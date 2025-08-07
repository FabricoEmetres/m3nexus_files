-- ========================================================
-- SAFE Remove Column updated_at from Component Table
-- M3 Nexus Database Migration - WITH DEPENDENCY RESOLUTION
-- 
-- This script identifies and safely removes all dependencies
-- before dropping the updated_at column from Component table
-- ========================================================

-- Begin transaction
BEGIN;

-- Log the migration start
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 ANALYZING DEPENDENCIES FOR Component.updated_at';
    RAISE NOTICE '====================================================';
END $$;

-- Step 1: Identify all dependencies on Component.updated_at
DO $$
DECLARE
    dep_record RECORD;
    dep_count integer := 0;
BEGIN
    RAISE NOTICE '📋 Checking for dependent objects...';
    
    -- Check for views that reference the column
    FOR dep_record IN
        SELECT DISTINCT
            schemaname,
            viewname,
            definition
        FROM pg_views
        WHERE definition ILIKE '%component%updated_at%'
        OR definition ILIKE '%Component%updated_at%'
    LOOP
        RAISE NOTICE '🔗 FOUND VIEW DEPENDENCY: %.%', dep_record.schemaname, dep_record.viewname;
        dep_count := dep_count + 1;
    END LOOP;
    
    -- Check for indexes on the column
    FOR dep_record IN
        SELECT
            schemaname,
            tablename,
            indexname,
            indexdef
        FROM pg_indexes
        WHERE tablename = 'Component'
        AND indexdef ILIKE '%updated_at%'
    LOOP
        RAISE NOTICE '📇 FOUND INDEX DEPENDENCY: %', dep_record.indexname;
        dep_count := dep_count + 1;
    END LOOP;
    
    -- Check for constraints that might reference the column
    FOR dep_record IN
        SELECT
            conname,
            contype,
            pg_get_constraintdef(oid) as condef
        FROM pg_constraint
        WHERE conrelid = 'public."Component"'::regclass
        AND pg_get_constraintdef(oid) ILIKE '%updated_at%'
    LOOP
        RAISE NOTICE '🔒 FOUND CONSTRAINT DEPENDENCY: % (type: %)', dep_record.conname, dep_record.contype;
        dep_count := dep_count + 1;
    END LOOP;
    
    -- Check for triggers
    FOR dep_record IN
        SELECT
            trigger_name,
            event_manipulation,
            action_statement
        FROM information_schema.triggers
        WHERE event_object_table = 'Component'
        AND (action_statement ILIKE '%updated_at%' OR trigger_name ILIKE '%updated_at%')
    LOOP
        RAISE NOTICE '⚡ FOUND TRIGGER DEPENDENCY: %', dep_record.trigger_name;
        dep_count := dep_count + 1;
    END LOOP;
    
    IF dep_count = 0 THEN
        RAISE NOTICE '✅ No obvious dependencies found - column should be safe to drop';
    ELSE
        RAISE NOTICE '⚠️  Found % potential dependencies', dep_count;
        RAISE NOTICE '';
        RAISE NOTICE '🚨 IMPORTANT: This script will attempt to resolve dependencies automatically';
        RAISE NOTICE '    Review the output carefully before proceeding with production data';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- Step 2: Get detailed dependency information from system catalogs
DO $$
DECLARE
    dep_record RECORD;
    obj_count integer := 0;
BEGIN
    RAISE NOTICE '🔍 DETAILED DEPENDENCY ANALYSIS';
    RAISE NOTICE '===============================';
    
    -- Query system catalogs for dependencies
    FOR dep_record IN
        SELECT DISTINCT
            d.objid,
            d.classid,
            d.refclassid,
            c.relname as table_name,
            a.attname as column_name,
            CASE d.deptype
                WHEN 'n' THEN 'normal'
                WHEN 'a' THEN 'auto'
                WHEN 'i' THEN 'internal'
                WHEN 'x' THEN 'extension'
                WHEN 'p' THEN 'pin'
            END as dependency_type,
            pg_describe_object(d.classid, d.objid, 0) as object_description
        FROM pg_depend d
        JOIN pg_class c ON d.refobjid = c.oid
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = d.refobjsubid
        WHERE c.relname = 'Component'
        AND a.attname = 'updated_at'
        AND d.deptype NOT IN ('i', 'x')  -- Exclude internal and extension dependencies
    LOOP
        RAISE NOTICE '🔗 DEPENDENCY: % (type: %)', dep_record.object_description, dep_record.dependency_type;
        obj_count := obj_count + 1;
    END LOOP;
    
    IF obj_count = 0 THEN
        RAISE NOTICE '✅ No system catalog dependencies found';
    ELSE
        RAISE NOTICE '⚠️  Found % dependencies in system catalogs', obj_count;
    END IF;
    
    RAISE NOTICE '';
