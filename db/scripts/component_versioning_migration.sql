-- =====================================================
-- M3 Nexus - Component Versioning Migration Script
-- =====================================================
-- This script implements automatic versioning for the Component table
-- Instead of updating existing components, new versions are created
-- maintaining complete history and traceability
-- =====================================================

-- Start transaction to ensure atomicity
BEGIN;

-- =====================================================
-- STEP 1: Add component_base_id column
-- =====================================================
-- This column will identify components that are versions of the same base component
-- Initially nullable to allow data population, will be made NOT NULL later

ALTER TABLE "Component" 
ADD COLUMN component_base_id UUID;

COMMENT ON COLUMN "Component".component_base_id IS 'References the base component ID - all versions of the same component share this ID';

-- =====================================================
-- STEP 2: Convert version column from varchar to integer
-- =====================================================
-- Current version column is varchar(20) with default '1.0'
-- We need integer for proper versioning logic

-- First, create a backup of current version values
ALTER TABLE "Component"
ADD COLUMN version_backup VARCHAR(20);

UPDATE "Component"
SET version_backup = version;

-- Remove the default constraint first to avoid casting issues
ALTER TABLE "Component"
ALTER COLUMN version DROP DEFAULT;

-- Convert version to integer, handling various formats
-- If version is numeric, convert it; otherwise default to 1
ALTER TABLE "Component"
ALTER COLUMN version TYPE INTEGER USING
  CASE
    WHEN version ~ '^[0-9]+\.?[0-9]*$' THEN
      CASE
        WHEN version LIKE '%.%' THEN SPLIT_PART(version, '.', 1)::INTEGER
        ELSE version::INTEGER
      END
    ELSE 1
  END;

-- Set new default value for version (after type conversion)
ALTER TABLE "Component"
ALTER COLUMN version SET DEFAULT 1;

-- =====================================================
-- STEP 3: Populate component_base_id for existing data
-- =====================================================
-- For existing components, set component_base_id = id (they are their own base)
-- This makes them version 1 of themselves

UPDATE "Component" 
SET component_base_id = id 
WHERE component_base_id IS NULL;

-- =====================================================
-- STEP 4: Make component_base_id NOT NULL and add constraints
-- =====================================================

-- Make component_base_id required
ALTER TABLE "Component" 
ALTER COLUMN component_base_id SET NOT NULL;

-- Add foreign key constraint (component_base_id references Component.id)
-- This ensures component_base_id always points to a valid component
-- Using ON DELETE RESTRICT to prevent accidental deletion of base components
-- that have versions, but allowing manual cleanup when needed
ALTER TABLE "Component"
ADD CONSTRAINT fk_component_base_id
FOREIGN KEY (component_base_id) REFERENCES "Component"(id) ON DELETE RESTRICT;

-- =====================================================
-- STEP 5: Create indexes for performance
-- =====================================================

-- Index on component_base_id for fast lookups of all versions of a component
CREATE INDEX idx_component_base_id ON "Component"(component_base_id);

-- Composite index on component_base_id + version for finding latest version
CREATE INDEX idx_component_base_version ON "Component"(component_base_id, version DESC);

-- Unique constraint to prevent duplicate versions for the same base component
ALTER TABLE "Component" 
ADD CONSTRAINT uk_component_base_version 
UNIQUE (component_base_id, version);

-- =====================================================
-- STEP 6: Create helper view for latest components
-- =====================================================
-- This view makes it easy to get the latest version of each component
-- Useful for maintaining compatibility with existing queries

CREATE OR REPLACE VIEW "LatestComponents" AS
WITH RankedComponents AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (
      PARTITION BY component_base_id 
      ORDER BY version DESC, created_at DESC
    ) as rn
  FROM "Component"
)
SELECT
  id,
  component_base_id,
  parent_component_id,
  fabric_id,
  postfabric_id,
  material_id,
  machine_id,
  title,
  description,
  dimen_x,
  dimen_y,
  dimen_z,
  min_weight,
  max_weight,
  notes,
  version,
  estimated_print_time_minutes,
  estimated_material_usage,
  created_at,
  updated_at,
  updated_by_id,
  onedrive_folder_id,
  onedrive_clientfiles_folder_id,
  onedrive_budgets_folder_id,
  onedrive_forge_folder_id,
  version_backup
FROM RankedComponents 
WHERE rn = 1;

COMMENT ON VIEW "LatestComponents" IS 'View containing only the latest version of each component based on component_base_id';

-- =====================================================
-- STEP 7: Create function to get next version number
-- =====================================================

CREATE OR REPLACE FUNCTION get_next_component_version(base_component_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN COALESCE(
    (SELECT MAX(version) + 1 
     FROM "Component" 
     WHERE component_base_id = base_component_id), 
    1
  );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_next_component_version(UUID) IS 'Returns the next version number for a given component_base_id';

-- =====================================================
-- STEP 8: Validation queries
-- =====================================================

-- Verify all components have component_base_id
DO $$
DECLARE
  null_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO null_count 
  FROM "Component" 
  WHERE component_base_id IS NULL;
  
  IF null_count > 0 THEN
    RAISE EXCEPTION 'Migration failed: % components have NULL component_base_id', null_count;
  END IF;
  
  RAISE NOTICE 'Validation passed: All components have component_base_id';
END $$;

-- Verify version numbers are positive integers
DO $$
DECLARE
  invalid_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO invalid_count 
  FROM "Component" 
  WHERE version < 1;
  
  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'Migration failed: % components have invalid version numbers', invalid_count;
  END IF;
  
  RAISE NOTICE 'Validation passed: All components have valid version numbers';
END $$;

-- Show migration summary
DO $$
DECLARE
  total_components INTEGER;
  unique_bases INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_components FROM "Component";
  SELECT COUNT(DISTINCT component_base_id) INTO unique_bases FROM "Component";
  
  RAISE NOTICE 'Migration Summary:';
  RAISE NOTICE '- Total components: %', total_components;
  RAISE NOTICE '- Unique component bases: %', unique_bases;
  RAISE NOTICE '- Average versions per component: %', 
    ROUND(total_components::DECIMAL / unique_bases::DECIMAL, 2);
END $$;

-- Commit the transaction
COMMIT;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- The Component table now supports automatic versioning:
-- 1. component_base_id identifies the base component
-- 2. version is an integer starting from 1
-- 3. Indexes ensure good performance
-- 4. Helper function and view simplify usage
-- 5. All existing data has been preserved and migrated
-- =====================================================
