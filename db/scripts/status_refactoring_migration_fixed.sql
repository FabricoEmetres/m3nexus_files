-- =================================================================
-- Status Refactoring Migration Script - FIXED VERSION
-- =================================================================
-- Author: Thúlio Silva
-- Date: Migration Script for Status Table Refactoring
-- 
-- Description: This script migrates the existing Status table into 
-- three separate tables: OrderStatus, BudgetStatus, and ComponentStatus.
-- It also updates all references in dependent tables.
-- 
-- FIXED VERSION: Compatible with Component table structure that has
-- created_by_id instead of updated_by_id, and no updated_at column.
-- =================================================================

-- Start transaction to ensure all operations complete successfully or rollback
BEGIN;

-- =================================================================
-- PRELIMINARY CHECK: Verify Status table exists
-- =================================================================
DO $$
DECLARE
    status_table_exists BOOLEAN;
    status_record_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔍 PRELIMINARY CHECKS';
    RAISE NOTICE '===================';
    
    -- Check if Status table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' 
        AND table_name = 'Status'
    ) INTO status_table_exists;
    
    IF status_table_exists THEN
        SELECT COUNT(*) FROM "Status" INTO status_record_count;
        RAISE NOTICE '✅ Status table found with % records', status_record_count;
    ELSE
        RAISE EXCEPTION '❌ Status table not found - migration cannot proceed';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- =================================================================
-- STEP 1: Create the new OrderStatus table
-- =================================================================
-- This table will contain status records where for_budget = false (Order statuses)
CREATE TABLE IF NOT EXISTS "OrderStatus" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_status_id UUID REFERENCES "OrderStatus"(id) ON DELETE SET NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes and constraints for performance and data integrity
CREATE INDEX IF NOT EXISTS idx_orderstatus_order ON "OrderStatus"("order");
CREATE INDEX IF NOT EXISTS idx_orderstatus_title ON "OrderStatus"(title);
CREATE INDEX IF NOT EXISTS idx_orderstatus_parent ON "OrderStatus"(parent_status_id);

-- Add unique constraint on title to match original Status table structure
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'OrderStatus_title_key' 
        AND table_name = 'OrderStatus'
    ) THEN
        ALTER TABLE "OrderStatus" ADD CONSTRAINT "OrderStatus_title_key" UNIQUE (title);
    END IF;
END $$;

-- =================================================================
-- STEP 2: Create the new BudgetStatus table
-- =================================================================
-- This table will contain status records where for_budget = true (Budget statuses)
CREATE TABLE IF NOT EXISTS "BudgetStatus" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_status_id UUID REFERENCES "BudgetStatus"(id) ON DELETE SET NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes and constraints for performance and data integrity
CREATE INDEX IF NOT EXISTS idx_budgetstatus_order ON "BudgetStatus"("order");
CREATE INDEX IF NOT EXISTS idx_budgetstatus_title ON "BudgetStatus"(title);
CREATE INDEX IF NOT EXISTS idx_budgetstatus_parent ON "BudgetStatus"(parent_status_id);

-- Add unique constraint on title to match original Status table structure
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'BudgetStatus_title_key' 
        AND table_name = 'BudgetStatus'
    ) THEN
        ALTER TABLE "BudgetStatus" ADD CONSTRAINT "BudgetStatus_title_key" UNIQUE (title);
    END IF;
END $$;

-- =================================================================
-- STEP 3: Create the new ComponentStatus table
-- =================================================================
-- This table will initially have the same status records as OrderStatus
-- It's designed for future component-specific status tracking
CREATE TABLE IF NOT EXISTS "ComponentStatus" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_status_id UUID REFERENCES "ComponentStatus"(id) ON DELETE SET NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes and constraints for performance and data integrity
CREATE INDEX IF NOT EXISTS idx_componentstatus_order ON "ComponentStatus"("order");
CREATE INDEX IF NOT EXISTS idx_componentstatus_title ON "ComponentStatus"(title);
CREATE INDEX IF NOT EXISTS idx_componentstatus_parent ON "ComponentStatus"(parent_status_id);

-- Add unique constraint on title to match original Status table structure
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'ComponentStatus_title_key' 
        AND table_name = 'ComponentStatus'
    ) THEN
        ALTER TABLE "ComponentStatus" ADD CONSTRAINT "ComponentStatus_title_key" UNIQUE (title);
    END IF;
END $$;

-- =================================================================
-- STEP 4: Migrate data from Status to OrderStatus
-- =================================================================
-- Insert all status records where for_budget = false into OrderStatus table
INSERT INTO "OrderStatus" (id, title, description, "order", created_at, updated_at)
SELECT 
    id,
    title,
    description,
    "order",
    created_at,
    updated_at
