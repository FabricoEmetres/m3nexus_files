# Mapeamento Detalhado dos Dados de Submissão de Orçamento de Componente

**Autor:** Thúlio Silva  
**Data:** Janeiro 2025  
**Versão:** 1.0  
**Status:** 📋 Documentação Técnica - Mapeamento Completo

---

## 🎯 Objetivo do Documento

Este documento mapeia **extremamente detalhadamente** todos os dados coletados na página de orçamentação de componentes 3D (`/component/[basecomponentId]/[version]/budget/`) que serão submetidos do frontend para a nova API de submissão de orçamento.

### Contexto da Página Analisada
- **Página:** `/component/[basecomponentId]/[version]/budget/page.js`
- **Formulários:** ForgeBudgetForm.js + PostForgeBudgetForm.js
- **Sistema:** Orçamentação por componente individual
- **Usuários:** Forge, Post-Forge, Admin

---

## 🏗️ Estrutura Geral da Submissão

```javascript
const budgetSubmissionPayload = {
  // === METADADOS DO CONTEXTO ===
  context: {
    basecomponentId: string,           // UUID do componente base
    componentId: string,               // UUID do componente específico (versão)
    version: number,                   // Número da versão (1, 2, 3...)
    orderId: string | null,            // UUID do pedido (opcional)
    userRole: string,                  // "Forge", "Post-Forge", "Admin"
    submissionTimestamp: string,       // ISO timestamp da submissão
    formType: string                   // "forge", "post-forge", "combined"
  },

  // === DADOS DO COMPONENTE (PRÉ-PREENCHIDOS) ===
  componentData: {
    id: string,                        // UUID do componente
    component_base_id: string,         // UUID do componente base
    version: number,                   // Versão do componente
    title: string,                     // Nome do componente
    description: string,               // Descrição do componente
    dimensions: {
      x: number,                       // Dimensão X em mm
      y: number,                       // Dimensão Y em mm
      z: number                        // Dimensão Z em mm
    },
    weight: {
      min: number,                     // Peso mínimo em gramas
      max: number                      // Peso máximo em gramas
    },
    preselectedData: {
      machine: {
        id: string,                    // UUID da máquina
        model: string,                 // Modelo da máquina
        manufacturer: {
          id: string,                  // UUID do fabricante
          name: string                 // Nome do fabricante
        },
        technology: {
          id: string,                  // UUID da tecnologia
          name: string,                // Nome da tecnologia
          technical_name: string       // Nome técnico
        },
        buildVolume: {
          x: number,                   // Volume X em mm
          y: number,                   // Volume Y em mm
          z: number                    // Volume Z em mm
        },
        location: string,              // Localização da máquina
        printResolution: string        // Resolução de impressão
      },
      material: {
        id: string,                    // UUID do material
        name: string,                  // Nome do material
        description: string,           // Descrição do material
        colorName: string,             // Nome da cor
        costPer1g: number,             // Custo por grama
        manufacturer: {
          id: string,                  // UUID do fabricante
          name: string                 // Nome do fabricante
        },
        materialType: {
          id: string,                  // UUID do tipo
          name: string,                // Nome do tipo
          technicalName: string        // Nome técnico
        },
        requiresCuring: boolean        // Se requer cura
      }
    }
  },

  // === DADOS DO FORMULÁRIO FORGE ===
  forgeData: {
    // Parâmetros de Produção
    production: {
      supportMaterial: {
        id: string | null,             // UUID do material de suporte
        name: string | null,           // Nome do material de suporte
        costPer1g: number | null       // Custo por grama
      },
      itemsPerTable: number,           // Número de itens por mesa
      printHoursPerTable: number,      // Horas de impressão por mesa (em minutos)
      volumePerTable: number,          // Volume por mesa em gramas
      supportVolumePerTable: number,   // Volume de suporte por mesa em gramas
      
      // Estimativas de Tempo (todos em minutos)
      timeEstimates: {
        modelingHours: number,         // Horas de modelagem
        slicingHours: number,          // Horas de slicing
        maintenanceHoursPerTable: number // Horas de manutenção por mesa
      }
    },

    // Parâmetros de Cura (condicional)
    curing: {
      isRequired: boolean,             // Se a cura é necessária
      machine: {
        id: string | null,             // UUID da máquina de cura
        model: string | null,          // Modelo da máquina
        manufacturer: {
          id: string | null,           // UUID do fabricante
          name: string | null          // Nome do fabricante
        }
      },
      hours: number,                   // Horas de cura (em minutos)
      itemsPerTable: number,           // Itens por mesa de cura
      autoFilledFromMachine: boolean   // Se foi preenchido automaticamente
    },

    // Comentários
    comments: {
      internal: string,                // Comentários internos
      external: string                 // Comentários para o cliente
    },

    // Arquivos Carregados
    uploadedFiles: [
      {
        tempId: string,                // ID temporário do arquivo
        oneDriveItemId: string,        // ID do item no OneDrive
        fileName: string,              // Nome do arquivo
        fileSize: number,              // Tamanho em bytes
        mimeType: string,              // Tipo MIME
        budgetCategory: string,        // "sliceImage", "slice", "excel"
        uploadTimestamp: string,       // ISO timestamp do upload
        status: string,                // "success", "pending", "error"
        isProfileImage: boolean        // Se é a imagem de perfil selecionada
      }
    ],

    // Imagem de Perfil
    profileImage: {
      oneDriveItemId: string | null,   // ID da imagem selecionada como perfil
      fileName: string | null,         // Nome do arquivo da imagem
      isUserSelected: boolean,         // Se foi selecionada pelo usuário
      fallbackToFirst: boolean         // Se usa a primeira imagem como fallback
    }
  },

  // === DADOS DO FORMULÁRIO POST-FORGE ===
  postForgeData: {
    finishings: [
      {
        id: string,                    // ID do acabamento
        name: string,                  // Nome do acabamento
        description: string,           // Descrição do acabamento
        sequence: number,              // Ordem de execução
        finishingType: string,         // Tipo de acabamento
        totalDryingHours: number,      // Horas totais de secagem

        // Materiais do Acabamento
        materials: [
          {
            id: string,                // ID do material (temp_ para novos)

            // Campos Dinâmicos (destacados/prioritários)
            dynamicFields: {
              unitConsumption: number, // Consumo unitário
              applicationHours: number // Tempo de Aplicação (convertidas de minutos)
            },

            // Campos Estáticos (podem ser pré-preenchidos)
            staticFields: {
              name: string,            // Nome do material
              description: string,     // Descrição do material
              unitCost: number,        // Custo unitário
              supplierName: string,    // Nome do fornecedor/marca
              purchaseLink: string     // Link de compra
            },

            // Metadados
            metadata: {
              isNew: boolean,          // Se é um material novo
              isDuplicated: boolean,   // Se foi duplicado de outro
              originalMaterialId: string | null, // ID do material original (se duplicado)
              createdAt: string,       // Timestamp de criação
              lastModified: string     // Timestamp da última modificação
            }
          }
        ]
      }
    ]
  },

  // === DADOS DE CÁLCULO E ORÇAMENTO ===
  budgetCalculations: {
    // Campos obrigatórios da API atual
    estimated_forge_days: number,     // Dias estimados de produção
    final_cost_per_piece: number,     // Custo final por peça
    final_price_per_piece: number,    // Preço final por peça
    estimated_prod_days: number,      // Dias estimados de produção total

    // Novos campos calculados
    calculations: {
      forge: {
        materialCost: number,          // Custo do material principal
        supportMaterialCost: number,   // Custo do material de suporte
        machineCost: number,           // Custo da máquina
        laborCost: number,             // Custo da mão de obra
        curingCost: number,            // Custo da cura
        totalForgeCost: number         // Custo total do Forge
      },
      postForge: {
        finishingsCosts: [
          {
            finishingId: string,       // ID do acabamento
            materialsCost: number,     // Custo dos materiais
            laborCost: number,         // Custo da mão de obra
            totalFinishingCost: number // Custo total do acabamento
          }
        ],
        totalPostForgeCost: number     // Custo total do Post-Forge
      },
      totals: {
        totalMaterialCost: number,     // Custo total de materiais
        totalLaborCost: number,        // Custo total de mão de obra
        totalProductionCost: number,   // Custo total de produção
        profitMargin: number,          // Margem de lucro
        finalPrice: number             // Preço final
      }
    }
  },

  // === DADOS DE PERSISTÊNCIA E ESTADO ===
  persistence: {
    localStorage: {
      forgeStorageKey: string,         // Chave do localStorage do Forge
      postForgeStorageKey: string,     // Chave do localStorage do Post-Forge
      lastSaved: string,               // Timestamp da última gravação
      hasUnsavedChanges: boolean       // Se há alterações não salvas
    },

    formState: {
      isValid: boolean,                // Se o formulário é válido
      validationErrors: object,        // Erros de validação
      hasChanges: boolean,             // Se há alterações
      completionPercentage: number     // Percentual de preenchimento
    }
  },

  // === DADOS DE UPLOAD E ARQUIVOS ===
  fileManagement: {
    uploadManager: {
      storageKey: string,              // Chave de armazenamento do upload manager
      enablePersistence: boolean,      // Se a persistência está ativada
      ttl: number,                     // Time to live em milissegundos
      totalFiles: number,              // Total de arquivos
      successfulUploads: number,       // Uploads bem-sucedidos
      failedUploads: number            // Uploads falhados
    },

    filesToDelete: [                   // Arquivos marcados para exclusão
      {
        oneDriveItemId: string,        // ID do item no OneDrive
        fileName: string,              // Nome do arquivo
        reason: string                 // Motivo da exclusão
      }
    ],

    fileCategories: {
      sliceImages: number,             // Quantidade de imagens de slice
      sliceFiles: number,              // Quantidade de arquivos de slice
      excelFiles: number               // Quantidade de arquivos Excel
    }
  },

  // === DADOS DE AUDITORIA E RASTREAMENTO ===
  auditTrail: {
    sessionId: string,                 // ID da sessão
    userAgent: string,                 // User agent do navegador
    ipAddress: string,                 // Endereço IP (se disponível)
    formInteractions: [                // Interações com o formulário
      {
        timestamp: string,             // Timestamp da interação
        action: string,                // Tipo de ação
        field: string,                 // Campo afetado
        oldValue: any,                 // Valor anterior
        newValue: any                  // Novo valor
      }
    ],
    timeSpent: {
      totalSeconds: number,            // Tempo total gasto
      forgeSeconds: number,            // Tempo no formulário Forge
      postForgeSeconds: number         // Tempo no formulário Post-Forge
    }
  }
}
```

