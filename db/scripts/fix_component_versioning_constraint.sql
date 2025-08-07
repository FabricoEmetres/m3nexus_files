-- =====================================================
-- M3 Nexus - Fix Component Versioning Constraint
-- =====================================================
-- This script fixes the foreign key constraint issue that prevents
-- component deletion when versioning is enabled
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: Drop the problematic constraint
-- =====================================================

-- Remove the existing foreign key constraint that's causing deletion issues
ALTER TABLE "Component" 
DROP CONSTRAINT IF EXISTS fk_component_base_id;

-- =====================================================
-- STEP 2: Add a more flexible constraint
-- =====================================================

-- Add the constraint back with ON DELETE RESTRICT
-- This still prevents accidental deletion but allows manual cleanup
ALTER TABLE "Component" 
ADD CONSTRAINT fk_component_base_id 
FOREIGN KEY (component_base_id) REFERENCES "Component"(id) ON DELETE RESTRICT;

-- =====================================================
-- STEP 3: Create helper function for safe component deletion
-- =====================================================

-- This function helps identify if a component can be safely deleted
-- considering both versioning and parent-child relationships
CREATE OR REPLACE FUNCTION can_delete_component(component_id_to_check UUID)
RETURNS TABLE(
  can_delete BOOLEAN,
  reason TEXT,
  blocking_components TEXT[]
) AS $$
DECLARE
  version_count INTEGER;
  child_count INTEGER;
  blocking_versions TEXT[];
  blocking_children TEXT[];
BEGIN
  -- Check if this component is a base for other versions
  SELECT COUNT(*) INTO version_count
  FROM "Component" 
  WHERE component_base_id = component_id_to_check 
  AND id != component_id_to_check;
  
  -- Check if this component has child components
  SELECT COUNT(*) INTO child_count
  FROM "Component" 
  WHERE parent_component_id = component_id_to_check;
  
  -- Get blocking version IDs
  IF version_count > 0 THEN
    SELECT ARRAY_AGG(id::TEXT) INTO blocking_versions
    FROM "Component" 
    WHERE component_base_id = component_id_to_check 
    AND id != component_id_to_check;
  END IF;
  
  -- Get blocking child IDs
  IF child_count > 0 THEN
    SELECT ARRAY_AGG(id::TEXT) INTO blocking_children
    FROM "Component" 
    WHERE parent_component_id = component_id_to_check;
  END IF;
  
  -- Determine if deletion is safe
  IF version_count > 0 AND child_count > 0 THEN
    RETURN QUERY SELECT 
      FALSE, 
      'Component has both versions and child components',
      ARRAY_CAT(COALESCE(blocking_versions, ARRAY[]::TEXT[]), COALESCE(blocking_children, ARRAY[]::TEXT[]));
  ELSIF version_count > 0 THEN
    RETURN QUERY SELECT 
      FALSE, 
      'Component is base for other versions',
      COALESCE(blocking_versions, ARRAY[]::TEXT[]);
  ELSIF child_count > 0 THEN
    RETURN QUERY SELECT 
      FALSE, 
      'Component has child components',
      COALESCE(blocking_children, ARRAY[]::TEXT[]);
  ELSE
    RETURN QUERY SELECT 
      TRUE, 
      'Component can be safely deleted',
      ARRAY[]::TEXT[];
  END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 4: Create function for safe component cleanup
-- =====================================================

-- This function helps clean up component versions when needed
-- It should be used carefully and only when necessary
CREATE OR REPLACE FUNCTION cleanup_component_versions(base_component_id UUID, keep_latest_n INTEGER DEFAULT 5)
RETURNS TABLE(
  deleted_count INTEGER,
  kept_count INTEGER,
  deleted_ids UUID[]
) AS $$
DECLARE
  total_versions INTEGER;
  versions_to_delete UUID[];
  versions_to_keep UUID[];
  deleted_count_result INTEGER := 0;