FROM "Status"
WHERE for_budget = false
ON CONFLICT (id) DO NOTHING; -- Prevent duplicates if script is run multiple times

-- Update parent_status_id references for OrderStatus
UPDATE "OrderStatus" 
SET parent_status_id = s.parent_status_id
FROM "Status" s
WHERE "OrderStatus".id = s.id 
    AND s.parent_status_id IS NOT NULL 
    AND s.for_budget = false;

-- =================================================================
-- STEP 5: Migrate data from Status to BudgetStatus
-- =================================================================
-- Insert all status records where for_budget = true into BudgetStatus table
INSERT INTO "BudgetStatus" (id, title, description, "order", created_at, updated_at)
SELECT 
    id,
    title,
    description,
    "order",
    created_at,
    updated_at
FROM "Status"
WHERE for_budget = true
ON CONFLICT (id) DO NOTHING; -- Prevent duplicates if script is run multiple times

-- Update parent_status_id references for BudgetStatus
UPDATE "BudgetStatus" 
SET parent_status_id = s.parent_status_id
FROM "Status" s
WHERE "BudgetStatus".id = s.id 
    AND s.parent_status_id IS NOT NULL 
    AND s.for_budget = true;

-- =================================================================
-- STEP 6: Populate ComponentStatus with OrderStatus data
-- =================================================================
-- Initially populate ComponentStatus with the same data as OrderStatus
-- This creates a separate status system for components that can evolve independently
INSERT INTO "ComponentStatus" (title, description, "order", created_at, updated_at)
SELECT 
    title,
    description,
    "order",
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM "OrderStatus"
ORDER BY "order" ASC
ON CONFLICT (title) DO NOTHING; -- Prevent duplicates if script is run multiple times

-- Update parent_status_id references for ComponentStatus
-- Map parent relationships from OrderStatus to ComponentStatus
UPDATE "ComponentStatus" 
SET parent_status_id = target_cs.id
FROM "OrderStatus" os
JOIN "OrderStatus" parent_os ON os.parent_status_id = parent_os.id
JOIN "ComponentStatus" source_cs ON source_cs.title = os.title AND source_cs."order" = os."order"
JOIN "ComponentStatus" target_cs ON target_cs.title = parent_os.title AND target_cs."order" = parent_os."order"
WHERE "ComponentStatus".id = source_cs.id;

-- =================================================================
-- STEP 7: Create mapping tables for ID correspondence
-- =================================================================
-- These tables will help map old Status IDs to new table IDs during the migration
-- They can be dropped after migration is complete

-- Mapping table for OrderStatus
CREATE TEMPORARY TABLE status_orderstatus_mapping AS
SELECT 
    s.id as old_status_id,
    os.id as new_orderstatus_id
FROM "Status" s
JOIN "OrderStatus" os ON s.id = os.id
WHERE s.for_budget = false;

-- Mapping table for BudgetStatus  
CREATE TEMPORARY TABLE status_budgetstatus_mapping AS
SELECT 
    s.id as old_status_id,
    bs.id as new_budgetstatus_id
FROM "Status" s
JOIN "BudgetStatus" bs ON s.id = bs.id
WHERE s.for_budget = true;

-- Mapping table for ComponentStatus (maps by title and order since IDs are different)
CREATE TEMPORARY TABLE orderstatus_componentstatus_mapping AS
SELECT 
    os.id as orderstatus_id,
    cs.id as componentstatus_id
FROM "OrderStatus" os
JOIN "ComponentStatus" cs ON os.title = cs.title AND os."order" = cs."order";

-- =================================================================
-- STEP 8: Fix data inconsistencies before adding constraints
-- =================================================================

-- Check and fix Order table status_id references
-- Some orders might have status_id pointing to budget statuses (for_budget = true)
-- We need to set these to a default order status before adding the foreign key constraint

-- First, let's identify problematic records and fix them
DO $$
DECLARE
    default_order_status_id UUID;
    invalid_records_count INTEGER;