---

## 🔍 Detalhes Específicos por Seção

### **1. Dados do Forge - Estrutura Detalhada**

```javascript
// Estado interno do ForgeBudgetForm
const forgeFormData = {
  supportMaterial: '',                 // UUID do material de suporte
  itemsPerTable: '',                   // String convertida para number
  printHoursPerTable: 0,               // Minutos (convertidos de TimeInput)
  volumePerTable: '',                  // String convertida para number
  supportVolumePerTable: '',           // String convertida para number
  modelingHours: 0,                    // Minutos
  slicingHours: 0,                     // Minutos
  maintenanceHoursPerTable: 0,         // Minutos
  internalComments: '',                // Texto livre
  externalComments: '',                // Texto livre
  curing: {
    machine: '',                       // UUID da máquina de cura
    hours: 0,                          // Minutos
    itemsPerTable: ''                  // String convertida para number
  },
  uploadedFiles: []                    // Array de arquivos carregados
}
```

### **2. Dados do Post-Forge - Estrutura Detalhada**

```javascript
// Estado interno do PostForgeBudgetForm
const postForgeFormData = {
  finishings: [
    {
      id: 'finishing-1',               // ID único do acabamento
      name: 'Pintura Base',            // Nome do acabamento
      description: 'Aplicação de tinta base...', // Descrição
      sequence: 1,                     // Ordem de execução
      finishingType: 'Pintura',        // Tipo de acabamento
      totalDryingHours: 0,             // Horas de secagem
      materials: [
        {
          id: 'temp_1640995200000_abc123', // ID temporário ou UUID
          name: '',                    // Nome do material
          description: '',             // Descrição do material
          unitConsumption: '',         // Consumo unitário (number)
          unitCost: '',                // Custo unitário (number)
          applicationHours: '',        // Tempo de Aplicação (number)
          supplierName: '',            // Nome do fornecedor
          purchaseLink: '',            // Link de compra
          _isNew: true                 // Flag para materiais novos
        }
      ]
    }
  ]
}
```

