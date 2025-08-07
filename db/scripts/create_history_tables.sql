-- =================================================================
-- History Tables Creation Script
-- =================================================================
-- Author: Thúlio Silva
-- Date: History Tables Creation Script
-- 
-- Description: This script creates BudgetStatusHistory and ComponentStatusHistory 
-- tables based on the existing OrderStatusHistory structure. These tables will 
-- track status changes for ComponentBudget and Component entities respectively.
-- 
-- PREREQUISITES: This script requires the new status tables (OrderStatus, 
-- BudgetStatus, ComponentStatus) to exist. Run status_refactoring_migration_fixed.sql first.
-- 
-- COMPATIBILITY: Updated to work with Component table that has created_by_id 
-- (instead of updated_by_id) due to component versioning system.
-- =================================================================

-- Start transaction to ensure all operations complete successfully or rollback
BEGIN;

-- =================================================================
-- PRELIMINARY CHECK: Verify required status tables exist
-- =================================================================
DO $$
DECLARE
    orderstatus_exists BOOLEAN;
    budgetstatus_exists BOOLEAN;
    componentstatus_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🔍 PRELIMINARY CHECKS';
    RAISE NOTICE '===================';
    
    -- Check if required status tables exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' 
        AND table_name = 'OrderStatus'
    ) INTO orderstatus_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' 
        AND table_name = 'BudgetStatus'
    ) INTO budgetstatus_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' 
        AND table_name = 'ComponentStatus'
    ) INTO componentstatus_exists;
    
    RAISE NOTICE 'Required tables status:';
    RAISE NOTICE '  - OrderStatus: %', CASE WHEN orderstatus_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
    RAISE NOTICE '  - BudgetStatus: %', CASE WHEN budgetstatus_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
    RAISE NOTICE '  - ComponentStatus: %', CASE WHEN componentstatus_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
    
    -- Verify all required tables exist
    IF NOT (orderstatus_exists AND budgetstatus_exists AND componentstatus_exists) THEN
        RAISE EXCEPTION '❌ Missing required status tables. Please run status_refactoring_migration_fixed.sql first.';
    END IF;
    
    RAISE NOTICE '✅ All required status tables found - proceeding with history tables creation';
    RAISE NOTICE '';
END $$;

-- =================================================================
-- STEP 1: Create BudgetStatusHistory table
-- =================================================================
-- This table will track status changes for ComponentBudget records
-- Structure based on OrderStatusHistory but referencing ComponentBudget and BudgetStatus
CREATE TABLE IF NOT EXISTS "BudgetStatusHistory" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component_budget_id UUID NOT NULL REFERENCES "ComponentBudget"(id) ON DELETE CASCADE,
    status_id UUID NOT NULL REFERENCES "BudgetStatus"(id) ON DELETE RESTRICT,
    user_id UUID NULL REFERENCES "User"(id) ON DELETE SET NULL,
    notes TEXT NULL,
    change_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance on BudgetStatusHistory
-- Index on component_budget_id for fast lookups by budget
CREATE INDEX IF NOT EXISTS idx_budgetstatushistory_component_budget 
ON "BudgetStatusHistory"(component_budget_id);

-- Index on status_id for fast lookups by status
CREATE INDEX IF NOT EXISTS idx_budgetstatushistory_status 
ON "BudgetStatusHistory"(status_id);

-- Index on user_id for fast lookups by user
CREATE INDEX IF NOT EXISTS idx_budgetstatushistory_user 
ON "BudgetStatusHistory"(user_id);

-- Index on change_timestamp for chronological queries
CREATE INDEX IF NOT EXISTS idx_budgetstatushistory_timestamp 
ON "BudgetStatusHistory"(change_timestamp);

-- Composite index for common query patterns (budget + timestamp)
CREATE INDEX IF NOT EXISTS idx_budgetstatushistory_budget_timestamp 
ON "BudgetStatusHistory"(component_budget_id, change_timestamp DESC);

-- Composite index for latest status per budget queries
CREATE INDEX IF NOT EXISTS idx_budgetstatushistory_budget_status_timestamp 
ON "BudgetStatusHistory"(component_budget_id, status_id, change_timestamp DESC);