BEGIN
    -- Get the default order status (first status with for_budget = false, order = 0)
    SELECT id INTO default_order_status_id 
    FROM "OrderStatus" 
    WHERE "order" = 0 
    ORDER BY "order" ASC, title ASC 
    LIMIT 1;
    
    -- Count invalid records
    SELECT COUNT(*) INTO invalid_records_count
    FROM "Order" o
    WHERE o.status_id IS NOT NULL 
    AND NOT EXISTS (SELECT 1 FROM "OrderStatus" os WHERE os.id = o.status_id);
    
    -- Log the findings
    RAISE NOTICE 'Found % Order records with invalid status_id references', invalid_records_count;
    RAISE NOTICE 'Using default OrderStatus ID: %', default_order_status_id;
    
    -- Fix invalid references by setting them to default order status
    IF default_order_status_id IS NOT NULL AND invalid_records_count > 0 THEN
        UPDATE "Order"
        SET status_id = default_order_status_id
        WHERE status_id IS NOT NULL 
        AND NOT EXISTS (SELECT 1 FROM "OrderStatus" os WHERE os.id = "Order".status_id);
        
        RAISE NOTICE 'Updated % Order records with default OrderStatus', invalid_records_count;
    END IF;
    
    -- Handle NULL status_id records
    UPDATE "Order"
    SET status_id = default_order_status_id
    WHERE status_id IS NULL AND default_order_status_id IS NOT NULL;
    
    GET DIAGNOSTICS invalid_records_count = ROW_COUNT;
    RAISE NOTICE 'Updated % Order records with NULL status_id', invalid_records_count;
END $$;

-- =================================================================
-- STEP 9: Update foreign key references in dependent tables
-- =================================================================

-- Now safely add Order table constraint to reference OrderStatus
DO $$
BEGIN
    -- Check if constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_order_orderstatus'
        AND table_name = 'Order'
    ) THEN
        ALTER TABLE "Order" 
        ADD CONSTRAINT fk_order_orderstatus 
        FOREIGN KEY (status_id) REFERENCES "OrderStatus"(id);
        RAISE NOTICE 'Added Order -> OrderStatus foreign key constraint';
    ELSE
        RAISE NOTICE 'Order -> OrderStatus foreign key constraint already exists';
    END IF;
END $$;

-- Check and fix ComponentBudget table before adding constraint
-- Ensure all ComponentBudget.status_id references exist in BudgetStatus
DO $$
DECLARE
    default_budget_status_id UUID;
    invalid_budget_records_count INTEGER;
BEGIN
    -- Get the default budget status (first status with for_budget = true, order = 0)
    SELECT id INTO default_budget_status_id 
    FROM "BudgetStatus" 
    WHERE "order" = 0 
    ORDER BY "order" ASC, title ASC 
    LIMIT 1;
    
    -- Count and fix invalid ComponentBudget references
    SELECT COUNT(*) INTO invalid_budget_records_count
    FROM "ComponentBudget" cb
    WHERE cb.status_id IS NOT NULL 
    AND NOT EXISTS (SELECT 1 FROM "BudgetStatus" bs WHERE bs.id = cb.status_id);
    
    RAISE NOTICE 'Found % ComponentBudget records with invalid status_id references', invalid_budget_records_count;
    
    -- Fix invalid references
    IF default_budget_status_id IS NOT NULL AND invalid_budget_records_count > 0 THEN
        UPDATE "ComponentBudget"
        SET status_id = default_budget_status_id
        WHERE status_id IS NOT NULL 
        AND NOT EXISTS (SELECT 1 FROM "BudgetStatus" bs WHERE bs.id = "ComponentBudget".status_id);
    END IF;
    
    -- Handle NULL status_id records
    UPDATE "ComponentBudget"
    SET status_id = default_budget_status_id
    WHERE status_id IS NULL AND default_budget_status_id IS NOT NULL;
END $$;

-- Now safely add ComponentBudget constraint
DO $$
BEGIN
    -- Check if constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_componentbudget_budgetstatus'
        AND table_name = 'ComponentBudget'
    ) THEN
        ALTER TABLE "ComponentBudget"
        ADD CONSTRAINT fk_componentbudget_budgetstatus
        FOREIGN KEY (status_id) REFERENCES "BudgetStatus"(id);
        RAISE NOTICE 'Added ComponentBudget -> BudgetStatus foreign key constraint';
    ELSE
        RAISE NOTICE 'ComponentBudget -> BudgetStatus foreign key constraint already exists';
    END IF;
END $$;

-- Check and fix OrderStatusHistory table before adding constraint
-- Ensure all OrderStatusHistory.status_id references exist in OrderStatus
DO $$
DECLARE
    invalid_history_records_count INTEGER;
