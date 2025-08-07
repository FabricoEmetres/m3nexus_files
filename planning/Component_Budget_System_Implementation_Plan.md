# Plano de Implementação: Sistema de Orçamentação por Componente

**Autor:** Thúlio Silva  
**Data:** 23 de Julho de 2025  
**Versão:** 1.0  

## Resumo Executivo

Este documento detalha o plano completo para implementação de um novo sistema de orçamentação por componente, permitindo que usuários Forge e Post-Forge criem orçamentos específicos para versões individuais de componentes 3D, substituindo o atual sistema de orçamentação global por pedido.

## Contexto e Objetivos

### Situação Atual
- Orçamentação é feita a nível de pedido completo
- Acesso via modal de orçamentos com botão "+" que atualmente apenas registra logs
- Falta de granularidade para orçamentação por componente e versão específica

### Objetivos do Projeto
1. **Orçamentação Granular**: Permitir orçamentação individual por componente e versão
2. **Fluxo Especializado**: Diferentes interfaces para Forge e Post-Forge
3. **Experiência Fluida**: Mudança dinâmica de versões sem recarregamento de página
4. **Dados Contextuais**: Integração com dados do pedido para melhor contexto
5. **Persistência Local**: Salvamento automático do progresso do formulário

## Arquitetura do Sistema

### Estrutura de URLs
```
/component/[basecomponentId]/[version]/budget/
```

**Componentes da URL:**
- `basecomponentId`: Campo `component_base_id` da tabela Component
- `version`: String no formato "v1", "v2", "v3", etc.
- Exemplo: `/component/abc123-def456/v2/budget/`

### Estrutura de Pastas Frontend
```
00_frontend/src/app/component/
├── [basecomponentId]/
│   └── [version]/
│       └── budget/
│           ├── page.js          # Página principal de orçamentação
│           └── layout.js        # Layout com controle de permissões
```

### Componentes de Interface
```
00_frontend/src/components/forms/budgetforms/
├── ForgeBudgetForm.js           # Formulário específico do Forge
├── PostForgeBudgetForm.js       # Formulário específico do Post-Forge
├── ComponentBudgetTitle.js      # Título da página de orçamentação
└── VersionSelector.js           # Seletor dinâmico de versões
```

## Análise da Base de Dados

### Tabelas Principais Envolvidas

#### 1. Tabela `Component`
**Função:** Armazena versões específicas de componentes
**Campos Relevantes:**
- `id` (UUID): Identificador único da versão
- `component_base_id` (UUID): Referência ao componente "pai"
- `version` (INTEGER): Número da versão
- `material_id` (UUID): Material pré-selecionado
- `machine_id` (UUID): Máquina pré-selecionada
- `title` (VARCHAR): Título do componente
- `dimen_x`, `dimen_y`, `dimen_z` (NUMERIC): Dimensões
- `max_weight`, `min_weight` (NUMERIC): Pesos

#### 2. Tabela `ComponentBudget`
**Função:** Armazena orçamentos criados para componentes
**Campos Relevantes:**
- `id` (UUID): Identificador único do orçamento
- `component_id` (UUID): Referência à versão específica do componente
- `forge_id` (UUID): ID do usuário Forge responsável
- `status_id` (UUID): Status atual do orçamento
- `version` (INTEGER): Versão do orçamento
- Campos de valores financeiros e datas

#### 3. Tabela `Order_Component`
**Função:** Relaciona pedidos com componentes e quantidades
**Campos Relevantes:**
- `order_id` (UUID): ID do pedido
- `component_id` (UUID): ID da versão do componente
- `quantity` (INTEGER): Quantidade solicitada

### Relacionamentos Críticos
- `Component.component_base_id` → `Component.id` (auto-referência para versionamento)
- `ComponentBudget.component_id` → `Component.id` (orçamento para versão específica)
- `Order_Component.component_id` → `Component.id` (componente no pedido)

## Especificações Funcionais

### Fluxo de Navegação
1. **Origem**: Modal de orçamentos (`BudgetsModalContent.js`)
2. **Ação**: Clique no botão "+" de adicionar orçamento
3. **Destino**: `/component/[basecomponentId]/[version]/budget/`
4. **Contexto**: Página carrega com versão específica selecionada no modal

### Controle de Acesso
**Implementação:** Layout.js com verificação de role
**Roles Permitidos:**
- `Forge`: Acesso completo ao formulário de orçamentação Forge
- `Post-Forge`: Acesso completo ao formulário de orçamentação Post-Forge
**Roles Negados:** Todos os outros (redirecionamento para página de erro)

### Mudança Dinâmica de Versão
**Comportamento:**
1. Dropdown de versões carregado com todas as versões do `component_base_id`
2. Seleção de nova versão atualiza URL via `router.replace()` com `shallow: true`
3. Dados da nova versão carregados via fetch API
4. Formulário atualizado sem perda do progresso atual
5. Estado local preservado durante a transição

## Especificações Técnicas por Role

### Formulário Forge (`ForgeBudgetForm.js`)