-- =================================================================
-- STEP 2: Create ComponentStatusHistory table
-- =================================================================
-- This table will track status changes for Component records
-- Structure based on OrderStatusHistory but referencing Component and ComponentStatus
CREATE TABLE IF NOT EXISTS "ComponentStatusHistory" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    component_id UUID NOT NULL REFERENCES "Component"(id) ON DELETE CASCADE,
    status_id UUID NOT NULL REFERENCES "ComponentStatus"(id) ON DELETE RESTRICT,
    user_id UUID NULL REFERENCES "User"(id) ON DELETE SET NULL,
    notes TEXT NULL,
    change_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance on ComponentStatusHistory
-- Index on component_id for fast lookups by component
CREATE INDEX IF NOT EXISTS idx_componentstatushistory_component 
ON "ComponentStatusHistory"(component_id);

-- Index on status_id for fast lookups by status
CREATE INDEX IF NOT EXISTS idx_componentstatushistory_status 
ON "ComponentStatusHistory"(status_id);

-- Index on user_id for fast lookups by user
CREATE INDEX IF NOT EXISTS idx_componentstatushistory_user 
ON "ComponentStatusHistory"(user_id);

-- Index on change_timestamp for chronological queries
CREATE INDEX IF NOT EXISTS idx_componentstatushistory_timestamp 
ON "ComponentStatusHistory"(change_timestamp);

-- Composite index for common query patterns (component + timestamp)
CREATE INDEX IF NOT EXISTS idx_componentstatushistory_component_timestamp 
ON "ComponentStatusHistory"(component_id, change_timestamp DESC);

-- Composite index for latest status per component queries
CREATE INDEX IF NOT EXISTS idx_componentstatushistory_component_status_timestamp 
ON "ComponentStatusHistory"(component_id, status_id, change_timestamp DESC);

-- =================================================================
-- STEP 3: Create helper functions for history tracking
-- =================================================================

