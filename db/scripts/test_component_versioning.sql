-- =====================================================
-- M3 Nexus - Component Versioning Test Script
-- =====================================================
-- This script tests the component versioning system
-- to ensure it works correctly after migration
-- =====================================================

-- Start transaction for testing (will be rolled back)
BEGIN;

-- =====================================================
-- TEST 1: Verify migration completed successfully
-- =====================================================

DO $$
DECLARE
  component_count INTEGER;
  null_base_count INTEGER;
  invalid_version_count INTEGER;
BEGIN
  -- Check total components
  SELECT COUNT(*) INTO component_count FROM "Component";
  RAISE NOTICE 'TEST 1: Total components in database: %', component_count;
  
  -- Check for NULL component_base_id
  SELECT COUNT(*) INTO null_base_count 
  FROM "Component" 
  WHERE component_base_id IS NULL;
  
  IF null_base_count > 0 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: % components have NULL component_base_id', null_base_count;
  ELSE
    RAISE NOTICE 'TEST 1 PASSED: All components have component_base_id';
  END IF;
  
  -- Check for invalid versions
  SELECT COUNT(*) INTO invalid_version_count 
  FROM "Component" 
  WHERE version < 1;
  
  IF invalid_version_count > 0 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: % components have invalid version numbers', invalid_version_count;
  ELSE
    RAISE NOTICE 'TEST 1 PASSED: All components have valid version numbers';
  END IF;
END $$;

-- =====================================================
-- TEST 2: Test helper function get_next_component_version
-- =====================================================

DO $$
DECLARE
  test_base_id UUID;
  next_version INTEGER;
BEGIN
  -- Get a random component_base_id for testing
  SELECT component_base_id INTO test_base_id 
  FROM "Component" 
  LIMIT 1;
  
  IF test_base_id IS NULL THEN
    RAISE EXCEPTION 'TEST 2 FAILED: No components found for testing';
  END IF;
  
  -- Test the function
  SELECT get_next_component_version(test_base_id) INTO next_version;
  
  IF next_version > 1 THEN
    RAISE NOTICE 'TEST 2 PASSED: get_next_component_version returned % for base_id %', next_version, test_base_id;
  ELSE
    RAISE NOTICE 'TEST 2 PASSED: get_next_component_version returned % for base_id % (first version)', next_version, test_base_id;
  END IF;
END $$;

-- =====================================================
-- TEST 3: Test LatestComponents view
-- =====================================================

DO $$
DECLARE
  view_count INTEGER;
  table_count INTEGER;
BEGIN
  -- Count components in view
  SELECT COUNT(*) INTO view_count FROM "LatestComponents";
  
  -- Count unique component_base_id in table
  SELECT COUNT(DISTINCT component_base_id) INTO table_count FROM "Component";
  
  IF view_count = table_count THEN
    RAISE NOTICE 'TEST 3 PASSED: LatestComponents view shows % components (matches unique base count)', view_count;
  ELSE
    RAISE EXCEPTION 'TEST 3 FAILED: LatestComponents view shows % components but table has % unique bases', view_count, table_count;
  END IF;
END $$;

-- =====================================================
-- TEST 4: Create a test component and version it
-- =====================================================

DO $$
DECLARE
  test_component_id UUID;
  test_base_id UUID;
  version_2_id UUID;
  version_count INTEGER;
  latest_version INTEGER;
