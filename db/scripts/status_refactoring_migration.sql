-- =================================================================
-- Status Refactoring Migration Script
-- =================================================================
-- Author: Thúlio Silva
-- Date: Migration Script for Status Table Refactoring
-- 
-- Description: This script migrates the existing Status table into 
-- three separate tables: OrderStatus, BudgetStatus, and ComponentStatus.
-- It also updates all references in dependent tables.
-- =================================================================

-- Start transaction to ensure all operations complete successfully or rollback
BEGIN;

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
WHERE for_budget = false;

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
WHERE for_budget = true;

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
ORDER BY "order" ASC;

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
ALTER TABLE "Order" 
ADD CONSTRAINT fk_order_orderstatus 
FOREIGN KEY (status_id) REFERENCES "OrderStatus"(id);

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
ALTER TABLE "ComponentBudget"
ADD CONSTRAINT fk_componentbudget_budgetstatus
FOREIGN KEY (status_id) REFERENCES "BudgetStatus"(id);

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
ALTER TABLE "OrderStatusHistory"
ADD CONSTRAINT fk_orderstatushistory_orderstatus
FOREIGN KEY (status_id) REFERENCES "OrderStatus"(id);

-- =================================================================
-- STEP 10: Add Component.status_id column for future use
-- =================================================================
-- Add status_id column to Component table to track component status
-- This will reference ComponentStatus and is prepared for future functionality
ALTER TABLE "Component"
ADD COLUMN IF NOT EXISTS status_id UUID REFERENCES "ComponentStatus"(id);

-- Set default status for existing components (first status in ComponentStatus, order = 0)
UPDATE "Component"
SET status_id = (
    SELECT id FROM "ComponentStatus" 
    WHERE "order" = 0 
    ORDER BY "order" ASC, title ASC 
    LIMIT 1
)
WHERE status_id IS NULL;

-- =================================================================
-- STEP 11: Remove old foreign key constraints from Status table
-- =================================================================
-- Remove the old foreign key constraint from Status table if it exists
-- This step might need to be adjusted based on actual constraint names
DO $$ 
BEGIN
    -- Remove constraint from Order table to old Status table
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'order_status_id_fkey' 
        AND table_name = 'Order'
    ) THEN
        ALTER TABLE "Order" DROP CONSTRAINT order_status_id_fkey;
    END IF;

    -- Remove constraint from ComponentBudget table to old Status table
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'componentbudget_status_id_fkey' 
        AND table_name = 'ComponentBudget'
    ) THEN
        ALTER TABLE "ComponentBudget" DROP CONSTRAINT componentbudget_status_id_fkey;
    END IF;

    -- Remove constraint from OrderStatusHistory table to old Status table
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'orderstatushistory_status_id_fkey' 
        AND table_name = 'OrderStatusHistory'
    ) THEN
        ALTER TABLE "OrderStatusHistory" DROP CONSTRAINT orderstatushistory_status_id_fkey;
    END IF;
END $$;

-- =================================================================
-- STEP 12: Drop the original Status table
-- =================================================================
-- Remove the original Status table since it's no longer needed
-- All data has been migrated to the appropriate new tables
DROP TABLE IF EXISTS "Status" CASCADE;

-- =================================================================
-- STEP 13: Verification queries (for debugging)
-- =================================================================
-- These queries help verify that the migration was successful
-- They can be uncommented and run separately to check the results

/*
-- Verify OrderStatus record count
SELECT 'OrderStatus' as table_name, COUNT(*) as record_count FROM "OrderStatus";

-- Verify BudgetStatus record count  
SELECT 'BudgetStatus' as table_name, COUNT(*) as record_count FROM "BudgetStatus";

-- Verify ComponentStatus record count
SELECT 'ComponentStatus' as table_name, COUNT(*) as record_count FROM "ComponentStatus";

-- Check Order table references
SELECT 'Order references check' as check_name, COUNT(*) as valid_references
FROM "Order" o
JOIN "OrderStatus" os ON o.status_id = os.id;

-- Check ComponentBudget table references
SELECT 'ComponentBudget references check' as check_name, COUNT(*) as valid_references  
FROM "ComponentBudget" cb
JOIN "BudgetStatus" bs ON cb.status_id = bs.id;

-- Check OrderStatusHistory table references
SELECT 'OrderStatusHistory references check' as check_name, COUNT(*) as valid_references
FROM "OrderStatusHistory" osh  
JOIN "OrderStatus" os ON osh.status_id = os.id;

-- Check Component table references (newly added column)
SELECT 'Component status references check' as check_name, COUNT(*) as valid_references
FROM "Component" c
JOIN "ComponentStatus" cs ON c.status_id = cs.id;
*/

-- =================================================================
-- STEP 14: Clean up temporary tables
-- =================================================================
-- Drop temporary mapping tables used during migration
DROP TABLE IF EXISTS status_orderstatus_mapping;
DROP TABLE IF EXISTS status_budgetstatus_mapping;
DROP TABLE IF EXISTS orderstatus_componentstatus_mapping;

-- =================================================================
-- Commit the transaction
-- =================================================================
-- If everything executed successfully, commit all changes
COMMIT;

-- =================================================================
-- Success message
-- =================================================================
-- Print success message (this works in some PostgreSQL clients)
DO $$ 
BEGIN 
    RAISE NOTICE 'Status refactoring migration completed successfully!';
    RAISE NOTICE 'Tables created: OrderStatus, BudgetStatus, ComponentStatus';
    RAISE NOTICE 'Original Status table dropped';
    RAISE NOTICE 'All foreign key references updated';
    RAISE NOTICE 'Component.status_id column added for future use';
END $$; 