### **3. Dados de Upload - Estrutura Detalhada**

```javascript
// Estrutura dos arquivos carregados
const uploadedFile = {
  tempId: 'upload_1640995200000_xyz789',  // ID temporário único
  onedrive_item_id: 'ABC123DEF456',       // ID do OneDrive
  fileName: 'slice_preview.png',          // Nome original do arquivo
  name: 'slice_preview.png',              // Nome do arquivo (alias)
  size: 1024000,                          // Tamanho em bytes
  type: 'image/png',                      // Tipo MIME
  budgetCategory: 'sliceImage',           // Categoria: sliceImage, slice, excel
  status: 'success',                      // Status: success, pending, error, uploading
  uploadProgress: 100,                    // Progresso do upload (0-100)
  uploadTimestamp: '2024-01-01T12:00:00Z', // Timestamp do upload
  lastModified: 1640995200000,            // Timestamp da última modificação
  webkitRelativePath: '',                 // Caminho relativo (se aplicável)

  // Metadados específicos do upload manager
  metadata: {
    componentId: 'comp-uuid-123',         // ID do componente
    orderId: 'order-uuid-456',            // ID do pedido
    version: '2',                         // Versão do componente
    uploadSessionId: 'session-789',       // ID da sessão de upload
    retryCount: 0,                        // Número de tentativas
    errorMessage: null                    // Mensagem de erro (se houver)
  }
}
```