#### Campos Pré-preenchidos (Não Editáveis)
- **Máquina**: Valor do campo `machine_id` da versão do componente
- **Material Principal**: Valor do campo `material_id` da versão do componente
- **Dimensões**: Valores de `dimen_x`, `dimen_y`, `dimen_z`
- **Pesos**: Valores de `max_weight`, `min_weight`

#### Campos Editáveis Específicos do Forge
1. **Material de Suporte**
   - Tipo: Dropdown de materiais compatíveis
   - Fonte: Tabela `Material` filtrada por compatibilidade

2. **Itens por Mesa**
   - Tipo: Input numérico
   - Validação: Mínimo 1, máximo baseado em dimensões vs. volume da máquina

3. **Horas de Impressão por Mesa**
   - Tipo: Input numérico com decimais
   - Unidade: Horas

4. **Volume por Mesa**
   - Tipo: Input numérico com decimais
   - Unidade: cm³ ou ml

5. **Horas de Modelação**
   - Tipo: Input numérico com decimais
   - Unidade: Horas

6. **Horas de Slicing**
   - Tipo: Input numérico com decimais
   - Unidade: Horas

7. **Horas de Manutenção por Mesa**
   - Tipo: Input numérico com decimais
   - Unidade: Horas

#### Seção Condicional de Cura
**Condição de Exibição:** Material selecionado requer cura (campo `cure_time` não nulo)

**Campos da Seção de Cura:**
1. **Máquina de Cura**
   - Tipo: Dropdown de máquinas de cura disponíveis
   - Fonte: Tabela `Machine` filtrada por tecnologia de cura

2. **Horas de Cura**
   - Tipo: Input numérico com decimais
   - Valor padrão: `cure_time` do material
   - Unidade: Horas

3. **Itens Mesa de Cura**
   - Tipo: Input numérico
   - Validação: Mínimo 1

### Formulário Post-Forge (`PostForgeBudgetForm.js`)
**Nota:** Especificações a serem definidas em fase posterior, seguindo padrão similar ao Forge.

## Integração com Sistema Existente

### Componente OrderDetails
**Localização:** `/components/forms/fullforms/OrderDetails.js`
**Integração:** Reutilização completa na nova página
**Configuração:**
- `showBudgetButton`: false (não mostrar botão de orçamento)
- `showNavigateBackButton`: true (permitir voltar)
- `fullDetails`: true (mostrar detalhes completos)

### Modal de Orçamentos
**Localização:** `/components/ui/modals/BudgetsModalContent.js`
**Modificação:** Função `handleAddBudget` (linha 196)
**Nova Implementação:**
```javascript
const handleAddBudget = (componentBaseId, componentVersion, componentTitle) => {
  router.push(`/component/${componentBaseId}/v${componentVersion}/budget/`);
};
```

## Persistência de Estado Local

### Requisitos
1. **Auto-save**: Salvamento automático a cada mudança de campo
2. **Recuperação**: Restauração de dados ao retornar à página
3. **Limpeza**: Remoção de dados após submissão bem-sucedida
4. **Versionamento**: Estado separado por versão de componente

### Implementação
**Tecnologia:** localStorage do navegador
**Chave de Armazenamento:** `component_budget_${basecomponentId}_v${version}`
**Estrutura de Dados:** JSON com todos os campos do formulário

## APIs Backend Necessárias

### 1. GET `/api/component-budget-data`
**Parâmetros:**
- `componentId`: ID da versão específica do componente
- `orderId`: ID do pedido para contexto

**Resposta:**
```json
{
  "success": true,
  "data": {
    "component": { /* dados da versão do componente */ },
    "order": { /* dados do pedido */ },
    "availableVersions": [ /* todas as versões do component_base_id */ ],
    "preselectedData": { /* máquina, material, etc. */ },
    "compatibleMaterials": [ /* materiais de suporte compatíveis */ ],
    "cureRequirements": { /* dados de cura se necessário */ }
  }
}
```

### 2. POST `/api/submit-component-budget`
**Payload:**
```json
{
  "componentId": "uuid",
  "orderId": "uuid", 
  "budgetData": {
    "supportMaterial": "uuid",
    "itemsPerTable": 5,
    "printHoursPerTable": 8.5,
    "volumePerTable": 250.0,
    "modelingHours": 2.0,
    "slicingHours": 1.5,
    "maintenanceHoursPerTable": 0.5,
    "curing": {
      "machine": "uuid",
      "hours": 4.0,
      "itemsPerTable": 10
    }
  }
}
```

### 3. GET `/api/component-versions`
**Parâmetros:**
- `baseComponentId`: component_base_id

**Resposta:**
```json
{
  "success": true,
  "data": {
    "versions": [
      {
        "id": "uuid",
        "version": 1,
        "title": "Componente v1",
        "machine": { /* dados da máquina */ },
        "material": { /* dados do material */ }
      }
    ]
  }
}
```

## Fases de Implementação

### Fase 1: Preparação da Infraestrutura

**Objetivo:** Criar a estrutura básica de pastas e arquivos necessários para o sistema.

