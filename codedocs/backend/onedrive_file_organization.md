# Organização de Ficheiros OneDrive - M3 Nexus

## Visão Geral

Este documento descreve a estrutura hierárquica completa de organização de ficheiros no OneDrive utilizada pelo sistema M3 Nexus.

## Estrutura Raiz

A pasta raiz do sistema é configurada através da variável de ambiente `ONEDRIVE_FOLDER` e pode ser `Nexus_Files_DEV` (desenvolvimento) ou `Nexus_Files_PROD` (produção). Esta é a pasta principal onde toda a estrutura de ficheiros é organizada.

```
📁 Nexus_Files_DEV/ (ou Nexus_Files_PROD/)
├── 📁 _NEXUS_TEMP_FILES/              # Pasta temporária única para todos os uploads
├── 📁 [Nome_Cliente_1]/
├── 📁 [Nome_Cliente_2]/
└── 📁 [Nome_Cliente_N]/
```

## Pasta Temporária

### **_NEXUS_TEMP_FILES** - Staging Universal

A pasta `_NEXUS_TEMP_FILES` é a única pasta temporária do sistema, onde todos os ficheiros são inicialmente carregados antes de serem movidos para as suas localizações definitivas.

```
📁 _NEXUS_TEMP_FILES/
├── 📄 arquivo_temporario_1.xlsx      # Uploads de componentes regulares
├── 📄 arquivo_temporario_2.stl       # Uploads de orçamentos
├── 📄 arquivo_temporario_3.jpg       # Qualquer tipo de upload temporário
└── 📄 [outros_arquivos_temporários]
```

**Características:**
- Todos os uploads (normais e de budget) vão para esta pasta
- Ficheiros são movidos automaticamente para destinos finais após processamento
- Limpeza automática de ficheiros órfãos
- Acesso via APIs: `create-onedrive-upload-session.js` (staging) e `create-budget-upload-session.js`

## Estrutura de Clientes

### **[Nome_Cliente]** - Pasta do Cliente

Cada cliente tem uma pasta dedicada com nome sanitizado, onde são organizados todos os seus pedidos.

```
📁 [Nome_Cliente]/
├── 📁 [Titulo_Pedido_1]/
├── 📁 [Titulo_Pedido_2]/
└── 📁 [Titulo_Pedido_N]/
```

## Estrutura de Pedidos

### **[Titulo_Pedido]** - Pasta do Pedido

Dentro da pasta do cliente, cada pedido tem uma pasta com o título sanitizado, contendo todos os componentes do pedido.

```
📁 [Titulo_Pedido]/
├── 📁 [Componente_1]/
├── 📁 [Componente_2]/
└── 📁 [Componente_N]/
```

## Estrutura de Componentes

### **[Componente]** - Pasta do Componente

Cada componente possui uma estrutura fixa de 3 pastas principais:

```
📁 [Nome_Componente]/
├── 📁 00_CLIENT_FILES/
├── 📁 01_BUDGET/
└── 📁 02_FORGE/
```

### **00_CLIENT_FILES** - Ficheiros do Cliente

Contém todos os ficheiros fornecidos pelo cliente ou adicionados ao criar/editar pedidos.

**Funcionalidade:**
- Ficheiros carregados durante criação de pedidos (`neworder`)
- Ficheiros adicionados durante edição de pedidos (`orderdetails`)
- Suporte a todos os tipos de ficheiros
- Gestão automática via API `submit-new-order.js` e `submit-edit-orderdetail.js`

```
📁 00_CLIENT_FILES/
├── 📄 desenho_tecnico.pdf
├── 📄 modelo_inicial.stl
├── 📄 especificacoes.docx
└── 📄 [outros_ficheiros_cliente]
```

### **01_BUDGET** - Orçamentos e Versões

Esta pasta contém todas as versões de orçamentos submetidas para o componente, organizadas sequencialmente.