BEGIN
    -- Count invalid OrderStatusHistory references
    SELECT COUNT(*) INTO invalid_history_records_count
    FROM "OrderStatusHistory" osh
    WHERE osh.status_id IS NOT NULL 
    AND NOT EXISTS (SELECT 1 FROM "OrderStatus" os WHERE os.id = osh.status_id);
    
    RAISE NOTICE 'Found % OrderStatusHistory records with invalid status_id references', invalid_history_records_count;
    
    -- For history records, we'll delete invalid ones as they represent historical data
    -- that no longer makes sense after the migration
    IF invalid_history_records_count > 0 THEN
        DELETE FROM "OrderStatusHistory"
        WHERE status_id IS NOT NULL 
        AND NOT EXISTS (SELECT 1 FROM "OrderStatus" os WHERE os.id = "OrderStatusHistory".status_id);
        
        RAISE NOTICE 'Deleted % invalid OrderStatusHistory records', invalid_history_records_count;
    END IF;
END $$;

-- Now safely add OrderStatusHistory constraint
DO $$
BEGIN
    -- Check if constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_orderstatushistory_orderstatus'
        AND table_name = 'OrderStatusHistory'
    ) THEN
        ALTER TABLE "OrderStatusHistory"
        ADD CONSTRAINT fk_orderstatushistory_orderstatus
        FOREIGN KEY (status_id) REFERENCES "OrderStatus"(id);
        RAISE NOTICE 'Added OrderStatusHistory -> OrderStatus foreign key constraint';
    ELSE
        RAISE NOTICE 'OrderStatusHistory -> OrderStatus foreign key constraint already exists';
    END IF;
END $$;

-- =================================================================
-- STEP 10: Add Component.status_id column for future use (FIXED)
-- =================================================================
-- Add status_id column to Component table to track component status
-- This will reference ComponentStatus and is prepared for future functionality
-- FIXED: Check current Component table structure first

DO $$
DECLARE
    has_status_id BOOLEAN;
    has_created_by_id BOOLEAN;
    has_updated_by_id BOOLEAN;
    component_count INTEGER;
    default_component_status_id UUID;
BEGIN
    RAISE NOTICE '🔍 CHECKING COMPONENT TABLE STRUCTURE';
    RAISE NOTICE '===================================';
    
    -- Check Component table structure
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'status_id'
    ) INTO has_status_id;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'created_by_id'
    ) INTO has_created_by_id;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'updated_by_id'
    ) INTO has_updated_by_id;
    
    SELECT COUNT(*) FROM "Component" INTO component_count;
    
    RAISE NOTICE 'Component table analysis:';
    RAISE NOTICE '  - Total components: %', component_count;
    RAISE NOTICE '  - Has status_id: %', CASE WHEN has_status_id THEN '✅' ELSE '❌' END;
    RAISE NOTICE '  - Has created_by_id: %', CASE WHEN has_created_by_id THEN '✅' ELSE '❌' END;
    RAISE NOTICE '  - Has updated_by_id: %', CASE WHEN has_updated_by_id THEN '✅' ELSE '❌' END;
    
    -- Add status_id column if it doesn't exist
    IF NOT has_status_id THEN
        RAISE NOTICE '📝 Adding status_id column to Component table...';
        ALTER TABLE "Component"
        ADD COLUMN status_id UUID REFERENCES "ComponentStatus"(id);
        RAISE NOTICE '✅ status_id column added successfully';
    ELSE
        RAISE NOTICE '⏭️  status_id column already exists in Component table';
    END IF;
    
    -- Get default component status
    SELECT id INTO default_component_status_id 
    FROM "ComponentStatus" 
    WHERE "order" = 0 
    ORDER BY "order" ASC, title ASC 
    LIMIT 1;
    
    -- Set default status for existing components with NULL status_id
    UPDATE "Component"
    SET status_id = default_component_status_id
    WHERE status_id IS NULL AND default_component_status_id IS NOT NULL;
    
    GET DIAGNOSTICS component_count = ROW_COUNT;
    RAISE NOTICE '📊 Updated % components with default status', component_count;
    RAISE NOTICE '';
END $$;

-- =================================================================
-- STEP 11: Remove old foreign key constraints from Status table
-- =================================================================
-- Remove the old foreign key constraint from Status table if it exists
-- This step might need to be adjusted based on actual constraint names
DO $$ 
DECLARE
    constraint_record RECORD;
    constraint_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🗑️  REMOVING OLD STATUS TABLE CONSTRAINTS';
    RAISE NOTICE '====================================';
    
    -- Find and remove all foreign key constraints referencing the old Status table
    FOR constraint_record IN
        SELECT 
            tc.table_name,
            tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND ccu.table_name = 'Status'
        AND tc.table_schema = 'public'
    LOOP
        constraint_count := constraint_count + 1;
        RAISE NOTICE '🗑️  Dropping constraint % from table %', constraint_record.constraint_name, constraint_record.table_name;
        
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
            constraint_record.table_name, 
            constraint_record.constraint_name);
            
        RAISE NOTICE '✅ Constraint dropped successfully';
    END LOOP;
    
    IF constraint_count = 0 THEN
        RAISE NOTICE '⏭️  No foreign key constraints to old Status table found';
    ELSE
        RAISE NOTICE '📊 Removed % foreign key constraints to old Status table', constraint_count;
    END IF;
    
    RAISE NOTICE '';