---

## 🎯 Campos Obrigatórios vs Opcionais

### **Campos Obrigatórios**
```javascript
const requiredFields = {
  // API atual (mantidos)
  estimated_forge_days: number,         // > 0
  final_cost_per_piece: number,         // > 0
  final_price_per_piece: number,        // > 0
  estimated_prod_days: number,          // > 0

  // Contexto
  componentId: string,                  // UUID válido
  basecomponentId: string,              // UUID válido
  version: number,                      // > 0

  // Forge (se userRole === "Forge")
  'forgeData.production.itemsPerTable': number,     // > 0
  'forgeData.production.printHoursPerTable': number, // > 0
  'forgeData.production.volumePerTable': number,     // > 0

  // Cura (se material requer cura)
  'forgeData.curing.machine': string,   // UUID válido
  'forgeData.curing.hours': number,     // > 0
  'forgeData.curing.itemsPerTable': number, // > 0

  // Post-Forge (se userRole === "Post-Forge")
  'postForgeData.finishings[].materials[].dynamicFields.unitConsumption': number, // > 0
  'postForgeData.finishings[].materials[].dynamicFields.applicationHours': number, // > 0
  'postForgeData.finishings[].materials[].staticFields.name': string, // não vazio
  'postForgeData.finishings[].materials[].staticFields.unitCost': number, // > 0
  'postForgeData.finishings[].materials[].staticFields.supplierName': string // não vazio
}
```