```
📁 01_BUDGET/
├── 📁 01_VERSION/
│   ├── 📁 00_EXCEL/
│   │   └── 📄 orcamento_v1.xlsx
│   ├── 📁 01_SLICE/
│   │   ├── 📁 00_SLICE_IMAGES/
│   │   │   ├── 📄 preview_1.jpg
│   │   │   ├── 📄 preview_2.png
│   │   │   └── 📄 [outras_imagens]
│   │   ├── 📄 modelo_fatiado.gcode
│   │   └── 📄 configuracoes_slice.json
│   ├── 📁 02_FINAL_STL/
│   │   ├── 📄 modelo_final.stl
│   │   └── 📄 [outros_modelos_finais]
│   └── 📁 03_BUDGET_APPROVAL_MAIL/
│       └── 📄 email_aprovacao_timestamp.html
├── 📁 02_VERSION/
│   ├── 📁 00_EXCEL/
│   ├── 📁 01_SLICE/
│   │   └── 📁 00_SLICE_IMAGES/
│   ├── 📁 02_FINAL_STL/
│   └── 📁 03_BUDGET_APPROVAL_MAIL/
└── 📁 [N]_VERSION/
```

#### **00_EXCEL** - Ficheiros de Orçamento

Contém os ficheiros Excel com os cálculos e detalhes do orçamento.

#### **01_SLICE** - Ficheiros de Fatiamento

Contém os ficheiros de slice/fatiamento do modelo 3D preparados para impressão.
- **00_SLICE_IMAGES** - Imagens de pré-visualização do fatiamento

#### **02_FINAL_STL** - Modelos Finais

Contém o ficheiro 3D final usado para criar o slice. Este pode ser diferente do ficheiro original do cliente, após otimizações para impressão.

#### **03_BUDGET_APPROVAL_MAIL** (Criada após aprovação)

Esta pasta é criada automaticamente apenas quando o orçamento é aprovado na página `budgetreview`. Contém o email operacional enviado à equipa de produção.

### **02_FORGE** - Ficheiros de Produção

Pasta livre para o modelador 3D (Forge) criar e guardar ficheiros relacionados com o componente.

```
📁 02_FORGE/
├── 📄 notas_tecnicas.txt
├── 📄 modelo_experimental.blend
├── 📄 testes_suporte.stl
└── 📄 [ficheiros_trabalho_forge]
```

**Características:**
- Pasta de trabalho livre para a equipa de produção
- Sem estrutura rígida
- Permite organização personalizada pelo Forge
- Não afeta o fluxo principal do sistema

## Exemplo de Estrutura Completa

```
📁 Nexus_Files_PROD/
├── 📁 _NEXUS_TEMP_FILES/
│   ├── 📄 temp_file_1.xlsx
│   ├── 📄 temp_file_2.stl
│   └── 📄 temp_file_3.jpg
├── 📁 Empresa_ABC_Lda/
│   ├── 📁 Projeto_Prototipo_Motor/
│   │   ├── 📁 Carter_Motor/
│   │   │   ├── 📁 00_CLIENT_FILES/
│   │   │   │   ├── 📄 desenho_carter.pdf
│   │   │   │   └── 📄 modelo_base.step
│   │   │   ├── 📁 01_BUDGET/
│   │   │   │   ├── 📁 01_VERSION/
│   │   │   │   │   ├── 📁 00_EXCEL/
│   │   │   │   │   │   └── 📄 orcamento_carter_v1.xlsx
│   │   │   │   │   ├── 📁 01_SLICE/
│   │   │   │   │   │   ├── 📁 00_SLICE_IMAGES/
│   │   │   │   │   │   │   ├── 📄 layer_preview_1.png
│   │   │   │   │   │   │   └── 📄 layer_preview_2.png
│   │   │   │   │   │   └── 📄 carter_sliced.gcode
│   │   │   │   │   ├── 📁 02_FINAL_STL/
│   │   │   │   │   │   └── 📄 carter_final_optimized.stl
│   │   │   │   │   └── 📁 03_BUDGET_APPROVAL_MAIL/
│   │   │   │   │       └── 📄 email_aprovacao_2025-01-09_14-30.html
│   │   │   │   └── 📁 02_VERSION/
│   │   │   │       ├── 📁 00_EXCEL/
│   │   │   │       ├── 📁 01_SLICE/
│   │   │   │       ├── 📁 02_FINAL_STL/
│   │   │   │       └── 📁 03_BUDGET_APPROVAL_MAIL/
│   │   │   └── 📁 02_FORGE/
│   │   │       ├── 📄 notas_producao.txt
│   │   │       └── 📄 teste_suportes.stl
│   │   └── 📁 Tampa_Motor/
│   │       ├── 📁 00_CLIENT_FILES/
│   │       ├── 📁 01_BUDGET/
│   │       └── 📁 02_FORGE/
│   └── 📁 Projeto_Pecas_Reposicao/
└── 📁 Particular_Joao_Silva/
```

