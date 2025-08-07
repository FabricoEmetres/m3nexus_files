-- ========================================================
-- Rename Column updated_by_id to created_by_id in Component Table
-- M3 Nexus Database Migration
-- 
-- RATIONALE: 
-- With the component versioning system, the column updated_by_id
-- is misleading because components are never updated - they are
-- versioned (new rows created). The column should be named
-- created_by_id to accurately reflect that it tracks who created
-- each specific version of the component.
-- ========================================================

-- Begin transaction
BEGIN;

-- Log the migration start
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔄 RENAMING COLUMN: Component.updated_by_id → created_by_id';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '⚠️  This migration renames updated_by_id to created_by_id';
    RAISE NOTICE '✅ Data will be preserved - only column name changes';
END $$;

-- Step 1: Check current table structure before migration
DO $$
DECLARE
    updated_by_exists boolean;
    created_by_exists boolean;
    table_row_count integer;
BEGIN
    RAISE NOTICE '🔍 ANALYZING CURRENT TABLE STRUCTURE';
    RAISE NOTICE '===================================';
    
    -- Check if updated_by_id column exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'updated_by_id'
    ) INTO updated_by_exists;
    
    -- Check if created_by_id column already exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'created_by_id'
    ) INTO created_by_exists;
    
    -- Get current row count
    SELECT COUNT(*) FROM "Component" INTO table_row_count;
    
    IF updated_by_exists AND NOT created_by_exists THEN
        RAISE NOTICE '✅ Found updated_by_id column - ready for rename';
        RAISE NOTICE '📊 Component table has % rows', table_row_count;
    ELSIF NOT updated_by_exists AND created_by_exists THEN
        RAISE NOTICE '⚠️  Column already renamed - created_by_id exists, updated_by_id does not';
        RAISE NOTICE '🚫 Migration not needed';
        RAISE EXCEPTION 'Column already renamed - migration not needed';
    ELSIF updated_by_exists AND created_by_exists THEN
        RAISE NOTICE '⚠️  Both columns exist - potential naming conflict';
        RAISE EXCEPTION 'Both updated_by_id and created_by_id exist - manual intervention required';
    ELSE
        RAISE NOTICE '❌ Neither column exists - unexpected state';
        RAISE EXCEPTION 'Neither updated_by_id nor created_by_id found in Component table';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- Step 2: Check for dependencies on updated_by_id column
DO $$
DECLARE
    dep_record RECORD;
    dep_count integer := 0;
BEGIN
    RAISE NOTICE '🔍 CHECKING FOR DEPENDENCIES ON updated_by_id';
    RAISE NOTICE '============================================';
    
    -- Check for views that reference the column
    FOR dep_record IN
        SELECT DISTINCT
            schemaname,
            viewname,
            definition
        FROM pg_views
        WHERE (definition ILIKE '%component%.updated_by_id%' 
           OR definition ILIKE '%"Component".updated_by_id%'
           OR definition ILIKE '%Component.updated_by_id%')
        AND schemaname = 'public'
    LOOP
        RAISE NOTICE '🔗 FOUND VIEW DEPENDENCY: %.%', dep_record.schemaname, dep_record.viewname;
        dep_count := dep_count + 1;
    END LOOP;
    
    -- Check for indexes on the column
    FOR dep_record IN
        SELECT
            indexname,
            indexdef
        FROM pg_indexes
        WHERE tablename = 'Component'
        AND schemaname = 'public'
        AND indexdef ILIKE '%updated_by_id%'
    LOOP
        RAISE NOTICE '📇 FOUND INDEX DEPENDENCY: %', dep_record.indexname;
        dep_count := dep_count + 1;
    END LOOP;
    
    -- Check for foreign key constraints
    FOR dep_record IN
        SELECT
            conname,
            pg_get_constraintdef(oid) as condef
        FROM pg_constraint
        WHERE conrelid = 'public."Component"'::regclass
        AND pg_get_constraintdef(oid) ILIKE '%updated_by_id%'
    LOOP
        RAISE NOTICE '🔒 FOUND CONSTRAINT DEPENDENCY: %', dep_record.conname;
        dep_count := dep_count + 1;
    END LOOP;
    
    IF dep_count = 0 THEN
        RAISE NOTICE '✅ No obvious dependencies found - column should be safe to rename';
    ELSE
        RAISE NOTICE '⚠️  Found % potential dependencies', dep_count;
        RAISE NOTICE '    These will need to be updated after column rename';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- Step 3: Perform the column rename
