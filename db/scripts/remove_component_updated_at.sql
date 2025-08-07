-- ========================================================
-- Remove Column updated_at from Component Table
-- M3 Nexus Database Migration
-- 
-- RATIONALE: 
-- With the component versioning system implemented, components
-- are never updated (UPDATE) but always versioned (INSERT new).
-- Therefore, the updated_at column is meaningless and should 
-- be removed to maintain data integrity and clarity.
-- 
-- The created_at column remains to track when each version
-- was created.
-- ========================================================

-- Begin transaction
BEGIN;

-- Log the migration start
DO $$
BEGIN
    RAISE NOTICE '🚀 Starting migration: Remove updated_at column from Component table';
    RAISE NOTICE '⚠️  This migration will permanently remove the updated_at column';
    RAISE NOTICE '✅ The created_at column will remain to track when each component version was created';
END $$;

-- Check current table structure before migration
DO $$
DECLARE
    column_exists boolean;
BEGIN
    -- Check if updated_at column exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'updated_at'
    ) INTO column_exists;
    
    IF column_exists THEN
        RAISE NOTICE '✅ Column updated_at exists in Component table - proceeding with removal';
    ELSE
        RAISE NOTICE '⚠️  Column updated_at does not exist in Component table - migration not needed';
    END IF;
END $$;

-- Remove the updated_at column from Component table
ALTER TABLE "Component" DROP COLUMN IF EXISTS updated_at;

-- Verify the column was removed
DO $$
DECLARE
    column_exists boolean;
    table_row_count integer;
BEGIN
    -- Check if column was successfully removed
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'updated_at'
    ) INTO column_exists;
    
    -- Get current row count
    SELECT COUNT(*) FROM "Component" INTO table_row_count;
    
    IF NOT column_exists THEN
        RAISE NOTICE '✅ SUCCESS: updated_at column successfully removed from Component table';
        RAISE NOTICE '📊 Component table now has % rows', table_row_count;
    ELSE
        RAISE EXCEPTION '❌ FAILED: updated_at column still exists in Component table';
    END IF;
END $$;

-- Log remaining columns for verification
DO $$
DECLARE
    col_record RECORD;
    column_list TEXT := '';
BEGIN
    RAISE NOTICE '📋 Remaining columns in Component table:';
    
    FOR col_record IN 
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component'
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '   - %: % (nullable: %)', 
            col_record.column_name, 
            col_record.data_type, 
            col_record.is_nullable;
    END LOOP;
    
    RAISE NOTICE '✅ Migration completed successfully!';
END $$;

-- Commit transaction
COMMIT;

-- Final summary
DO $$
BEGIN
    RAISE NOTICE '🎉 MIGRATION COMPLETE: Component.updated_at column removed';
    RAISE NOTICE '📝 Summary:';
    RAISE NOTICE '   - Removed: Component.updated_at column';
    RAISE NOTICE '   - Kept: Component.created_at column (tracks when each version was created)';
    RAISE NOTICE '   - Impact: Component versioning system now has cleaner data model';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Remember to deploy updated application code that no longer references updated_at';
END $$; 