**Tarefas:**
1. **Criar estrutura de pastas**
   - Criar diretório `/app/component/[basecomponentId]/[version]/budget/`
   - Criar arquivos `page.js` e `layout.js` básicos

2. **Implementar controle de acesso**
   - Configurar `layout.js` com verificação de role (Forge e Post-Forge)
   - Implementar redirecionamento para página de erro para roles não autorizados

3. **Criar componentes base**
   - Criar `ComponentBudgetTitle.js`
   - Criar `VersionSelector.js` (sem funcionalidade completa)
   - Criar esqueletos de `ForgeBudgetForm.js` e `PostForgeBudgetForm.js`

4. **Modificar BudgetsModalContent.js**
   - Atualizar função `handleAddBudget` para navegar para a nova URL

**Entregáveis:**
- Estrutura de pastas e arquivos base
- Sistema de controle de acesso funcional
- Navegação básica do modal para a página de orçamentação

### Fase 2: Desenvolvimento do Frontend Base

**Objetivo:** Implementar a interface básica e o sistema de mudança dinâmica de versão.

**Tarefas:**
1. **Implementar página principal**
   - Integrar `OrderDetails` para exibir informações do pedido
   - Implementar lógica condicional para exibir formulário baseado no role

2. **Desenvolver seletor de versões**
   - Implementar dropdown com todas as versões disponíveis
   - Configurar atualização dinâmica de URL via `router.replace()`
   - Implementar carregamento de dados da nova versão via fetch

3. **Criar sistema de persistência local**
   - Implementar salvamento automático em localStorage
   - Configurar restauração de dados ao carregar página
   - Implementar limpeza de dados após submissão bem-sucedida

4. **Desenvolver APIs backend iniciais**
   - Implementar endpoint `/api/component-versions`
   - Implementar versão básica de `/api/component-budget-data`

**Entregáveis:**
- Página funcional com seletor de versões dinâmico
- Sistema de persistência local operacional
- APIs backend básicas implementadas

### Fase 3: Implementação do Formulário Forge

**Objetivo:** Desenvolver o formulário completo para usuários Forge.

**Tarefas:**
1. **Implementar campos pré-preenchidos**
   - Configurar exibição de máquina, material e dimensões
   - Implementar lógica para campos não editáveis

2. **Desenvolver campos específicos do Forge**
   - Implementar todos os campos editáveis com validações
   - Configurar cálculos automáticos quando aplicável
   - Implementar seção condicional de cura

3. **Configurar validações de formulário**
   - Implementar validações em tempo real
   - Configurar mensagens de erro específicas
   - Implementar validação de submissão

4. **Finalizar API de submissão**
   - Implementar endpoint `/api/submit-component-budget`
   - Configurar processamento e armazenamento de dados
   - Implementar retorno de confirmação e erros

**Entregáveis:**
- Formulário Forge completo e funcional
- Sistema de validação operacional
- API de submissão implementada

### Fase 4: Testes e Refinamentos

**Objetivo:** Garantir a qualidade e usabilidade do sistema.

**Tarefas:**
1. **Realizar testes funcionais**
   - Testar fluxo completo de criação de orçamento
   - Verificar mudança dinâmica de versões
   - Testar persistência local em diferentes cenários

2. **Implementar melhorias de UX**
   - Adicionar feedback visual durante operações
   - Melhorar responsividade em diferentes dispositivos
   - Otimizar tempos de carregamento

3. **Corrigir bugs e problemas**
   - Resolver problemas identificados nos testes
   - Otimizar consultas ao banco de dados
   - Melhorar tratamento de erros

4. **Documentar sistema**
   - Atualizar documentação técnica
   - Criar guia de usuário básico
   - Documentar APIs para referência futura

**Entregáveis:**
- Sistema testado e refinado
- Documentação completa
- Relatório de testes e correções

### Fase 5: Implementação do Formulário Post-Forge (Futura)

**Objetivo:** Expandir o sistema para incluir orçamentação Post-Forge.

**Tarefas:**
1. **Analisar requisitos específicos do Post-Forge**
   - Identificar campos necessários
   - Mapear fluxo de trabalho específico

2. **Desenvolver formulário Post-Forge**
   - Implementar campos específicos
   - Configurar validações e cálculos

3. **Integrar com sistema existente**
   - Configurar exibição condicional baseada em role
   - Implementar APIs específicas se necessário

4. **Testar e refinar**
   - Realizar testes funcionais
   - Implementar melhorias baseadas em feedback

**Entregáveis:**
- Formulário Post-Forge completo e funcional
- Sistema integrado para ambos os roles
- Documentação atualizada

## Considerações Finais

Este plano de implementação fornece um roteiro detalhado para o desenvolvimento do sistema de orçamentação por componente. A abordagem em fases permite um desenvolvimento incremental, com entregas funcionais a cada etapa.

A arquitetura proposta é escalável e flexível, permitindo futuras expansões como a adição de funcionalidades para Post-Forge ou a implementação de sub-componentes conforme mencionado nos requisitos futuros.

A implementação seguirá as melhores práticas de desenvolvimento web, com foco em experiência do usuário, performance e manutenibilidade do código.
