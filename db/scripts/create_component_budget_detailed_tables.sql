BEGIN;
his
-- 0) Extensão UUID (se necessário)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1) COMPONENTBUDGET: Novos campos (Forge/Cura + metadados mínimos de submissão)
ALTER TABLE public."ComponentBudget"
  ADD COLUMN IF NOT EXISTS submission_mode VARCHAR(20)
    CHECK (submission_mode IN ('forge', 'post-forge', 'admin')),
  ADD COLUMN IF NOT EXISTS submitted_by_user_id UUID
    REFERENCES public."User"(id),

  -- Forge (produção)
  ADD COLUMN IF NOT EXISTS support_material_id UUID
    REFERENCES public."Material"(id),
  ADD COLUMN IF NOT EXISTS support_volume_per_table NUMERIC(10,3),
  ADD COLUMN IF NOT EXISTS items_per_table INTEGER,
  ADD COLUMN IF NOT EXISTS print_hours_per_table INTEGER,         -- minutos
  ADD COLUMN IF NOT EXISTS volume_per_table NUMERIC(10,3),
  ADD COLUMN IF NOT EXISTS modeling_hours INTEGER,                -- minutos
  ADD COLUMN IF NOT EXISTS slicing_hours INTEGER,                 -- minutos
  ADD COLUMN IF NOT EXISTS maintenance_hours_per_table INTEGER,   -- minutos

  -- Cura
  ADD COLUMN IF NOT EXISTS curing_machine_id UUID
    REFERENCES public."MachineCure"(id),
  ADD COLUMN IF NOT EXISTS curing_hours INTEGER,                  -- minutos
  ADD COLUMN IF NOT EXISTS curing_items_per_table INTEGER,
  ADD COLUMN IF NOT EXISTS curing_auto_filled BOOLEAN DEFAULT FALSE;

-- Índices úteis nos novos FKs
CREATE INDEX IF NOT EXISTS idx_componentbudget_support_material
  ON public."ComponentBudget"(support_material_id);
CREATE INDEX IF NOT EXISTS idx_componentbudget_curing_machine
  ON public."ComponentBudget"(curing_machine_id);
CREATE INDEX IF NOT EXISTS idx_componentbudget_submitted_by
  ON public."ComponentBudget"(submitted_by_user_id);
CREATE INDEX IF NOT EXISTS idx_componentbudget_component
  ON public."ComponentBudget"(component_id);
CREATE INDEX IF NOT EXISTS idx_componentbudget_status
  ON public."ComponentBudget"(status_id);

-- 2) CATÁLOGO DE MATERIAIS DE ACABAMENTO (novo)
CREATE TABLE IF NOT EXISTS public."FinishingMaterial" (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  brand_name VARCHAR(100),                 -- Marca (conforme alinhado)
  description TEXT,
  default_unit_cost NUMERIC(10,2),
  currency CHAR(3) DEFAULT 'EUR',
  unit_of_measurement VARCHAR(20),        -- 'litre','kg','unit', etc.
  purchase_link TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Relação estática: quais materiais podem ser usados em cada acabamento
CREATE TABLE IF NOT EXISTS public."Finishing_FinishingMaterial" (
  finishing_id UUID NOT NULL REFERENCES public."Finishing"(id),
  finishing_material_id UUID NOT NULL REFERENCES public."FinishingMaterial"(id),
  is_required BOOLEAN DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (finishing_id, finishing_material_id)
);

CREATE INDEX IF NOT EXISTS idx_finishing_finmat_finishing
  ON public."Finishing_FinishingMaterial"(finishing_id);
CREATE INDEX IF NOT EXISTS idx_finishing_finmat_material
  ON public."Finishing_FinishingMaterial"(finishing_material_id);

-- 3) DINÂMICO POR ORÇAMENTO (ACABAMENTOS)
-- Por acabamento no orçamento: horas totais de secagem e (opcional) sequência neste orçamento
CREATE TABLE IF NOT EXISTS public."ComponentBudgetFinishing" (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  component_budget_id UUID NOT NULL REFERENCES public."ComponentBudget"(id) ON DELETE CASCADE,
  finishing_id UUID NOT NULL REFERENCES public."Finishing"(id),
  total_drying_hours NUMERIC(8,2) NOT NULL,   -- input do utilizador (por acabamento)
  sequence_override INTEGER,                  -- opcional reordenação neste orçamento
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (component_budget_id, finishing_id)
);

CREATE INDEX IF NOT EXISTS idx_cbf_budget
  ON public."ComponentBudgetFinishing"(component_budget_id);
CREATE INDEX IF NOT EXISTS idx_cbf_finishing
  ON public."ComponentBudgetFinishing"(finishing_id);

-- Materiais usados em cada acabamento do orçamento, com campos dinâmicos e snapshots
CREATE TABLE IF NOT EXISTS public."ComponentBudgetFinishingMaterial" (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  component_budget_finishing_id UUID NOT NULL
    REFERENCES public."ComponentBudgetFinishing"(id) ON DELETE CASCADE,
  finishing_material_id UUID NOT NULL REFERENCES public."FinishingMaterial"(id),

  -- Campos dinâmicos (neste trabalho)
  quantity NUMERIC(12,3) NOT NULL CHECK (quantity > 0),  -- consumo unitário
  quantity_uom VARCHAR(20),                               -- unidade ('litre','kg', etc.)
  application_hours NUMERIC(8,2) NOT NULL CHECK (application_hours > 0),

  -- Snapshots (imutabilidade do orçamento)
  unit_cost_snapshot NUMERIC(10,2),
  currency_snapshot CHAR(3),
  brand_name_snapshot VARCHAR(100),
  purchase_link_snapshot TEXT,

  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

  UNIQUE (component_budget_finishing_id, finishing_material_id)
);

