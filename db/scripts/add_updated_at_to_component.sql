--
-- Script para adicionar campo updated_at à tabela Component
-- Criado por: Thúlio Silva
--
-- Este script adiciona o campo updated_at à tabela Component seguindo
-- os padrões existentes na base de dados M3 Nexus.
--

-- 1. Primeiro, verificar se a função set_updated_at_timestamp() já existe
-- (Ela deveria já existir baseado no dump da BD)

-- 2. Verificar se a coluna updated_at já existe na tabela Component
SELECT CASE 
    WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Component' 
        AND column_name = 'updated_at'
    ) 
    THEN 'A coluna updated_at já existe na tabela Component'
    ELSE 'A coluna updated_at NÃO existe - será criada'
END as status_coluna;

-- 3. Adicionar a coluna updated_at se não existir
ALTER TABLE public."Component" 
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL;

-- 4. Atualizar registros existentes para que updated_at = created_at
-- Isso mantém a consistência histórica dos dados
UPDATE public."Component" 
SET updated_at = created_at 
WHERE updated_at = CURRENT_TIMESTAMP OR updated_at IS NULL;

-- 5. Verificar se o trigger já existe antes de criar
SELECT CASE 
    WHEN EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_component_updated_at' 
        AND tgrelid = 'public."Component"'::regclass
    ) 
    THEN 'Trigger trg_component_updated_at já existe'
    ELSE 'Trigger trg_component_updated_at NÃO existe - será criado'
END as status_trigger;

-- 6. Criar trigger se não existir
-- Nota: Se o trigger já existir, este comando irá dar erro, mas não afetará a operação
CREATE TRIGGER trg_component_updated_at 
    BEFORE UPDATE ON public."Component" 
    FOR EACH ROW 
    EXECUTE FUNCTION public.set_updated_at_timestamp();

-- 7. Verificações finais
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'Component' 
            AND column_name = 'updated_at'
        ) 
        THEN '✅ SIM' 
        ELSE '❌ NÃO' 
    END as coluna_updated_at_existe,
    
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'trg_component_updated_at' 
            AND tgrelid = 'public."Component"'::regclass
        ) 
        THEN '✅ SIM' 
        ELSE '❌ NÃO' 
    END as trigger_existe,
    
    COUNT(*) as total_registros_component
FROM public."Component";

-- 8. Exemplo de como testar o funcionamento:
-- Descomente as linhas abaixo para testar:

-- UPDATE public."Component" SET title = title WHERE id = (SELECT id FROM public."Component" LIMIT 1);
-- SELECT id, title, created_at, updated_at FROM public."Component" LIMIT 5;

-- COMENTÁRIOS:
-- - Este script pode ser executado múltiplas vezes sem problemas
-- - A coluna updated_at será automaticamente atualizada em cada UPDATE devido ao trigger  
-- - Para novos INSERTs, o valor DEFAULT CURRENT_TIMESTAMP será aplicado
-- - O formato timestamp with time zone é consistente com created_at
-- - Se o trigger já existir, verá uma mensagem de erro na linha 45, mas isso é normal