END $$;

-- =================================================================
-- STEP 12: Drop the original Status table
-- =================================================================
-- Remove the original Status table since it's no longer needed
-- All data has been migrated to the appropriate new tables
DO $$
DECLARE
    status_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🗑️  DROPPING ORIGINAL STATUS TABLE';
    RAISE NOTICE '==============================';
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' 
        AND table_name = 'Status'
    ) INTO status_exists;
    
    IF status_exists THEN
        RAISE NOTICE '🗑️  Dropping Status table...';
        DROP TABLE IF EXISTS "Status" CASCADE;
        RAISE NOTICE '✅ Status table dropped successfully';
    ELSE
        RAISE NOTICE '⏭️  Status table already removed';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- =================================================================
-- STEP 13: Clean up temporary tables
-- =================================================================
-- Drop temporary mapping tables used during migration
DROP TABLE IF EXISTS status_orderstatus_mapping;
DROP TABLE IF EXISTS status_budgetstatus_mapping;
DROP TABLE IF EXISTS orderstatus_componentstatus_mapping;

-- =================================================================
-- STEP 14: Final verification and summary
-- =================================================================
DO $$
DECLARE
    orderstatus_count INTEGER;
    budgetstatus_count INTEGER;
    componentstatus_count INTEGER;
    order_refs INTEGER;
    budget_refs INTEGER;
    history_refs INTEGER;
BEGIN
    RAISE NOTICE '✅ FINAL VERIFICATION';
    RAISE NOTICE '===================';
    
    -- Count records in new tables
    SELECT COUNT(*) FROM "OrderStatus" INTO orderstatus_count;
    SELECT COUNT(*) FROM "BudgetStatus" INTO budgetstatus_count;
    SELECT COUNT(*) FROM "ComponentStatus" INTO componentstatus_count;
    
    -- Count foreign key references
    SELECT COUNT(*) FROM "Order" WHERE status_id IS NOT NULL INTO order_refs;
    SELECT COUNT(*) FROM "ComponentBudget" WHERE status_id IS NOT NULL INTO budget_refs;
    SELECT COUNT(*) FROM "OrderStatusHistory" WHERE status_id IS NOT NULL INTO history_refs;
    
    RAISE NOTICE '📊 MIGRATION RESULTS:';
    RAISE NOTICE '  - OrderStatus records: %', orderstatus_count;
    RAISE NOTICE '  - BudgetStatus records: %', budgetstatus_count;
    RAISE NOTICE '  - ComponentStatus records: %', componentstatus_count;
    RAISE NOTICE '';
    RAISE NOTICE '🔗 FOREIGN KEY REFERENCES:';
    RAISE NOTICE '  - Orders with status: %', order_refs;
    RAISE NOTICE '  - ComponentBudgets with status: %', budget_refs;
    RAISE NOTICE '  - OrderStatusHistory records: %', history_refs;
    RAISE NOTICE '';
    RAISE NOTICE '🎉 STATUS REFACTORING MIGRATION COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '';
    RAISE NOTICE '📝 SUMMARY:';
    RAISE NOTICE '  ✅ Created OrderStatus, BudgetStatus, ComponentStatus tables';
    RAISE NOTICE '  ✅ Migrated all Status data to appropriate new tables';
    RAISE NOTICE '  ✅ Updated all foreign key references';
    RAISE NOTICE '  ✅ Added Component.status_id column for future functionality';
    RAISE NOTICE '  ✅ Dropped original Status table';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NEXT STEPS:';
    RAISE NOTICE '  1. Test application functionality with new status tables';
    RAISE NOTICE '  2. Update API endpoints to use appropriate status tables';
    RAISE NOTICE '  3. Consider running create_history_tables.sql for audit trail';
    RAISE NOTICE '  4. Update frontend to work with new status structure';
    RAISE NOTICE '';
END $$;

-- =================================================================
-- Commit the transaction
-- =================================================================
COMMIT;

RAISE NOTICE '🚀 Transaction committed - Status refactoring migration complete!'; 