### **Campos Opcionais**
```javascript
const optionalFields = {
  orderId: string | null,
  'forgeData.production.supportMaterial': object | null,
  'forgeData.production.supportVolumePerTable': number | null,
  'forgeData.comments.internal': string,
  'forgeData.comments.external': string,
  'forgeData.uploadedFiles': array,
  'postForgeData.finishings[].materials[].staticFields.description': string,
  'postForgeData.finishings[].materials[].staticFields.purchaseLink': string,
  // ... todos os campos de auditoria e metadados
}
```

---

## 🔄 Transformações de Dados

### **Conversões Necessárias**
```javascript
const dataTransformations = {
  // TimeInput retorna minutos, mas alguns campos podem precisar de horas
  timeFields: {
    'forgeData.production.printHoursPerTable': 'minutes', // Manter em minutos
    'forgeData.curing.hours': 'minutes',                  // Manter em minutos
    'postForgeData.finishings[].materials[].dynamicFields.applicationHours': 'hours' // Converter para horas
  },

  // Strings numéricas para números
  numericFields: [
    'forgeData.production.itemsPerTable',
    'forgeData.production.volumePerTable',
    'forgeData.production.supportVolumePerTable',
    'forgeData.curing.itemsPerTable',
    'postForgeData.finishings[].materials[].dynamicFields.unitConsumption',
    'postForgeData.finishings[].materials[].staticFields.unitCost'
  ],

  // Limpeza de strings
  stringFields: [
    'forgeData.comments.internal',
    'forgeData.comments.external',
    'postForgeData.finishings[].materials[].staticFields.name',
    'postForgeData.finishings[].materials[].staticFields.description',
    'postForgeData.finishings[].materials[].staticFields.supplierName',
    'postForgeData.finishings[].materials[].staticFields.purchaseLink'
  ]
}
```

---

## 📊 Exemplos de Payloads Reais

### **Exemplo 1: Submissão Forge Completa**
```javascript
const forgeSubmissionExample = {
  context: {
    basecomponentId: "550e8400-e29b-41d4-a716-446655440000",
    componentId: "550e8400-e29b-41d4-a716-446655440001",
    version: 2,
    orderId: "550e8400-e29b-41d4-a716-446655440002",
    userRole: "Forge",
    submissionTimestamp: "2025-01-18T14:30:00.000Z",
    formType: "forge"
  },

  forgeData: {
    production: {
      supportMaterial: {
        id: "550e8400-e29b-41d4-a716-446655440003",
        name: "PLA Support",
        costPer1g: 0.025
      },
      itemsPerTable: 12,
      printHoursPerTable: 480, // 8 horas em minutos
      volumePerTable: 150.5,
      supportVolumePerTable: 25.3,
      timeEstimates: {
        modelingHours: 120, // 2 horas em minutos
        slicingHours: 60,   // 1 hora em minutos
        maintenanceHoursPerTable: 30 // 30 minutos
      }
    },

    curing: {
      isRequired: true,
      machine: {
        id: "550e8400-e29b-41d4-a716-446655440004",
        model: "UV Chamber Pro",
        manufacturer: {
          id: "550e8400-e29b-41d4-a716-446655440005",
          name: "FormLabs"
        }
      },
      hours: 180, // 3 horas em minutos
      itemsPerTable: 12,
      autoFilledFromMachine: true
    },

    comments: {
      internal: "Peça complexa, requer atenção especial no suporte",
      external: "Acabamento premium solicitado pelo cliente"
    },

    uploadedFiles: [
      {
        tempId: "upload_1705582200000_abc123",
        oneDriveItemId: "01ABCDEF123456789",
        fileName: "slice_preview_v2.png",
        fileSize: 2048000,
        mimeType: "image/png",
        budgetCategory: "sliceImage",
        uploadTimestamp: "2025-01-18T14:25:00.000Z",
        status: "success",
        isProfileImage: true
      }
    ],

    profileImage: {
      oneDriveItemId: "01ABCDEF123456789",
      fileName: "slice_preview_v2.png",
      isUserSelected: true,
      fallbackToFirst: false
    }
  },

  budgetCalculations: {
    estimated_forge_days: 3,
    final_cost_per_piece: 15.75,
    final_price_per_piece: 22.50,
    estimated_prod_days: 5
  }
}
```