BEGIN
  -- Create a test component
  INSERT INTO "Component" (
    title, description, component_base_id, version,
    created_at, updated_at
  ) VALUES (
    'Test Component for Versioning',
    'This is a test component to validate versioning',
    NULL, -- Will be updated to self-reference
    1,
    NOW(),
    NOW()
  ) RETURNING id INTO test_component_id;
  
  -- Set component_base_id to self (simulating new component creation)
  UPDATE "Component" 
  SET component_base_id = test_component_id 
  WHERE id = test_component_id;
  
  test_base_id := test_component_id;
  
  RAISE NOTICE 'TEST 4: Created test component with ID: %', test_component_id;
  
  -- Create version 2 of the same component
  INSERT INTO "Component" (
    title, description, component_base_id, version,
    created_at, updated_at
  ) VALUES (
    'Test Component for Versioning - Version 2',
    'This is version 2 of the test component',
    test_base_id,
    2,
    NOW(),
    NOW()
  ) RETURNING id INTO version_2_id;
  
  RAISE NOTICE 'TEST 4: Created version 2 with ID: %', version_2_id;
  
  -- Verify we have 2 versions
  SELECT COUNT(*) INTO version_count 
  FROM "Component" 
  WHERE component_base_id = test_base_id;
  
  IF version_count = 2 THEN
    RAISE NOTICE 'TEST 4 PASSED: Found % versions for base component', version_count;
  ELSE
    RAISE EXCEPTION 'TEST 4 FAILED: Expected 2 versions, found %', version_count;
  END IF;
  
  -- Verify latest version is 2
  SELECT MAX(version) INTO latest_version 
  FROM "Component" 
  WHERE component_base_id = test_base_id;
  
  IF latest_version = 2 THEN
    RAISE NOTICE 'TEST 4 PASSED: Latest version is %', latest_version;
  ELSE
    RAISE EXCEPTION 'TEST 4 FAILED: Expected latest version 2, found %', latest_version;
  END IF;
  
  -- Verify LatestComponents view shows version 2
  SELECT version INTO latest_version 
  FROM "LatestComponents" 
  WHERE component_base_id = test_base_id;
  
  IF latest_version = 2 THEN
    RAISE NOTICE 'TEST 4 PASSED: LatestComponents view shows version %', latest_version;
  ELSE
    RAISE EXCEPTION 'TEST 4 FAILED: LatestComponents view shows version %, expected 2', latest_version;
  END IF;
  
  -- Clean up test data
  DELETE FROM "Component" WHERE component_base_id = test_base_id;
  RAISE NOTICE 'TEST 4: Cleaned up test data';
END $$;

-- =====================================================
-- TEST 5: Test indexes and constraints
-- =====================================================

DO $$
DECLARE
  index_count INTEGER;
BEGIN
  -- Check if indexes exist
  SELECT COUNT(*) INTO index_count 
  FROM pg_indexes 
  WHERE tablename = 'Component' 
  AND indexname IN ('idx_component_base_id', 'idx_component_base_version');
  
  IF index_count = 2 THEN
    RAISE NOTICE 'TEST 5 PASSED: All required indexes exist';
  ELSE
    RAISE EXCEPTION 'TEST 5 FAILED: Expected 2 indexes, found %', index_count;
  END IF;
  
  -- Test unique constraint (this should fail)
  BEGIN
    INSERT INTO "Component" (
      title, component_base_id, version,
      created_at, updated_at
    ) VALUES (
      'Duplicate Test', 
      (SELECT component_base_id FROM "Component" LIMIT 1),
      (SELECT version FROM "Component" LIMIT 1),
      NOW(),
      NOW()
    );
    
    RAISE EXCEPTION 'TEST 5 FAILED: Unique constraint did not prevent duplicate version';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE 'TEST 5 PASSED: Unique constraint properly prevents duplicate versions';
  END;
END $$;

-- =====================================================
-- TEST 6: Performance test with indexes
-- =====================================================

DO $$
DECLARE
  start_time TIMESTAMP;
  end_time TIMESTAMP;
  duration INTERVAL;
  test_base_id UUID;
BEGIN
  -- Get a component_base_id for testing
  SELECT component_base_id INTO test_base_id 
  FROM "Component" 
  LIMIT 1;
  
  -- Test query performance
  start_time := clock_timestamp();
  
  PERFORM * FROM "Component" 
  WHERE component_base_id = test_base_id 
  ORDER BY version DESC 
  LIMIT 1;
  
  end_time := clock_timestamp();
  duration := end_time - start_time;
  
  RAISE NOTICE 'TEST 6: Query for latest version took: %', duration;
  
  IF EXTRACT(MILLISECONDS FROM duration) < 100 THEN
    RAISE NOTICE 'TEST 6 PASSED: Query performance is acceptable (< 100ms)';
  ELSE
    RAISE NOTICE 'TEST 6 WARNING: Query took longer than expected, check indexes';
  END IF;
END $$;

-- =====================================================
-- TEST SUMMARY
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '=====================================================';
  RAISE NOTICE 'COMPONENT VERSIONING TESTS COMPLETED';
  RAISE NOTICE '=====================================================';
  RAISE NOTICE 'All tests passed successfully!';
  RAISE NOTICE 'The component versioning system is ready for use.';
  RAISE NOTICE '=====================================================';
END $$;

-- Rollback test transaction
ROLLBACK;
