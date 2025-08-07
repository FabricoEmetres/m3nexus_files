-- =================================================================
-- Fix Triggers Before Status Migration - VERSION 2
-- =================================================================
-- Author: Thúlio Silva
-- Date: Fix Script for Triggers causing "updated_at" errors
-- 
-- Description: This script removes the problematic set_timestamp_component 
-- trigger that tries to update non-existent updated_at column.
-- =================================================================

-- Start transaction to ensure all operations complete successfully or rollback
BEGIN;

-- =================================================================
-- STEP 1: Identify the problematic trigger
-- =================================================================
DO $$
DECLARE
    trigger_exists BOOLEAN;
    function_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🔍 IDENTIFYING THE PROBLEMATIC TRIGGER';
    RAISE NOTICE '====================================';
    
    -- Check if set_timestamp_component trigger exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers
        WHERE trigger_name = 'set_timestamp_component'
        AND event_object_table = 'Component'
        AND event_object_schema = 'public'
    ) INTO trigger_exists;
    
    -- Check if trigger_set_timestamp function exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'trigger_set_timestamp'
    ) INTO function_exists;
    
    RAISE NOTICE 'Current status:';
    RAISE NOTICE '  - set_timestamp_component trigger: %', CASE WHEN trigger_exists THEN '🔧 EXISTS (PROBLEMATIC)' ELSE '✅ NOT FOUND' END;
    RAISE NOTICE '  - trigger_set_timestamp function: %', CASE WHEN function_exists THEN '🔧 EXISTS' ELSE '❌ NOT FOUND' END;
    RAISE NOTICE '';
    
    IF trigger_exists THEN
        RAISE NOTICE '🎯 FOUND THE CULPRIT: set_timestamp_component trigger is trying to update non-existent updated_at column!';
        RAISE NOTICE '';
    END IF;
END $$;

-- =================================================================
-- STEP 2: Remove the problematic trigger
-- =================================================================
DO $$
BEGIN
    RAISE NOTICE '🗑️  REMOVING PROBLEMATIC TRIGGER';
    RAISE NOTICE '==============================';
    
    -- Drop the set_timestamp_component trigger
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers
        WHERE trigger_name = 'set_timestamp_component'
        AND event_object_table = 'Component'
        AND event_object_schema = 'public'
    ) THEN
        RAISE NOTICE '🗑️  Dropping trigger: set_timestamp_component';
        DROP TRIGGER IF EXISTS set_timestamp_component ON "Component";
        RAISE NOTICE '✅ Trigger set_timestamp_component dropped successfully!';
        RAISE NOTICE '🎯 This was the trigger causing the "updated_at" error!';
    ELSE
        RAISE NOTICE '⏭️  Trigger set_timestamp_component not found - already removed';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- =================================================================
-- STEP 3: Check if trigger_set_timestamp function should be kept
-- =================================================================
DO $$
DECLARE
    function_usage_count INTEGER;
    usage_record RECORD;
BEGIN
    RAISE NOTICE '🔍 CHECKING trigger_set_timestamp FUNCTION USAGE';
    RAISE NOTICE '===============================================';
    
    -- Count how many other triggers use this function
    SELECT COUNT(*) INTO function_usage_count
    FROM information_schema.triggers
    WHERE action_statement LIKE '%trigger_set_timestamp%'
    AND event_object_schema = 'public';
    
    RAISE NOTICE 'trigger_set_timestamp function usage count: %', function_usage_count;
    
    IF function_usage_count > 0 THEN
        RAISE NOTICE '⚠️  Function trigger_set_timestamp is still used by other triggers:';
        
        FOR usage_record IN
            SELECT 
                event_object_table,
                trigger_name
            FROM information_schema.triggers
            WHERE action_statement LIKE '%trigger_set_timestamp%'
            AND event_object_schema = 'public'
        LOOP
            RAISE NOTICE '  - % on table %', usage_record.trigger_name, usage_record.event_object_table;
        END LOOP;
        
        RAISE NOTICE '✅ Keeping trigger_set_timestamp function (used by other tables)';
    ELSE
        RAISE NOTICE '🗑️  Function trigger_set_timestamp is not used by any triggers';
        
        IF EXISTS (
            SELECT 1 FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
            AND p.proname = 'trigger_set_timestamp'
        ) THEN
            RAISE NOTICE '🗑️  Dropping unused function: trigger_set_timestamp';
            DROP FUNCTION IF EXISTS trigger_set_timestamp() CASCADE;
            RAISE NOTICE '✅ Function trigger_set_timestamp dropped successfully';
        END IF;
    END IF;
    
    RAISE NOTICE '';
END $$;

-- =================================================================
-- STEP 4: Final verification
-- =================================================================
DO $$
DECLARE
    trigger_count INTEGER;
    component_trigger_record RECORD;
BEGIN
    RAISE NOTICE '✅ FINAL VERIFICATION';
    RAISE NOTICE '===================';
    
    -- Count remaining triggers on Component table
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers
    WHERE event_object_table = 'Component'
    AND event_object_schema = 'public';
    
    RAISE NOTICE 'Remaining triggers on Component table: %', trigger_count;
    
    IF trigger_count > 0 THEN
        RAISE NOTICE 'Remaining triggers:';
        FOR component_trigger_record IN
            SELECT trigger_name, event_manipulation, action_timing
            FROM information_schema.triggers
            WHERE event_object_table = 'Component'
            AND event_object_schema = 'public'
        LOOP
            RAISE NOTICE '  - %: % %', 
                component_trigger_record.trigger_name,
                component_trigger_record.action_timing,
                component_trigger_record.event_manipulation;
        END LOOP;
    END IF;
    
    -- Check if the problematic trigger is gone
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers
        WHERE trigger_name = 'set_timestamp_component'
        AND event_object_table = 'Component'
        AND event_object_schema = 'public'
    ) THEN
        RAISE NOTICE '';
        RAISE NOTICE '✅ SUCCESS: Problematic set_timestamp_component trigger removed!';
        RAISE NOTICE '🎯 The "updated_at" error should now be fixed!';
        RAISE NOTICE '🚀 Component table is ready for status migration!';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '❌ ERROR: set_timestamp_component trigger still exists!';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 TRIGGER CLEANUP COMPLETED!';
    RAISE NOTICE '============================';
    RAISE NOTICE '';
    RAISE NOTICE '📝 WHAT WAS FIXED:';
    RAISE NOTICE '  ✅ Removed set_timestamp_component trigger from Component table';
    RAISE NOTICE '  ✅ This trigger was trying to update non-existent updated_at column';
    RAISE NOTICE '  ✅ Component table now ready for status migration';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 NEXT STEP:';
    RAISE NOTICE '  Now run: status_refactoring_migration_fixed.sql';
    RAISE NOTICE '';
END $$;

-- =================================================================
-- Commit the transaction
-- =================================================================
COMMIT; 