### **Exemplo 2: Submissão Post-Forge Completa**
```javascript
const postForgeSubmissionExample = {
  context: {
    basecomponentId: "550e8400-e29b-41d4-a716-446655440000",
    componentId: "550e8400-e29b-41d4-a716-446655440001",
    version: 2,
    orderId: "550e8400-e29b-41d4-a716-446655440002",
    userRole: "Post-Forge",
    submissionTimestamp: "2025-01-18T15:45:00.000Z",
    formType: "post-forge"
  },

  postForgeData: {
    finishings: [
      {
        id: "finishing-1",
        name: "Pintura Base",
        description: "Aplicação de tinta base acrílica",
        sequence: 1,
        finishingType: "Pintura",
        totalDryingHours: 4,
        materials: [
          {
            id: "temp_1705586700000_def456",
            dynamicFields: {
              unitConsumption: 2.5,
              applicationHours: 0.5 // 30 minutos convertidos para horas
            },
            staticFields: {
              name: "Tinta Acrílica Branca",
              description: "Tinta acrílica de alta qualidade",
              unitCost: 8.50,
              supplierName: "Tintas Premium Lda",
              purchaseLink: "https://example.com/tinta-acrilica"
            },
            metadata: {
              isNew: true,
              isDuplicated: false,
              originalMaterialId: null,
              createdAt: "2025-01-18T15:40:00.000Z",
              lastModified: "2025-01-18T15:42:00.000Z"
            }
          }
        ]
      },
      {
        id: "finishing-2",
        name: "Verniz Protetor",
        description: "Aplicação de verniz para proteção UV",
        sequence: 2,
        finishingType: "Proteção",
        totalDryingHours: 6,
        materials: [
          {
            id: "temp_1705586800000_ghi789",
            dynamicFields: {
              unitConsumption: 1.2,
              applicationHours: 0.25 // 15 minutos convertidos para horas
            },
            staticFields: {
              name: "Verniz UV Premium",
              description: "Verniz com proteção UV avançada",
              unitCost: 12.00,
              supplierName: "Vernizes Técnicos SA",
              purchaseLink: "https://example.com/verniz-uv"
            },
            metadata: {
              isNew: true,
              isDuplicated: false,
              originalMaterialId: null,
              createdAt: "2025-01-18T15:43:00.000Z",
              lastModified: "2025-01-18T15:44:00.000Z"
            }
          }
        ]
      }
    ]
  },

  budgetCalculations: {
    estimated_forge_days: 2,
    final_cost_per_piece: 8.25,
    final_price_per_piece: 12.50,
    estimated_prod_days: 3
  }
}
```

---

## 🔍 Validações e Regras de Negócio