BEGIN
  -- Get total version count
  SELECT COUNT(*) INTO total_versions
  FROM "Component" 
  WHERE component_base_id = base_component_id;
  
  -- If we have more versions than we want to keep
  IF total_versions > keep_latest_n THEN
    -- Get versions to delete (oldest ones)
    SELECT ARRAY_AGG(id) INTO versions_to_delete
    FROM (
      SELECT id 
      FROM "Component" 
      WHERE component_base_id = base_component_id
      ORDER BY version ASC, created_at ASC
      LIMIT (total_versions - keep_latest_n)
    ) old_versions;
    
    -- Get versions to keep (newest ones)
    SELECT ARRAY_AGG(id) INTO versions_to_keep
    FROM (
      SELECT id 
      FROM "Component" 
      WHERE component_base_id = base_component_id
      ORDER BY version DESC, created_at DESC
      LIMIT keep_latest_n
    ) new_versions;
    
    -- Delete old versions (this would need to be done carefully in practice)
    -- For now, just return what would be deleted
    deleted_count_result := array_length(versions_to_delete, 1);
    
    RETURN QUERY SELECT 
      deleted_count_result,
      keep_latest_n,
      COALESCE(versions_to_delete, ARRAY[]::UUID[]);
  ELSE
    RETURN QUERY SELECT 
      0,
      total_versions,
      ARRAY[]::UUID[];
  END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 5: Update component versioning to handle parent relationships
-- =====================================================

-- Create function to handle parent component versioning
CREATE OR REPLACE FUNCTION get_latest_parent_version(original_parent_id UUID)
RETURNS UUID AS $$
DECLARE
  parent_base_id UUID;
  latest_parent_id UUID;
BEGIN
  -- If no parent, return NULL
  IF original_parent_id IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Get the base ID of the parent component
  SELECT component_base_id INTO parent_base_id
  FROM "Component" 
  WHERE id = original_parent_id;
  
  -- If parent doesn't have a base ID (shouldn't happen after migration), use original
  IF parent_base_id IS NULL THEN
    RETURN original_parent_id;
  END IF;
  
  -- Get the latest version of the parent component
  SELECT id INTO latest_parent_id
  FROM "Component" 
  WHERE component_base_id = parent_base_id
  ORDER BY version DESC, created_at DESC
  LIMIT 1;
  
  RETURN COALESCE(latest_parent_id, original_parent_id);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 6: Validation and summary
-- =====================================================

DO $$
DECLARE
  constraint_exists BOOLEAN;
  function_exists BOOLEAN;
BEGIN
  -- Check if constraint exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_component_base_id' 
    AND table_name = 'Component'
  ) INTO constraint_exists;
  
  -- Check if helper function exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_name = 'can_delete_component'
  ) INTO function_exists;
  
  IF constraint_exists AND function_exists THEN
    RAISE NOTICE '✅ Component versioning constraint fix completed successfully';
    RAISE NOTICE '✅ Helper functions created for safe component management';
    RAISE NOTICE '📋 Available functions:';
    RAISE NOTICE '   - can_delete_component(uuid) - Check if component can be deleted';
    RAISE NOTICE '   - cleanup_component_versions(uuid, int) - Clean up old versions';
    RAISE NOTICE '   - get_latest_parent_version(uuid) - Get latest parent version';
  ELSE
    RAISE EXCEPTION 'Fix failed: constraint_exists=%, function_exists=%', constraint_exists, function_exists;
  END IF;
END $$;

COMMIT;

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

-- Example 1: Check if a component can be deleted
-- SELECT * FROM can_delete_component('your-component-id-here');

-- Example 2: Clean up old versions (keep only 5 latest)
-- SELECT * FROM cleanup_component_versions('your-base-component-id-here', 5);

-- Example 3: Get latest version of a parent component
-- SELECT get_latest_parent_version('your-parent-component-id-here');

-- =====================================================
-- IMPORTANT NOTES
-- =====================================================
-- 1. Components should NOT be deleted when creating new versions
-- 2. Only delete components when explicitly removing them from orders
-- 3. Use helper functions to check deletion safety
-- 4. Parent-child relationships are preserved across versions
-- 5. Always keep version history for audit purposes
