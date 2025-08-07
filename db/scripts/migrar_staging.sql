
ALTER TABLE "Order"
	DROP CONSTRAINT fk_order_seller;

CREATE TABLE "AdminData" (
	user_id uuid NOT NULL,
	role_id uuid NOT NULL,
	updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE "AdminData" OWNER TO neondb_owner;

CREATE TABLE "AnalystData" (
	user_id uuid NOT NULL,
	role_id uuid NOT NULL,
	work_location character varying(100),
	updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE "AnalystData" OWNER TO neondb_owner;

CREATE TABLE "ComponentBudget" (
	id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
	forge_id uuid NOT NULL,
	component_id uuid NOT NULL,
	status_id uuid NOT NULL,
	client_id uuid,
	analyst_id uuid,
	version integer DEFAULT 1 NOT NULL,
	description text,
	internal_notes character varying(255),
	client_notes character varying(255),
	currency character varying(3) DEFAULT 'EUR'::character varying NOT NULL,
	budget_expiration_date timestamp(6) with time zone,
	order_deadline timestamp(6) with time zone,
	production_subtotal_value numeric(12,2),
	material_subtotal_value numeric(12,2),
	finishing_subtotal_value numeric(12,2),
	total_value numeric(12,2),
	other_costs numeric(12,2),
	tax_value numeric(12,2),
	tax_percentage numeric(5,2),
	discount_value numeric(12,2),
	discount_percentage numeric(5,2),
	discount_type character varying(50),
	send_to_client_date timestamp(6) with time zone,
	analyst_approval_date timestamp(6) with time zone,
	analyst_disapproval_date timestamp(6) with time zone,
	client_approval_date timestamp(6) with time zone,
	client_disapproval_date timestamp(6) with time zone,
	updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	estimated_forge_days integer,
	final_cost_per_piece numeric(12,2),
	final_price_per_piece numeric(12,2),
	estimated_prod_days integer,
	onedrive_folder_id text,
	onedrive_excel_folder_id text,
	onedrive_slice_folder_id text,
	onedrive_stl_folder_id text,
	onedrive_slice_images_folder_id text,
	onedrive_operational_mail_file_id text
);

ALTER TABLE "ComponentBudget" OWNER TO neondb_owner;

CREATE TABLE "ComponentBudgetFiles" (
	id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
	component_budget_id uuid NOT NULL,
	onedrive_item_id text NOT NULL,
	onedrive_web_url text NOT NULL,
	file_name text NOT NULL,
	file_type text NOT NULL,
	updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE "ComponentBudgetFiles" OWNER TO neondb_owner;

CREATE TABLE "OrderBudget" (
	id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
	forge_id uuid NOT NULL,
	order_id uuid NOT NULL,
	status_id uuid NOT NULL,
	client_id uuid NOT NULL,
	analyst_id uuid,
	version integer DEFAULT 1 NOT NULL,
	description text,
	internal_notes character varying(255),
	client_notes character varying(255),
	currency character varying(3) DEFAULT 'EUR'::character varying NOT NULL,
	budget_expiration_date timestamp(6) with time zone,
	order_deadline timestamp(6) with time zone,
	production_subtotal_value numeric(12,2),
	material_subtotal_value numeric(12,2),
	finishing_subtotal_value numeric(12,2),
	total_value numeric(12,2),
	other_costs numeric(12,2),
	tax_value numeric(12,2),
	tax_percentage numeric(5,2),
	discount_value numeric(12,2),
	discount_percentage numeric(5,2),
	discount_type character varying(50),
	send_to_client_date timestamp(6) with time zone,
	analyst_approval_date timestamp(6) with time zone,
	analyst_disapproval_date timestamp(6) with time zone,
	client_approval_date timestamp(6) with time zone,
	client_disapproval_date timestamp(6) with time zone,
	updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE "OrderBudget" OWNER TO neondb_owner;

CREATE TABLE "PaymentTerms" (
	id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
	title character varying(100) NOT NULL,
	description text,
	updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE "PaymentTerms" OWNER TO neondb_owner;

CREATE TABLE "Priority" (
	id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
	title character varying(100) NOT NULL,
	"level" integer NOT NULL,
	description text,
	updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE "Priority" OWNER TO neondb_owner;

CREATE TABLE "ProductionType" (
	id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
	title character varying(100) NOT NULL,
	description text,
	updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE "ProductionType" OWNER TO neondb_owner;

ALTER TABLE "Component"
	ADD COLUMN onedrive_clientfiles_folder_id text,
	ADD COLUMN onedrive_budgets_folder_id text,
	ADD COLUMN onedrive_forge_folder_id text;

ALTER TABLE "Order"
	DROP COLUMN priority,
	DROP COLUMN budget_due_date,
	DROP COLUMN budget_price,
	DROP COLUMN final_cost,
	DROP COLUMN finished_at,
	ADD COLUMN priority_id uuid,
	ADD COLUMN payment_terms_id uuid,
	ADD COLUMN production_type_id uuid,
	ALTER COLUMN is_urgent SET NOT NULL,
	ALTER COLUMN is_scan SET NOT NULL;

ALTER TABLE "Status"
	DROP COLUMN is_budget,
	ADD COLUMN for_budget boolean;

ALTER TABLE "AdminData"
	ADD CONSTRAINT "AdminData_pkey" PRIMARY KEY (user_id);

ALTER TABLE "AnalystData"
	ADD CONSTRAINT "AnalystData_pkey" PRIMARY KEY (user_id);

ALTER TABLE "ComponentBudget"
	ADD CONSTRAINT "ComponentBudge_pkey" PRIMARY KEY (id);

ALTER TABLE "ComponentBudgetFiles"
	ADD CONSTRAINT "ComponentBudgetFiles_pkey" PRIMARY KEY (id);

ALTER TABLE "OrderBudget"
	ADD CONSTRAINT "Budget_pkey" PRIMARY KEY (id);

ALTER TABLE "PaymentTerms"
	ADD CONSTRAINT "PaymentTerms_pkey" PRIMARY KEY (id);

ALTER TABLE "Priority"
	ADD CONSTRAINT "Priority_pkey" PRIMARY KEY (id);

ALTER TABLE "ProductionType"
	ADD CONSTRAINT "ProductionType_pkey" PRIMARY KEY (id);

ALTER TABLE "AdminData"
	ADD CONSTRAINT fk_admindata_role FOREIGN KEY (role_id) REFERENCES public."Role"(id) ON DELETE RESTRICT;

ALTER TABLE "AdminData"
	ADD CONSTRAINT fk_admindata_user FOREIGN KEY (user_id) REFERENCES public."User"(id) ON DELETE CASCADE;

ALTER TABLE "AnalystData"
	ADD CONSTRAINT fk_analystdata_role FOREIGN KEY (role_id) REFERENCES public."Role"(id) ON DELETE RESTRICT;

ALTER TABLE "AnalystData"
	ADD CONSTRAINT fk_analystdata_user FOREIGN KEY (user_id) REFERENCES public."User"(id) ON DELETE CASCADE;

ALTER TABLE "ComponentBudget"
	ADD CONSTRAINT fk_componentbudget_analyst FOREIGN KEY (analyst_id) REFERENCES public."AdminData"(user_id) ON DELETE RESTRICT;

ALTER TABLE "ComponentBudget"
	ADD CONSTRAINT fk_componentbudget_client FOREIGN KEY (client_id) REFERENCES public."ClientData"(user_id) ON DELETE RESTRICT;

ALTER TABLE "ComponentBudget"
	ADD CONSTRAINT fk_componentbudget_component FOREIGN KEY (component_id) REFERENCES public."Component"(id) ON DELETE RESTRICT;

ALTER TABLE "ComponentBudget"
	ADD CONSTRAINT fk_componentbudget_forge FOREIGN KEY (forge_id) REFERENCES public."UserData"(user_id) ON DELETE RESTRICT;

ALTER TABLE "ComponentBudget"
	ADD CONSTRAINT fk_componentbudget_status FOREIGN KEY (status_id) REFERENCES public."Status"(id) ON DELETE RESTRICT;

ALTER TABLE "ComponentBudgetFiles"
	ADD CONSTRAINT fk_componentbudgetfiles_componentbudget FOREIGN KEY (component_budget_id) REFERENCES public."ComponentBudget"(id) ON DELETE CASCADE;

ALTER TABLE "Order"
	ADD CONSTRAINT fk_order_payment_terms FOREIGN KEY (payment_terms_id) REFERENCES public."PaymentTerms"(id) ON DELETE RESTRICT;

ALTER TABLE "Order"
	ADD CONSTRAINT fk_order_priority FOREIGN KEY (priority_id) REFERENCES public."Priority"(id) ON DELETE RESTRICT;

ALTER TABLE "Order"
	ADD CONSTRAINT fk_order_production_type FOREIGN KEY (production_type_id) REFERENCES public."ProductionType"(id) ON DELETE RESTRICT;

ALTER TABLE "Order"
	ADD CONSTRAINT fk_order_seller FOREIGN KEY (seller_id) REFERENCES public."UserData"(user_id) ON DELETE RESTRICT;

ALTER TABLE "OrderBudget"
	ADD CONSTRAINT fk_budget_analyst FOREIGN KEY (analyst_id) REFERENCES public."AnalystData"(user_id) ON DELETE RESTRICT;

ALTER TABLE "OrderBudget"
	ADD CONSTRAINT fk_budget_client FOREIGN KEY (client_id) REFERENCES public."ClientData"(user_id) ON DELETE RESTRICT;

ALTER TABLE "OrderBudget"
	ADD CONSTRAINT fk_budget_forge FOREIGN KEY (forge_id) REFERENCES public."ForgeData"(user_id) ON DELETE RESTRICT;

ALTER TABLE "OrderBudget"
	ADD CONSTRAINT fk_budget_order FOREIGN KEY (order_id) REFERENCES public."Order"(id) ON DELETE RESTRICT;

ALTER TABLE "OrderBudget"
	ADD CONSTRAINT fk_budget_status FOREIGN KEY (status_id) REFERENCES public."Status"(id) ON DELETE RESTRICT;

CREATE INDEX idx_componentbudgetfiles_componentbudget_id ON "ComponentBudgetFiles" USING btree (component_budget_id);