## Fluxo de Criação de Pastas

### Criação de Pedidos
1. Cria-se a pasta do cliente (se não existir)
2. Cria-se a pasta do pedido
3. Para cada componente:
   - Cria-se a pasta do componente
   - Cria-se as 3 subpastas: `00_CLIENT_FILES`, `01_BUDGET`, `02_FORGE`
4. Move-se ficheiros de `_NEXUS_TEMP_FILES` para `00_CLIENT_FILES`

### Submissão de Orçamentos
1. Cria-se a pasta da versão (ex: `01_VERSION`)
2. Cria-se as subpastas: `00_EXCEL`, `01_SLICE`, `02_FINAL_STL`
3. Cria-se a subpasta `00_SLICE_IMAGES` dentro de `01_SLICE`
4. Move-se ficheiros de staging para as pastas correspondentes

### Aprovação de Orçamentos
1. Cria-se a pasta `03_BUDGET_APPROVAL_MAIL`
2. Gera-se o ficheiro HTML do email operacional

## Variáveis de Ambiente

```env
# Pasta raiz principal
ONEDRIVE_FOLDER=Nexus_Files_PROD

# Pasta temporária (DEPRECIADA - agora usa _NEXUS_TEMP_FILES)
ONEDRIVE_STAGING_FOLDER=Nexus_Staging_Uploads
```

## Mapeamento na Base de Dados

### Tabela Order
```sql
client_onedrive_folder_id   -- Pasta do cliente
order_onedrive_folder_id    -- Pasta do pedido
```

### Tabela Component  
```sql
onedrive_folder_id              -- Pasta raiz do componente
onedrive_clientfiles_folder_id  -- Pasta 00_CLIENT_FILES
onedrive_budgets_folder_id      -- Pasta 01_BUDGET
onedrive_forge_folder_id        -- Pasta 02_FORGE
```

### Tabela ComponentBudget
```sql
onedrive_folder_id              -- Pasta da versão (ex: 01_VERSION)
onedrive_excel_folder_id        -- Pasta 00_EXCEL
onedrive_slice_folder_id        -- Pasta 01_SLICE
onedrive_stl_folder_id          -- Pasta 02_FINAL_STL
onedrive_slice_images_folder_id -- Pasta 00_SLICE_IMAGES
onedrive_operational_mail_file_id -- Ficheiro em 03_BUDGET_APPROVAL_MAIL
```

## Características Técnicas

1. **Sanitização**: Todos os nomes de pastas são sanitizados para compatibilidade OneDrive
2. **Atomicidade**: Criação de pastas em transações para garantir consistência
3. **Versionamento**: Orçamentos organizados por versões incrementais
4. **Staging**: Sistema temporário unificado para todos os uploads
5. **Cleanup**: Limpeza automática de ficheiros temporários órfãos

## APIs Relacionadas

- `create-onedrive-upload-session.js` - Upload para staging
- `create-budget-upload-session.js` - Upload de orçamentos para staging  
- `submit-new-order.js` - Criação estrutura pedidos
- `submit-component-budget.js` - Criação estrutura orçamentos
- `submit-budget-approval.js` - Criação pasta aprovação
- `delete-temp-file.js` - Limpeza ficheiros temporários 