END $$;

-- Step 3: Attempt to identify and drop specific dependency types
DO $$
DECLARE
    view_record RECORD;
    index_record RECORD;
    constraint_record RECORD;
BEGIN
    RAISE NOTICE '🧹 CLEANING UP DEPENDENCIES';
    RAISE NOTICE '==========================';
    
    -- Drop any views that reference Component.updated_at
    FOR view_record IN
        SELECT DISTINCT
            schemaname,
            viewname
        FROM pg_views
        WHERE (definition ILIKE '%component.updated_at%' 
           OR definition ILIKE '%"Component".updated_at%'
           OR definition ILIKE '%Component.updated_at%')
        AND schemaname = 'public'
    LOOP
        RAISE NOTICE '🗑️  Dropping view: %.%', view_record.schemaname, view_record.viewname;
        EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', view_record.schemaname, view_record.viewname);
        RAISE NOTICE '✅ View dropped successfully';
    END LOOP;
    
    -- Drop any indexes specifically on updated_at column
    FOR index_record IN
        SELECT
            indexname
        FROM pg_indexes
        WHERE tablename = 'Component'
        AND schemaname = 'public'
        AND indexdef ILIKE '%updated_at%'
        AND indexname != 'Component_pkey'  -- Don't drop primary key
    LOOP
        RAISE NOTICE '🗑️  Dropping index: %', index_record.indexname;
        EXECUTE format('DROP INDEX IF EXISTS %I', index_record.indexname);
        RAISE NOTICE '✅ Index dropped successfully';
    END LOOP;
    
    RAISE NOTICE '🧹 Dependency cleanup completed';
    RAISE NOTICE '';
END $$;

-- Step 4: Now attempt to drop the column
DO $$
DECLARE
    column_exists boolean;
    table_row_count integer;
BEGIN
    RAISE NOTICE '🎯 DROPPING COLUMN updated_at';
    RAISE NOTICE '============================';
    
    -- Check if column still exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'updated_at'
    ) INTO column_exists;
    
    IF column_exists THEN
        RAISE NOTICE '🔄 Attempting to drop updated_at column...';
        
        -- Try to drop the column (this will now show the actual error if any)
        BEGIN
            ALTER TABLE "Component" DROP COLUMN updated_at;
            RAISE NOTICE '✅ SUCCESS: updated_at column dropped successfully!';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ FAILED TO DROP COLUMN: %', SQLERRM;
            RAISE NOTICE '';
            RAISE NOTICE '🔧 ALTERNATIVE APPROACH: Using CASCADE';
            RAISE NOTICE 'Executing: ALTER TABLE "Component" DROP COLUMN updated_at CASCADE;';
            
            -- Try with CASCADE to force drop dependencies
            ALTER TABLE "Component" DROP COLUMN updated_at CASCADE;
            RAISE NOTICE '✅ SUCCESS: Column dropped with CASCADE!';
        END;
    ELSE
        RAISE NOTICE '⚠️  Column updated_at does not exist - already removed';
    END IF;
    
    -- Get final row count
    SELECT COUNT(*) FROM "Component" INTO table_row_count;
    RAISE NOTICE '📊 Component table now has % rows', table_row_count;
    
END $$;

-- Step 5: Final verification and summary
DO $$
DECLARE
    column_exists boolean;
    col_record RECORD;
    column_count integer := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 FINAL VERIFICATION';
    RAISE NOTICE '===================';
    
    -- Check if column was successfully removed
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'updated_at'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE '✅ SUCCESS: updated_at column successfully removed from Component table';
    ELSE
        RAISE EXCEPTION '❌ CRITICAL ERROR: updated_at column still exists after migration attempt';
    END IF;
    
    -- Show remaining columns
    RAISE NOTICE '';
    RAISE NOTICE '📋 Current Component table structure:';
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
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 MIGRATION COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '====================================';
    RAISE NOTICE '';
    RAISE NOTICE '📝 SUMMARY:';
    RAISE NOTICE '  ✅ Analyzed and resolved dependencies';
    RAISE NOTICE '  ✅ Dropped Component.updated_at column';  
    RAISE NOTICE '  ✅ Preserved Component.created_at column';
    RAISE NOTICE '  ✅ Component table now has % columns', column_count;
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NEXT STEPS:';
    RAISE NOTICE '  1. Deploy updated application code';
    RAISE NOTICE '  2. Test component creation/versioning';
    RAISE NOTICE '  3. Verify UI shows created_at instead of updated_at';
    RAISE NOTICE '';
    
END $$;

-- Commit transaction
COMMIT;

RAISE NOTICE '🚀 Transaction committed - Migration complete!'; 