CREATE INDEX IF NOT EXISTS idx_cbfm_budgetfin
  ON public."ComponentBudgetFinishingMaterial"(component_budget_finishing_id);
CREATE INDEX IF NOT EXISTS idx_cbfm_finishing_material
  ON public."ComponentBudgetFinishingMaterial"(finishing_material_id);

-- 4) COMPONENTBUDGETFILES: categorias de ficheiro e imagem de perfil
ALTER TABLE public."ComponentBudgetFiles"
  ADD COLUMN IF NOT EXISTS budget_category VARCHAR(20)
    CHECK (budget_category IN ('slice','sliceImage','excel')),
  ADD COLUMN IF NOT EXISTS is_profile_image BOOLEAN DEFAULT FALSE;

-- Índices úteis
CREATE INDEX IF NOT EXISTS idx_componentbudgetfiles_budget
  ON public."ComponentBudgetFiles"(component_budget_id);
CREATE INDEX IF NOT EXISTS idx_componentbudgetfiles_budget_category
  ON public."ComponentBudgetFiles"(component_budget_id, budget_category);

-- 5) LIMPEZA DE CAMPOS LEGADOS EM COMPONENTBUDGET
-- Remover cálculos, impostos, descontos, aprovações, versionamento e pastas OneDrive obsoletas
ALTER TABLE public."ComponentBudget"
  DROP COLUMN IF EXISTS production_subtotal_value,
  DROP COLUMN IF EXISTS material_subtotal_value,
  DROP COLUMN IF EXISTS finishing_subtotal_value,
  DROP COLUMN IF EXISTS total_value,
  DROP COLUMN IF EXISTS other_costs,
  DROP COLUMN IF EXISTS tax_value,
  DROP COLUMN IF EXISTS tax_percentage,
  DROP COLUMN IF EXISTS discount_value,
  DROP COLUMN IF EXISTS discount_percentage,
  DROP COLUMN IF EXISTS discount_type,
  DROP COLUMN IF EXISTS send_to_client_date,
  DROP COLUMN IF EXISTS analyst_approval_date,
  DROP COLUMN IF EXISTS analyst_disapproval_date,
  DROP COLUMN IF EXISTS client_approval_date,
  DROP COLUMN IF EXISTS client_disapproval_date,
  DROP COLUMN IF EXISTS estimated_forge_days,
  DROP COLUMN IF EXISTS final_cost_per_piece,
  DROP COLUMN IF EXISTS final_price_per_piece,
  DROP COLUMN IF EXISTS estimated_prod_days,
  DROP COLUMN IF EXISTS version,
  DROP COLUMN IF EXISTS onedrive_folder_id,
  DROP COLUMN IF EXISTS onedrive_excel_folder_id,
  DROP COLUMN IF EXISTS onedrive_slice_folder_id,
  DROP COLUMN IF EXISTS onedrive_stl_folder_id,
  DROP COLUMN IF EXISTS onedrive_slice_images_folder_id,
  DROP COLUMN IF EXISTS onedrive_operational_mail_file_id,
  DROP COLUMN IF EXISTS is_active;

-- 6) COMENTÁRIOS (documentação embutida)
COMMENT ON TABLE public."FinishingMaterial" IS 'Catálogo de materiais de acabamento (tintas, colas, etc.)';
COMMENT ON TABLE public."Finishing_FinishingMaterial" IS 'Relação estática: quais materiais são elegíveis para cada acabamento';
COMMENT ON TABLE public."ComponentBudgetFinishing" IS 'Relação dinâmica por orçamento: acabamentos aplicados e horas totais de secagem';
COMMENT ON TABLE public."ComponentBudgetFinishingMaterial" IS 'Relação dinâmica por orçamento: materiais usados em cada acabamento, com quantidades e tempo de aplicação';

COMMENT ON COLUMN public."ComponentBudget".support_material_id IS 'Material de suporte (impressão 3D) usado neste trabalho (FK Material)';
COMMENT ON COLUMN public."ComponentBudget".support_volume_per_table IS 'Volume de suporte por mesa (g)';
COMMENT ON COLUMN public."ComponentBudget".items_per_table IS 'Itens por mesa (impressão)';
COMMENT ON COLUMN public."ComponentBudget".volume_per_table IS 'Volume por mesa (g)';
COMMENT ON COLUMN public."ComponentBudget".print_hours_per_table IS 'Tempo de impressão por mesa (minutos)';
COMMENT ON COLUMN public."ComponentBudget".modeling_hours IS 'Tempo de modelação (minutos)';
COMMENT ON COLUMN public."ComponentBudget".slicing_hours IS 'Tempo de slicing (minutos)';
COMMENT ON COLUMN public."ComponentBudget".maintenance_hours_per_table IS 'Tempo de manutenção por mesa (minutos)';
COMMENT ON COLUMN public."ComponentBudget".curing_machine_id IS 'Máquina de cura (FK MachineCure)';
COMMENT ON COLUMN public."ComponentBudget".curing_hours IS 'Tempo de cura por mesa (minutos)';
COMMENT ON COLUMN public."ComponentBudget".curing_items_per_table IS 'Itens por mesa de cura';
COMMENT ON COLUMN public."ComponentBudgetFiles".budget_category IS 'Categoria do ficheiro: slice | sliceImage | excel';

COMMIT;