DO $$
DECLARE
    table_row_count integer;
BEGIN
    RAISE NOTICE '🎯 RENAMING COLUMN';
    RAISE NOTICE '=================';
    
    -- Rename the column
    RAISE NOTICE '🔄 Executing: ALTER TABLE "Component" RENAME COLUMN updated_by_id TO created_by_id;';
    ALTER TABLE "Component" RENAME COLUMN updated_by_id TO created_by_id;
    
    -- Get final row count
    SELECT COUNT(*) FROM "Component" INTO table_row_count;
    
    RAISE NOTICE '✅ SUCCESS: Column renamed successfully!';
    RAISE NOTICE '📊 Component table still has % rows (data preserved)', table_row_count;
    RAISE NOTICE '';
END $$;

-- Step 4: Verify the rename was successful
DO $$
DECLARE
    updated_by_exists boolean;
    created_by_exists boolean;
    col_record RECORD;
    column_count integer := 0;
BEGIN
    RAISE NOTICE '🔍 FINAL VERIFICATION';
    RAISE NOTICE '===================';
    
    -- Check if old column still exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'updated_by_id'
    ) INTO updated_by_exists;
    
    -- Check if new column exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'created_by_id'
    ) INTO created_by_exists;
    
    IF NOT updated_by_exists AND created_by_exists THEN
        RAISE NOTICE '✅ SUCCESS: Column successfully renamed!';
        RAISE NOTICE '   - updated_by_id: ❌ (removed)';
        RAISE NOTICE '   - created_by_id: ✅ (exists)';
    ELSE
        RAISE EXCEPTION '❌ CRITICAL ERROR: Column rename verification failed';
    END IF;
    
    -- Show current table structure
    RAISE NOTICE '';
    RAISE NOTICE '📋 Updated Component table structure:';
    FOR col_record IN 
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component'
        ORDER BY ordinal_position
    LOOP
        column_count := column_count + 1;
        RAISE NOTICE '   %: % % %', 
            column_count,
            col_record.column_name, 
            col_record.data_type,
            CASE WHEN col_record.is_nullable = 'YES' THEN '(nullable)' ELSE '(not null)' END;
    END LOOP;
    
END $$;

-- Step 5: Summary and next steps
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 MIGRATION COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '====================================';
    RAISE NOTICE '';
    RAISE NOTICE '📝 SUMMARY:';
    RAISE NOTICE '  ✅ Renamed Component.updated_by_id → created_by_id';  
    RAISE NOTICE '  ✅ All data preserved during rename';
    RAISE NOTICE '  ✅ Column semantics now match versioning system';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NEXT STEPS:';
    RAISE NOTICE '  1. Deploy updated application code that uses created_by_id';
    RAISE NOTICE '  2. Test component creation and versioning';
    RAISE NOTICE '  3. Update any views/procedures that referenced updated_by_id';
    RAISE NOTICE '  4. Verify UI shows correct creator information';
    RAISE NOTICE '';
    RAISE NOTICE '📋 SEMANTIC MEANING:';
    RAISE NOTICE '  - created_by_id: Who created this specific component version';
    RAISE NOTICE '  - created_at: When this component version was created';
    RAISE NOTICE '  - version: Version number (1, 2, 3...)';
    RAISE NOTICE '  - component_base_id: Links all versions of same component';
    RAISE NOTICE '';
    
END $$;

-- Commit transaction
COMMIT;

RAISE NOTICE '🚀 Transaction committed - Column rename complete!'; 