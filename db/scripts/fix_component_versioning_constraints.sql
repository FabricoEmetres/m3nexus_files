-- =====================================================
-- M3 Nexus - Fix Component Versioning Constraints
-- =====================================================
-- This script fixes issues that may arise during the transition
-- to component versioning, particularly foreign key constraint
-- violations when trying to delete components that are referenced
-- by newer versions.
-- =====================================================

-- Start transaction
BEGIN;

-- =====================================================
-- STEP 1: Identify orphaned components and constraint issues
-- =====================================================

DO $$
DECLARE
  orphaned_count INTEGER;
  constraint_violations INTEGER;
BEGIN
  -- Check for components that might be causing constraint violations
  SELECT COUNT(*) INTO constraint_violations
  FROM "Component" c1
  WHERE EXISTS (
    SELECT 1 FROM "Component" c2 
    WHERE c2.component_base_id = c1.id 
    AND c2.id != c1.id
  );
  
  RAISE NOTICE 'Found % components that are referenced as base components by other versions', constraint_violations;
  
  -- Check for components not referenced by any Order_Component
  SELECT COUNT(*) INTO orphaned_count
  FROM "Component" c
  WHERE NOT EXISTS (
    SELECT 1 FROM "Order_Component" oc WHERE oc.component_id = c.id
  );
  
  RAISE NOTICE 'Found % components not referenced by any Order_Component', orphaned_count;
END $$;

-- =====================================================
-- STEP 2: Show current component versioning status
-- =====================================================

DO $$
DECLARE
  total_components INTEGER;
  unique_bases INTEGER;
  max_versions INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_components FROM "Component";
  SELECT COUNT(DISTINCT component_base_id) INTO unique_bases FROM "Component" WHERE component_base_id IS NOT NULL;
  SELECT MAX(version) INTO max_versions FROM "Component" WHERE version IS NOT NULL;
  
  RAISE NOTICE 'Current Component Status:';
  RAISE NOTICE '- Total components: %', total_components;
  RAISE NOTICE '- Unique component bases: %', unique_bases;
  RAISE NOTICE '- Highest version number: %', max_versions;
END $$;

-- =====================================================
-- STEP 3: Fix component_base_id for existing components
-- =====================================================

-- For components that don't have component_base_id set, set it to their own ID
-- This handles components created before versioning was implemented
UPDATE "Component" 
SET component_base_id = id 
WHERE component_base_id IS NULL;

-- Ensure version is set for all components
UPDATE "Component" 
SET version = 1 
WHERE version IS NULL OR version < 1;

-- =====================================================
-- STEP 4: Clean up Order_Component references safely
-- =====================================================

-- This query identifies Order_Component records that reference components
-- which are not the latest version of their component_base_id
-- We'll update these to point to the latest version

WITH LatestComponentVersions AS (
  SELECT 
    component_base_id,
    id as latest_component_id,
    version,
    ROW_NUMBER() OVER (
      PARTITION BY component_base_id 
      ORDER BY version DESC, created_at DESC
    ) as rn
  FROM "Component"
  WHERE component_base_id IS NOT NULL
),
OnlyLatest AS (
  SELECT component_base_id, latest_component_id
  FROM LatestComponentVersions 
  WHERE rn = 1
),
OutdatedReferences AS (
  SELECT 
    oc.order_id,
    oc.component_id as old_component_id,
    ol.latest_component_id as new_component_id,
    c.component_base_id
  FROM "Order_Component" oc
  JOIN "Component" c ON oc.component_id = c.id
  JOIN OnlyLatest ol ON c.component_base_id = ol.component_base_id
  WHERE oc.component_id != ol.latest_component_id
)
UPDATE "Order_Component" 
SET component_id = OutdatedReferences.new_component_id
FROM OutdatedReferences
WHERE "Order_Component".order_id = OutdatedReferences.order_id 
  AND "Order_Component".component_id = OutdatedReferences.old_component_id;

-- Log the updates
DO $$
DECLARE
  updated_count INTEGER;
BEGIN
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RAISE NOTICE 'Updated % Order_Component references to point to latest component versions', updated_count;
END $$;

-- =====================================================
-- STEP 5: Identify truly orphaned components
-- =====================================================