### **Validações por Tipo de Usuário**
```javascript
const validationRules = {
  Forge: {
    required: [
      'forgeData.production.itemsPerTable',
      'forgeData.production.printHoursPerTable',
      'forgeData.production.volumePerTable'
    ],
    conditional: {
      // Se material requer cura
      curingRequired: [
        'forgeData.curing.machine.id',
        'forgeData.curing.hours',
        'forgeData.curing.itemsPerTable'
      ]
    }
  },

  'Post-Forge': {
    required: [
      'postForgeData.finishings[].materials[].dynamicFields.unitConsumption',
      'postForgeData.finishings[].materials[].dynamicFields.applicationHours',
      'postForgeData.finishings[].materials[].staticFields.name',
      'postForgeData.finishings[].materials[].staticFields.unitCost',
      'postForgeData.finishings[].materials[].staticFields.supplierName'
    ],
    business: {
      // Pelo menos um acabamento deve ter pelo menos um material
      minFinishingsWithMaterials: 1,
      // Consumo unitário deve ser > 0
      unitConsumptionMin: 0.001,
      // Tempo de Aplicação devem ser > 0
      applicationHoursMin: 0.001
    }
  },

  Admin: {
    // Admin pode submeter ambos os formulários
    inherits: ['Forge', 'Post-Forge']
  }
}
```

### **Regras de Transformação de Dados**
```javascript
const transformationRules = {
  // Converter strings vazias para null
  emptyStringToNull: [
    'forgeData.production.supportMaterial.id',
    'forgeData.comments.internal',
    'forgeData.comments.external',
    'postForgeData.finishings[].materials[].staticFields.description',
    'postForgeData.finishings[].materials[].staticFields.purchaseLink'
  ],

  // Converter strings numéricas para números
  stringToNumber: [
    'forgeData.production.itemsPerTable',
    'forgeData.production.volumePerTable',
    'forgeData.production.supportVolumePerTable',
    'forgeData.curing.itemsPerTable',
    'postForgeData.finishings[].totalDryingHours',
    'postForgeData.finishings[].materials[].dynamicFields.unitConsumption',
    'postForgeData.finishings[].materials[].staticFields.unitCost'
  ],

  // Converter minutos para horas (Post-Forge)
  minutesToHours: [
    'postForgeData.finishings[].materials[].dynamicFields.applicationHours'
  ],

  // Trim strings
  trimStrings: [
    'forgeData.comments.internal',
    'forgeData.comments.external',
    'postForgeData.finishings[].materials[].staticFields.name',
    'postForgeData.finishings[].materials[].staticFields.description',
    'postForgeData.finishings[].materials[].staticFields.supplierName',
    'postForgeData.finishings[].materials[].staticFields.purchaseLink'
  ]
}
```

---

## 📝 Notas de Implementação

### **Compatibilidade com API Atual**
- Os campos `estimated_forge_days`, `final_cost_per_piece`, `final_price_per_piece`, `estimated_prod_days` devem ser mantidos para compatibilidade
- O campo `uploadedFiles` deve manter a estrutura `{ onedrive_item_id, fileName, budgetCategory }`
- Os campos `internal_notes` e `client_notes` mapeiam para `forgeData.comments.internal` e `forgeData.comments.external`

### **Persistência Local**
- Dados do Forge: `localStorage` com chave `component_budget_${basecomponentId}_v${version}`
- Dados do Post-Forge: `localStorage` com chave `postforge_budget_${basecomponentId}_v${version}`
- Upload Manager: `localStorage` com chave gerada dinamicamente pelo upload manager

### **Gestão de Estado**
- Estado é gerenciado separadamente por cada formulário (Forge/Post-Forge)
- Mudanças são persistidas automaticamente no `localStorage`
- Validação ocorre em tempo real com feedback visual
- Submissão só é permitida após validação completa

---

## 🎯 Conclusão

Este mapeamento detalhado cobre **todos** os dados coletados na página de orçamentação de componentes 3D. A estrutura é:

- **Hierárquica**: Organizada em seções lógicas
- **Tipada**: Cada campo tem seu tipo de dados especificado
- **Validada**: Inclui regras de validação e transformação
- **Auditável**: Inclui metadados para rastreamento
- **Compatível**: Mantém compatibilidade com a API atual
- **Extensível**: Permite futuras expansões sem quebrar a estrutura

A nova API de submissão deve aceitar esta estrutura completa e processar adequadamente cada seção conforme o papel do usuário e os dados fornecidos.
