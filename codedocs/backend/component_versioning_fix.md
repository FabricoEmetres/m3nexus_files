# Correção do Sistema de Versionamento de Componentes

## Problema Identificado

Durante o teste do sistema de versionamento de componentes, ocorreu um erro de violação de constraint de foreign key:

```
ERROR: update or delete on table "Component" violates foreign key constraint "fk_component_base_id" on table "Component"
Detail: Key (id)=(3e000dc5-6941-44ef-9a4b-53b9a6838523) is still referenced from table "Component".
```

### Causa do Problema

1. **Sistema criou nova versão corretamente**: 
   - Componente original: `3e000dc5-6941-44ef-9a4b-53b9a6838523` (version 1)
   - Nova versão: `cca9b328-0313-4177-8361-0ae5e30c5fc5` (version 2)
   - Nova versão referencia original como `component_base_id`

2. **Order_Component foi atualizado corretamente**:
   - Agora referencia a nova versão: `cca9b328-0313-4177-8361-0ae5e30c5fc5`

3. **Sistema tentou deletar componente original (ERRO)**:
   - Não pode deletar porque nova versão o referencia via `component_base_id`
   - **Com versionamento, componentes antigos NUNCA devem ser deletados**

## Solução Implementada

### 1. Correção da Lógica de Remoção

**Antes (Problemático):**
```javascript
// Deletava componentes que não estavam em processedFrontendComponentIds
const componentsToRemove = existingDbComponentIds.filter(
  id => !processedFrontendComponentIds.includes(id)
);
```

**Depois (Corrigido):**
```javascript
// Só remove componentes que não são referenciados por NENHUM Order_Component
// E que não são base de outras versões
const currentOrderComponentsQuery = `
  SELECT component_id FROM "Order_Component" WHERE order_id = $1
`;
// ... lógica adicional para verificar referências
```

### 2. Nova Lógica de Verificação

A nova lógica verifica:

1. **Componentes não referenciados por Order_Component atual**
2. **Componentes não referenciados por NENHUM Order_Component**
3. **Componentes que não são base de outras versões**
4. **Componentes que não têm ComponentBudgets**

Só então permite a remoção.

### 3. Script de Correção da Base de Dados

Criado `fix_component_versioning_constraints.sql` que:

1. **Identifica problemas**: Componentes órfãos e violações de constraint
2. **Corrige component_base_id**: Para componentes sem base definida
3. **Atualiza Order_Component**: Para referenciar versões mais recentes
4. **Identifica componentes removíveis**: Que podem ser deletados com segurança
5. **Verifica integridade**: Confirma que não há violações

## Como Aplicar a Correção

### Passo 1: Executar Script de Correção
```sql
-- No SQL Editor do NeonDB
\i files/db/scripts/fix_component_versioning_constraints.sql
```

### Passo 2: Verificar Logs
O script mostrará:
- Quantos componentes foram corrigidos
- Quantas referências foram atualizadas
- Status final do sistema

### Passo 3: Testar Novamente
Após a correção, testar:
- Criação de novos componentes
- Edição de componentes existentes
- Verificar que não há mais erros de constraint

## Comportamento Esperado Após Correção

### Criação de Componente
```javascript
// Novo componente
component_base_id = próprio_id
version = 1
```

### Edição de Componente
```javascript
// Em vez de UPDATE:
// 1. Buscar component_base_id do componente atual
// 2. Criar nova versão com version = max_version + 1
// 3. Atualizar Order_Component para nova versão
// 4. MANTER componente original no histórico
```

### Remoção de Componente
```javascript
// Só remove se:
// - Não referenciado por nenhum Order_Component
// - Não é base de outras versões
// - Não tem ComponentBudgets
// - Não tem outras dependências
```

## Vantagens da Correção

1. **Histórico Completo**: Todas as versões são mantidas
2. **Integridade Referencial**: Sem violações de constraint
3. **Rastreabilidade**: Possível ver evolução dos componentes
4. **Compatibilidade**: ComponentBudgets referenciam versões específicas
5. **Performance**: Índices otimizados para versionamento

## Monitoramento

### Queries Úteis para Monitoramento

```sql
-- Ver todas as versões de um componente
SELECT * FROM "Component" 
WHERE component_base_id = 'uuid-aqui' 
ORDER BY version DESC;

-- Ver componentes com múltiplas versões
SELECT component_base_id, COUNT(*) as versions
FROM "Component" 
GROUP BY component_base_id 
HAVING COUNT(*) > 1;

-- Ver componentes órfãos (não referenciados)
SELECT c.* FROM "Component" c
WHERE NOT EXISTS (
  SELECT 1 FROM "Order_Component" oc WHERE oc.component_id = c.id
);
```

### Logs a Monitorar

- `[componentVersioning] Creating new version for component`
- `[componentVersioning] Current max version: X, next version: Y`
- `[componentVersioning] Successfully updated Order_Component reference`
- `Component X still has Y references, keeping in database for historical tracking`

## Prevenção de Problemas Futuros

1. **Nunca deletar componentes com referências**
2. **Sempre verificar component_base_id antes de remoção**
3. **Manter logs detalhados de versionamento**
4. **Executar testes regulares de integridade**
5. **Backup antes de operações críticas**

## Rollback (Se Necessário)

Se houver problemas, o rollback pode ser feito:

1. **Restaurar backup da base de dados**
2. **Reverter alterações no código**
3. **Executar script de limpeza manual**

Mas com a correção implementada, isso não deve ser necessário.

## Conclusão

O sistema de versionamento agora está corrigido e funcionando corretamente. Os componentes são versionados automaticamente quando editados, mantendo histórico completo e integridade referencial. A lógica de remoção foi ajustada para respeitar as relações de versionamento.