-- Function to automatically insert BudgetStatusHistory when ComponentBudget status changes
CREATE OR REPLACE FUNCTION track_budget_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only insert history if status_id actually changed
    IF OLD.status_id IS DISTINCT FROM NEW.status_id THEN
        INSERT INTO "BudgetStatusHistory" (
            component_budget_id, 
            status_id, 
            user_id, 
            notes, 
            change_timestamp
        ) VALUES (
            NEW.id,
            NEW.status_id,
            COALESCE(NEW.analyst_id, NEW.forge_id), -- Use analyst_id first, then forge_id (ComponentBudget doesn't have updated_by_id)
            CASE 
                WHEN OLD.status_id IS NULL THEN 'Status inicial definido'
                ELSE 'Status atualizado automaticamente'
            END,
            CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically insert ComponentStatusHistory when Component status changes
CREATE OR REPLACE FUNCTION track_component_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only insert history if status_id actually changed
    IF OLD.status_id IS DISTINCT FROM NEW.status_id THEN
        INSERT INTO "ComponentStatusHistory" (
            component_id, 
            status_id, 
            user_id, 
            notes, 
            change_timestamp
        ) VALUES (
            NEW.id,
            NEW.status_id,
            NEW.created_by_id, -- Use created_by_id from Component table (updated from updated_by_id)
            CASE 
                WHEN OLD.status_id IS NULL THEN 'Status inicial definido'
                ELSE 'Status atualizado automaticamente'
            END,
            CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =================================================================
-- STEP 4: Create triggers for automatic history tracking
-- =================================================================

-- Trigger for ComponentBudget status changes
DROP TRIGGER IF EXISTS trg_componentbudget_status_history ON "ComponentBudget";
CREATE TRIGGER trg_componentbudget_status_history
    AFTER INSERT OR UPDATE OF status_id ON "ComponentBudget"
    FOR EACH ROW
    EXECUTE FUNCTION track_budget_status_change();

-- Trigger for Component status changes
-- This trigger tracks when Component.status_id changes and logs it to ComponentStatusHistory
DROP TRIGGER IF EXISTS trg_component_status_history ON "Component";
CREATE TRIGGER trg_component_status_history
    AFTER INSERT OR UPDATE OF status_id ON "Component"
    FOR EACH ROW
    EXECUTE FUNCTION track_component_status_change();

-- =================================================================
-- STEP 5: Populate initial history records for existing data
-- =================================================================

-- Insert initial history records for all existing ComponentBudget records
-- This creates a baseline history showing when each budget was created with its current status
INSERT INTO "BudgetStatusHistory" (
    component_budget_id,
    status_id,
    user_id,
    notes,
    change_timestamp
)
SELECT 
    cb.id as component_budget_id,
    cb.status_id,
    COALESCE(cb.analyst_id, cb.forge_id) as user_id, -- Use analyst_id if available, otherwise forge_id (ComponentBudget doesn't have updated_by_id)
    'Histórico inicial - Status definido na criação do orçamento' as notes,
    cb.created_at as change_timestamp
FROM "ComponentBudget" cb
WHERE cb.status_id IS NOT NULL
ON CONFLICT DO NOTHING; -- In case this script is run multiple times

-- Insert initial history records for all existing Component records with status
-- Only for components that already have a status_id set (should be all of them after migration)
INSERT INTO "ComponentStatusHistory" (
    component_id,
    status_id,
    user_id,
    notes,
    change_timestamp
)
SELECT 
    c.id as component_id,
    c.status_id,
    c.created_by_id as user_id, -- Use created_by_id instead of updated_by_id (field was renamed)
    'Histórico inicial - Status definido na criação/migração do componente' as notes,
    COALESCE(c.created_at, CURRENT_TIMESTAMP) as change_timestamp
FROM "Component" c
WHERE c.status_id IS NOT NULL
ON CONFLICT DO NOTHING; -- In case this script is run multiple times

-- =================================================================
-- STEP 6: Create views for easy access to latest status information
-- =================================================================

-- View to get the latest status information for each ComponentBudget
CREATE OR REPLACE VIEW "LatestBudgetStatusHistory" AS
SELECT DISTINCT ON (bsh.component_budget_id)
    bsh.id,
    bsh.component_budget_id,
    bsh.status_id,
    bs.title as status_title,
    bs.description as status_description,
    bs."order" as status_order,
    bsh.user_id,
    u.name as user_name,
    u.surname as user_surname,
    bsh.notes,
    bsh.change_timestamp
FROM "BudgetStatusHistory" bsh
LEFT JOIN "BudgetStatus" bs ON bsh.status_id = bs.id
LEFT JOIN "User" u ON bsh.user_id = u.id
ORDER BY bsh.component_budget_id, bsh.change_timestamp DESC;

-- View to get the latest status information for each Component
CREATE OR REPLACE VIEW "LatestComponentStatusHistory" AS
SELECT DISTINCT ON (csh.component_id)
    csh.id,
    csh.component_id,
    csh.status_id,
    cs.title as status_title,
    cs.description as status_description,
    cs."order" as status_order,
    csh.user_id,
    u.name as user_name,
    u.surname as user_surname,
    csh.notes,
    csh.change_timestamp
FROM "ComponentStatusHistory" csh
LEFT JOIN "ComponentStatus" cs ON csh.status_id = cs.id
LEFT JOIN "User" u ON csh.user_id = u.id
ORDER BY csh.component_id, csh.change_timestamp DESC;

-- =================================================================
-- STEP 7: Add comments for documentation
-- =================================================================

-- Add comments to tables
COMMENT ON TABLE "BudgetStatusHistory" IS 'Tracks status changes for ComponentBudget records, maintaining a complete audit trail of budget status transitions';
COMMENT ON TABLE "ComponentStatusHistory" IS 'Tracks status changes for Component records, maintaining a complete audit trail of component status transitions';

-- Add comments to columns
COMMENT ON COLUMN "BudgetStatusHistory".component_budget_id IS 'Reference to the ComponentBudget whose status changed';
COMMENT ON COLUMN "BudgetStatusHistory".status_id IS 'Reference to the BudgetStatus that was applied';
COMMENT ON COLUMN "BudgetStatusHistory".user_id IS 'User who triggered the status change (nullable for system changes)';
COMMENT ON COLUMN "BudgetStatusHistory".notes IS 'Optional notes about the status change';
COMMENT ON COLUMN "BudgetStatusHistory".change_timestamp IS 'Exact timestamp when the status change occurred';

COMMENT ON COLUMN "ComponentStatusHistory".component_id IS 'Reference to the Component whose status changed';
COMMENT ON COLUMN "ComponentStatusHistory".status_id IS 'Reference to the ComponentStatus that was applied';
COMMENT ON COLUMN "ComponentStatusHistory".user_id IS 'User who triggered the status change (nullable for system changes)';
COMMENT ON COLUMN "ComponentStatusHistory".notes IS 'Optional notes about the status change';
COMMENT ON COLUMN "ComponentStatusHistory".change_timestamp IS 'Exact timestamp when the status change occurred';

-- =================================================================
-- STEP 8: Grant appropriate permissions
-- =================================================================

-- Grant SELECT permissions to all users (assuming they have access to related tables)
-- These permissions should match the permissions on OrderStatusHistory
-- Adjust as needed based on your application's security model

-- Note: Specific GRANT statements should be customized based on your user roles
-- Example permissions (uncomment and modify as needed):
/*
GRANT SELECT ON "BudgetStatusHistory" TO your_read_only_role;
GRANT INSERT, SELECT ON "BudgetStatusHistory" TO your_app_role;
GRANT SELECT ON "ComponentStatusHistory" TO your_read_only_role;
GRANT INSERT, SELECT ON "ComponentStatusHistory" TO your_app_role;
GRANT SELECT ON "LatestBudgetStatusHistory" TO your_read_only_role;
GRANT SELECT ON "LatestComponentStatusHistory" TO your_read_only_role;
*/

-- =================================================================
-- STEP 9: Verification and summary
-- =================================================================

-- Verification queries to ensure everything was created successfully
DO $$ 
DECLARE
    budget_history_count INTEGER;
    component_history_count INTEGER;
    componentbudget_count INTEGER;
    component_count INTEGER;
BEGIN 
    -- Count initial history records
    SELECT COUNT(*) INTO budget_history_count FROM "BudgetStatusHistory";
    SELECT COUNT(*) INTO component_history_count FROM "ComponentStatusHistory";
    
    -- Count source data records
    SELECT COUNT(*) INTO componentbudget_count FROM "ComponentBudget";
    SELECT COUNT(*) INTO component_count FROM "Component" WHERE status_id IS NOT NULL;
    
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'History Tables Creation completed successfully!';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '📊 TABLES CREATED:';
    RAISE NOTICE '  - BudgetStatusHistory: % initial records (from % ComponentBudgets)', budget_history_count, componentbudget_count;
    RAISE NOTICE '  - ComponentStatusHistory: % initial records (from % Components)', component_history_count, component_count;
    RAISE NOTICE '';
    RAISE NOTICE '👁️  VIEWS CREATED:';
    RAISE NOTICE '  - LatestBudgetStatusHistory (latest status per ComponentBudget)';
    RAISE NOTICE '  - LatestComponentStatusHistory (latest status per Component)';
    RAISE NOTICE '';
    RAISE NOTICE '⚡ TRIGGERS CREATED:';   
    RAISE NOTICE '  - trg_componentbudget_status_history → tracks ComponentBudget.status_id changes';
    RAISE NOTICE '  - trg_component_status_history → tracks Component.status_id changes';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FUNCTIONS CREATED:';
    RAISE NOTICE '  - track_budget_status_change() → handles ComponentBudget status history';
    RAISE NOTICE '  - track_component_status_change() → handles Component status history';
    RAISE NOTICE '';
    RAISE NOTICE '✅ FEATURES ACTIVE:';
    RAISE NOTICE '  ✅ Automatic status change tracking via triggers';
    RAISE NOTICE '  ✅ Complete audit trail for all status changes';
    RAISE NOTICE '  ✅ Optimized indexes for high-performance queries';
    RAISE NOTICE '  ✅ Helper views for latest status information';
    RAISE NOTICE '  ✅ Initial history baseline populated for existing data';
    RAISE NOTICE '  ✅ Compatible with Component versioning system (uses created_by_id)';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 READY FOR USE:';
    RAISE NOTICE '  - ComponentBudget status changes will be automatically logged';
    RAISE NOTICE '  - Component status changes will be automatically logged';
    RAISE NOTICE '  - History queries can use LatestBudgetStatusHistory & LatestComponentStatusHistory views';
    RAISE NOTICE '';
    RAISE NOTICE '=================================================================';
END $$;

-- =================================================================
-- Commit the transaction
-- =================================================================
COMMIT; 