-- Create a temporary table to track components that can be safely removed
CREATE TEMP TABLE components_safe_to_remove AS
SELECT c.id, c.title, c.component_base_id, c.version
FROM "Component" c
WHERE NOT EXISTS (
  -- Not referenced by any Order_Component
  SELECT 1 FROM "Order_Component" oc WHERE oc.component_id = c.id
) AND NOT EXISTS (
  -- Not used as a base component by any other component
  SELECT 1 FROM "Component" c2 WHERE c2.component_base_id = c.id AND c2.id != c.id
) AND NOT EXISTS (
  -- Not referenced by any ComponentBudget
  SELECT 1 FROM "ComponentBudget" cb WHERE cb.component_id = c.id
);

-- Show what would be removed
DO $$
DECLARE
  removable_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO removable_count FROM components_safe_to_remove;
  RAISE NOTICE 'Found % components that can be safely removed', removable_count;
  
  IF removable_count > 0 THEN
    RAISE NOTICE 'Components safe to remove:';
    FOR rec IN SELECT id, title, version FROM components_safe_to_remove LOOP
      RAISE NOTICE '- ID: %, Title: "%" (version %)', rec.id, rec.title, rec.version;
    END LOOP;
  END IF;
END $$;

-- =====================================================
-- STEP 6: Optional cleanup (commented out for safety)
-- =====================================================

-- Uncomment the following section if you want to actually remove orphaned components
-- WARNING: This will permanently delete components that are not referenced anywhere

/*
-- Delete related records first
DELETE FROM "Component_Finishing" 
WHERE component_id IN (SELECT id FROM components_safe_to_remove);

DELETE FROM "ComponentFile" 
WHERE component_id IN (SELECT id FROM components_safe_to_remove);

-- Delete the components themselves
DELETE FROM "Component" 
WHERE id IN (SELECT id FROM components_safe_to_remove);

DO $$
DECLARE
  deleted_count INTEGER;
BEGIN
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'Deleted % orphaned components', deleted_count;
END $$;
*/

-- =====================================================
-- STEP 7: Verify constraint integrity
-- =====================================================

DO $$
DECLARE
  constraint_issues INTEGER;
BEGIN
  -- Check for any remaining constraint violations
  SELECT COUNT(*) INTO constraint_issues
  FROM "Component" c1
  WHERE EXISTS (
    SELECT 1 FROM "Component" c2 
    WHERE c2.component_base_id = c1.id 
    AND c2.id != c1.id
  ) AND NOT EXISTS (
    SELECT 1 FROM "Order_Component" oc WHERE oc.component_id = c1.id
  ) AND NOT EXISTS (
    SELECT 1 FROM "ComponentBudget" cb WHERE cb.component_id = c1.id
  );
  
  IF constraint_issues > 0 THEN
    RAISE WARNING 'Still have % potential constraint issues that need manual review', constraint_issues;
  ELSE
    RAISE NOTICE 'No constraint violations detected - system is ready for component versioning';
  END IF;
END $$;

-- =====================================================
-- STEP 8: Final status report
-- =====================================================

DO $$
DECLARE
  total_components INTEGER;
  unique_bases INTEGER;
  order_references INTEGER;
  budget_references INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_components FROM "Component";
  SELECT COUNT(DISTINCT component_base_id) INTO unique_bases FROM "Component";
  SELECT COUNT(*) INTO order_references FROM "Order_Component";
  SELECT COUNT(*) INTO budget_references FROM "ComponentBudget";
  
  RAISE NOTICE '=====================================================';
  RAISE NOTICE 'COMPONENT VERSIONING FIX COMPLETED';
  RAISE NOTICE '=====================================================';
  RAISE NOTICE 'Final Status:';
  RAISE NOTICE '- Total components: %', total_components;
  RAISE NOTICE '- Unique component bases: %', unique_bases;
  RAISE NOTICE '- Order_Component references: %', order_references;
  RAISE NOTICE '- ComponentBudget references: %', budget_references;
  RAISE NOTICE '=====================================================';
  RAISE NOTICE 'The system is now ready for component versioning.';
  RAISE NOTICE 'Components will be versioned instead of deleted.';
  RAISE NOTICE '=====================================================';
END $$;

-- Commit the transaction
COMMIT;
