# 📋 **Padrões das APIs do Sistema M3 Nexus**

> **Documentação Completa dos Padrões Estabelecidos**  
> Baseada na análise profunda de todas as APIs existentes no sistema  
> **Autor:** Thúlio Silva  

---

## 🎯 **Visão Geral**

Este documento define os padrões obrigatórios para todas as APIs do sistema M3 Nexus, garantindo consistência, manutenibilidade e qualidade do código. Todos os novos endpoints devem seguir rigorosamente estes padrões.

---

## 📦 **1. Estrutura de Importações**

### **Padrão Obrigatório:**
```javascript
// Import necessary modules
import pool from "@/lib/db"; // Database connection pool
import { allowCors } from "@/lib/cors"; // CORS middleware
import { getAuthenticatedUserId } from "@/lib/userAuth"; // Authentication function

// Importações específicas conforme necessário:
import jwt from "jsonwebtoken"; // Para APIs de autenticação
import cookie from "cookie"; // Para manipulação de cookies
import { getNewAccessToken } from "@/lib/onedriveAuth"; // Para APIs OneDrive
import { 
    deleteFileFromOneDrive,
    moveOneDriveItem,
    ensureFolderPath,
    sanitizeFilename 
} from "@/lib/graphClient"; // Para operações OneDrive
```

### **❌ Não Usar:**
- Configuração manual do Pool PostgreSQL
- Importação direta de `{ Pool } from 'pg'`
- Configurações de base de dados inline

---

## 🔐 **2. Estrutura de Autenticação**

### **Padrão para APIs que Requerem Autenticação:**
```javascript
async function handler(req, res) {
  // Get database connection (se necessário)
  const client_pg = await pool.connect();
  console.log(`🔌 Database connection established`);

  try {
    // === Authentication ===
    console.log(`🔐 Starting authentication`);
    const userId = await getAuthenticatedUserId(req);
    
    if (!userId) {
      console.error(`❌ Authentication failed`);
      return res.status(401).json({ 
        success: false, 
        error: "Authentication required: No token provided."
      });
    }

    console.log(`✅ Authentication successful for user: ${userId}`);
    
    // Resto da lógica...
  } catch (error) {
    // Error handling...
  } finally {
    // Resource cleanup...
  }
}
```

### **APIs Especiais (session.js, loginDB.js):**
- Podem usar estruturas de resposta diferentes
- Mantêm padrões específicos de autenticação
- Usam campos como `valid`, `code`, etc.

---

## 🌐 **3. Validação de Método HTTP**

### **Padrão Obrigatório:**
```javascript
// Only allow [METHOD] requests
if (req.method !== 'GET') { // ou POST, DELETE, etc.
  console.error(`❌ Method ${req.method} not allowed`);
  return res.status(405).json({ 
    success: false, 
    message: 'Método não permitido. Use GET.' // Adaptar conforme método
  });
}
```

### **Para APIs de Upload/Delete:**
```javascript
if (req.method !== "POST") {
    res.setHeader("Allow", ["POST"]);
    return res.status(405).json({ 
        success: false, 
        message: "Method Not Allowed" 
    });
}
```

---

## ✅ **4. Validação de Parâmetros**

### **Validação de Parâmetros Obrigatórios:**
```javascript
// === Parameter Validation ===
const { componentId, orderId } = req.query; // ou req.body para POST

if (!componentId) {
  console.error('❌ Missing componentId parameter');
  return res.status(400).json({ 
    success: false, 
    message: 'Parâmetro componentId é obrigatório.'
  });
}
```

### **Validação de UUID:**
```javascript
// Validate UUID format using consistent regex pattern
const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
if (!uuidRegex.test(componentId)) {
  console.error(`❌ Invalid UUID format for componentId: ${componentId}`);
  return res.status(400).json({ 
    success: false, 
    message: 'Formato de componentId inválido.'
  });
}
```

---

## 📊 **5. Estrutura de Resposta**

### **Resposta de Sucesso:**
```javascript
// Para APIs GET (dados)
return res.status(200).json({
  success: true,
  data: responseData
});

// Para APIs POST/PUT (ações)
return res.status(200).json({
  success: true,
  message: "Operação realizada com sucesso."
});
```

### **Resposta de Erro:**
```javascript
// Erro de validação (400)
return res.status(400).json({ 
  success: false, 
  message: 'Parâmetro obrigatório em falta.'
});

// Erro de autenticação (401)
return res.status(401).json({ 
  success: false, 
  error: "Authentication required: No token provided."
});

// Erro não encontrado (404)
return res.status(404).json({ 
  success: false, 
  error: 'Recurso não encontrado.'
});

// Erro interno (500)
return res.status(500).json({
  success: false, 
  error: "Internal server error while processing request."
});
```

### **❌ Não Usar:**
- Campos `meta`, `error_code`, `timestamp`
- Estruturas complexas de erro
- Códigos de erro estruturados

---

## 🗄️ **6. Gestão de Base de Dados**

### **Conexão Padrão:**
```javascript
// Get database connection
const client_pg = await pool.connect();
console.log(`🔌 Database connection established`);

try {
  // Database operations...
  
} catch (error) {
  // Error handling...
} finally {
  // === Resource Cleanup ===
  if (client_pg) {
    console.log(`🔌 Releasing database connection`);
    client_pg.release();
  }
}
```

### **Para Transações:**
```javascript
try {
  client_pg = await pool.connect();
  await client_pg.query('BEGIN');
  
  // Database operations...
  
  await client_pg.query('COMMIT');
} catch (error) {
  if (client_pg) {
    try { 
      await client_pg.query('ROLLBACK'); 
    } catch (rbError) { 
      console.error("❌ Failed to rollback transaction:", rbError); 
    }
  }
  // Error handling...
} finally {
  if (client_pg) {
    client_pg.release();
  }
}
```

---

## 📝 **7. Padrões de Logging**

### **Logging Padrão:**
```javascript
// Início da API
console.log(`🚀 Starting [api-name] API request`);

// Autenticação
console.log(`🔐 Starting authentication`);
console.log(`✅ Authentication successful for user: ${userId}`);

// Operações de base de dados
console.log(`🔌 Database connection established`);
console.log(`🔍 Fetching data for: ${parameter}`);
console.log(`📊 Found ${results.length} records`);

// Sucesso
console.log(`✅ Successfully processed request`);

// Erros
console.error(`❌ Error in /api/[api-name]:`, error);
console.error(`❌ Error stack:`, error.stack);

// Cleanup
console.log(`🔌 Releasing database connection`);
console.log(`🏁 [api-name] API request completed`);
```

### **❌ Não Usar:**
- Tracking de performance detalhado
- Logs excessivamente verbosos
- Timestamps manuais nos logs

---

## 🚨 **8. Tratamento de Erros**

### **Estrutura Padrão:**
```javascript
} catch (error) {
  console.error(`❌ Error in /api/[api-name]:`, error);
  console.error(`❌ Error stack:`, error.stack);

  // Return generic error response
  return res.status(500).json({
    success: false, 
    error: "Internal server error while processing request."
  });
}
```

### **Para APIs Específicas (submit, upload, etc.):**
```javascript
} catch (error) {
  console.error("❌ Unexpected error in /api/[api-name]:", error);
  return res.status(500).json({
    success: false,
    message: "Internal Server Error while processing request.",
    details: error.message // Opcional para debugging
  });
}
```

---

## 🔄 **9. Exportação e CORS**

### **Padrão Obrigatório:**
```javascript
// Export the handler with CORS protection
export default allowCors(handler);
```

---

## 📋 **10. Documentação de API**

### **Cabeçalho Obrigatório:**
```javascript
/**
 * API endpoint to [descrição da funcionalidade]
 * 
 * This endpoint [descrição detalhada do que faz].
 * Requires authentication via JWT token in cookies.
 * 
 * Method: GET/POST/DELETE
 * Route: /api/[nome-da-api]
 * 
 * Query Parameters: (para GET)
 * - param1: Required/Optional [tipo] - Descrição
 * 
 * Body Parameters: (para POST)
 * - param1: Required/Optional [tipo] - Descrição
 * 
 * Response format:
 * {
 *   success: true,
 *   data: { ... }
 * }
 * 
 * Error Response:
 * {
 *   success: false,
 *   error: "Error description"
 * }
 */
```

---

## 🎯 **11. Categorias de APIs**

### **APIs GET (Consulta):**
- Estrutura: `get-[recurso]-[ação].js`
- Resposta: `{ success: true, data: ... }`
- Autenticação: Obrigatória (exceto status)

### **APIs POST (Submissão):**
- Estrutura: `submit-[ação].js` ou `create-[recurso].js`
- Resposta: `{ success: true, message: ... }`
- Validação: Rigorosa de parâmetros

### **APIs DELETE:**
- Estrutura: `delete-[recurso].js`
- Resposta: `{ success: true, message: ... }`
- Transações: Obrigatórias

### **APIs de Status:**
- Estrutura: `[sistema]-status.js`
- Resposta: `{ status: "online/offline", ... }`
- Autenticação: Não obrigatória

### **APIs de Autenticação:**
- Estrutura específica mantida
- Respostas: Formatos especiais permitidos

---

## ⚠️ **12. Regras Importantes**

### **✅ Sempre Fazer:**
1. Usar pool de conexão centralizado
2. Implementar cleanup de recursos
3. Validar todos os parâmetros
4. Usar logging com emojis
5. Seguir estrutura de resposta padrão
6. Implementar autenticação quando necessário

### **❌ Nunca Fazer:**
1. Configurar pool de base de dados manualmente
2. Usar estruturas de resposta complexas
3. Implementar tracking de performance
4. Usar códigos de erro estruturados
5. Omitir validação de parâmetros
6. Esquecer cleanup de recursos

---

## 🔍 **13. Exemplos de Referência**

### **APIs Bem Implementadas:**
- `get-orders-list.js` - Padrão GET com autenticação
- `submit-new-order.js` - Padrão POST com transações
- `delete-file.js` - Padrão DELETE com cleanup
- `session.js` - API especial de autenticação
- `db-status.js` - API de status sem autenticação

### **Usar Como Referência:**
Sempre consulte estas APIs como modelo para implementar novos endpoints seguindo os padrões estabelecidos.

---

---

## 🔧 **14. Padrões Específicos por Tipo de Operação**

### **APIs de Upload de Arquivos:**
```javascript
// Estrutura para create-[tipo]-upload-session.js
async function handler(req, res) {
    if (req.method !== "POST") {
        res.setHeader("Allow", ["POST"]);
        return res.status(405).json({
            success: false,
            message: "Method Not Allowed"
        });
    }

    try {
        // Authentication
        const userId = await getAuthenticatedUserId(req);
        if (!userId) {
            return res.status(401).json({
                success: false,
                message: "Not authenticated."
            });
        }

        // Extract parameters
        const { fileName, fileSize } = req.body;

        // Validation
        if (!fileName || !fileSize) {
            return res.status(400).json({
                success: false,
                message: "fileName and fileSize are required."
            });
        }

        // OneDrive operations...

        return res.status(200).json({
            success: true,
            uploadUrl: uploadUrl,
            expirationDateTime: expirationDateTime,
            // Outros campos específicos...
        });

    } catch (error) {
        console.error("❌ Error creating upload session:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to create upload session."
        });
    }
}
```

### **APIs de Finalização de Upload:**
```javascript
// Estrutura para finalize-[tipo]-upload.js
async function handler(req, res) {
    if (req.method !== "POST") {
        res.setHeader("Allow", ["POST"]);
        return res.status(405).json({
            success: false,
            message: "Method Not Allowed"
        });
    }

    let client_pg = null;

    try {
        // Authentication
        const userId = await getAuthenticatedUserId(req);
        if (!userId) {
            return res.status(401).json({
                success: false,
                message: "Not authenticated."
            });
        }

        client_pg = await pool.connect();
        await client_pg.query('BEGIN');

        // Database operations...

        await client_pg.query('COMMIT');

        return res.status(200).json({
            success: true,
            message: "Upload finalized successfully."
        });

    } catch (error) {
        if (client_pg) {
            try {
                await client_pg.query('ROLLBACK');
            } catch (rbError) {
                console.error("❌ Failed to rollback:", rbError);
            }
        }

        console.error("❌ Error finalizing upload:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to finalize upload."
        });
    } finally {
        if (client_pg) {
            client_pg.release();
        }
    }
}
```

### **APIs de Download/Links:**
```javascript
// Estrutura para get-[tipo]-download-link/[id].js
async function handler(req, res) {
    if (req.method !== 'GET') {
        console.error(`❌ Method ${req.method} not allowed`);
        return res.status(405).json({
            success: false,
            message: 'Método não permitido. Use GET.'
        });
    }

    try {
        // Authentication
        const userId = await getAuthenticatedUserId(req);
        if (!userId) {
            return res.status(401).json({
                success: false,
                error: "Authentication required: No token provided."
            });
        }

        // Extract ID from URL
        const { id } = req.query;

        // Validation
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        if (!id || !uuidRegex.test(id)) {
            return res.status(400).json({
                success: false,
                error: "Invalid or missing ID parameter."
            });
        }

        // Generate download link...

        return res.status(200).json({
            success: true,
            data: {
                downloadUrl: downloadUrl,
                expiresAt: expirationTime
            }
        });

    } catch (error) {
        console.error(`❌ Error generating download link:`, error);
        return res.status(500).json({
            success: false,
            error: "Internal server error while generating download link."
        });
    }
}
```

---

## 🌍 **15. Padrões de Internacionalização**

### **Mensagens de Erro:**
```javascript
// Autenticação: SEMPRE em inglês
error: "Authentication required: No token provided."
error: "Authentication failed: Invalid or expired token."

// Validação: SEMPRE em português
message: 'Parâmetro componentId é obrigatório.'
message: 'Formato de UUID inválido.'

// Erros internos: SEMPRE em inglês
error: "Internal server error while processing request."
error: "Database connection failed."
```

### **APIs com Suporte a Idioma:**
```javascript
// Para APIs como getneworder.js que suportam múltiplos idiomas
const language = req.query.language || 'en';

return res.status(400).json({
    success: false,
    error: language === 'pt' ?
        "Recurso não especificado ou inválido" :
        "Resource not specified or invalid"
});
```

---

## 🔒 **16. Padrões de Segurança**

### **Validação de Entrada:**
```javascript
// Sempre validar tipos de dados
if (!componentFileId || typeof componentFileId !== 'string') {
    return res.status(400).json({
        success: false,
        message: "Invalid or missing componentFileId."
    });
}

// Sanitização de nomes de arquivo
const sanitizedFileName = sanitizeFilename(fileName);

// Validação de tamanho de arquivo
if (fileSize > MAX_FILE_SIZE) {
    return res.status(400).json({
        success: false,
        message: "File size exceeds maximum allowed."
    });
}
```

### **Proteção contra Ataques:**
```javascript
// Rate limiting implícito através de autenticação
// Validação rigorosa de UUIDs
// Sanitização de inputs
// Uso de prepared statements (automático com pool.query)
```

---

## 📈 **17. Padrões de Performance**

### **Queries Otimizadas:**
```javascript
// Use JOINs eficientes
const query = `
    SELECT
        c.id,
        c.title,
        m.model as machine_model,
        mm.name as machine_manufacturer_name
    FROM "Component" c
    LEFT JOIN "Machine" m ON c.machine_id = m.id
    LEFT JOIN "MachineManufacturer" mm ON m.machinemanufacturer_id = mm.id
    WHERE c.id = $1;
`;

// Use LIMIT quando apropriado
const query = `
    SELECT * FROM "Order"
    ORDER BY created_at DESC
    LIMIT 100;
`;
```

### **Gestão de Conexões:**
```javascript
// SEMPRE usar o pool centralizado
const client_pg = await pool.connect();

// SEMPRE fazer cleanup
finally {
    if (client_pg) {
        client_pg.release();
    }
}
```

---

## 🧪 **18. Padrões de Testing**

### **Estrutura para Testes:**
```javascript
// Teste de método HTTP
// Teste de autenticação
// Teste de validação de parâmetros
// Teste de operações de base de dados
// Teste de tratamento de erros
// Teste de cleanup de recursos
```

### **Casos de Teste Obrigatórios:**
1. Método HTTP inválido (405)
2. Sem autenticação (401)
3. Parâmetros em falta (400)
4. UUID inválido (400)
5. Recurso não encontrado (404)
6. Erro de base de dados (500)
7. Sucesso (200)

---

## 📚 **19. Documentação de Funções Helper**

### **Funções Reutilizáveis:**
```javascript
/**
 * Helper function to validate component access
 * @param {Object} client_pg - Database client connection
 * @param {string} componentId - UUID of the component
 * @param {string} userId - UUID of the user
 * @returns {Object} Validation result with component details
 */
async function validateComponentAccess(client_pg, componentId, userId) {
    // Implementation...
}

/**
 * Helper function to generate OneDrive folder path
 * @param {string} clientName - Name of the client
 * @param {string} orderTitle - Title of the order
 * @param {string} componentTitle - Title of the component
 * @returns {string} Sanitized folder path
 */
function generateFolderPath(clientName, orderTitle, componentTitle) {
    // Implementation...
}
```

---

## 🔄 **20. Padrões de Versionamento**

### **Estrutura de Versões:**
- APIs estáveis: Manter compatibilidade
- Mudanças breaking: Documentar claramente
- Deprecação: Processo gradual com avisos

### **Changelog de APIs:**
- Documentar todas as mudanças
- Manter histórico de versões
- Comunicar mudanças à equipe

---

---

## ✅ **21. Checklist de Desenvolvimento**

### **Antes de Criar uma Nova API:**
- [ ] Consultar este documento de padrões
- [ ] Verificar se funcionalidade similar já existe
- [ ] Definir estrutura de parâmetros e resposta
- [ ] Planejar validações necessárias
- [ ] Identificar dependências (OneDrive, base de dados, etc.)

### **Durante o Desenvolvimento:**
- [ ] Seguir estrutura de importações padrão
- [ ] Implementar validação de método HTTP
- [ ] Implementar autenticação (se necessário)
- [ ] Validar todos os parâmetros obrigatórios
- [ ] Usar pool de conexão centralizado
- [ ] Implementar logging com emojis
- [ ] Seguir estrutura de resposta padrão
- [ ] Implementar tratamento de erros
- [ ] Garantir cleanup de recursos

### **Antes de Fazer Deploy:**
- [ ] Testar todos os cenários (sucesso e erro)
- [ ] Verificar logs no console
- [ ] Validar estrutura de resposta
- [ ] Testar autenticação
- [ ] Verificar cleanup de recursos
- [ ] Documentar parâmetros e resposta
- [ ] Adicionar comentários explicativos

---

## 🎯 **22. Exemplo Completo de API**

### **Template Completo para Nova API GET:**
```javascript
// Import necessary modules
import pool from "@/lib/db"; // Database connection pool
import { allowCors } from "@/lib/cors"; // CORS middleware
import { getAuthenticatedUserId } from "@/lib/userAuth"; // Authentication function

/**
 * API endpoint to fetch [descrição da funcionalidade]
 *
 * This endpoint retrieves [descrição detalhada].
 * Requires authentication via JWT token in cookies.
 *
 * Method: GET
 * Route: /api/get-[nome-recurso]
 *
 * Query Parameters:
 * - resourceId: Required UUID of the resource to fetch
 * - optionalParam: Optional string parameter
 *
 * Response format:
 * {
 *   success: true,
 *   data: {
 *     resource: { ... },
 *     additionalData: [ ... ]
 *   }
 * }
 *
 * Error Response:
 * {
 *   success: false,
 *   error: "Error description"
 * }
 */

/**
 * Helper function to fetch resource details
 * @param {Object} client_pg - Database client connection
 * @param {string} resourceId - UUID of the resource to fetch
 * @returns {Object|null} Resource details or null if not found
 */
async function getResourceDetails(client_pg, resourceId) {
  console.log(`🔍 Fetching resource details for: ${resourceId}`);

  const query = `
    SELECT
      r.id,
      r.title,
      r.description,
      r.created_at
    FROM "Resource" r
    WHERE r.id = $1;
  `;

  const result = await client_pg.query(query, [resourceId]);
  const resource = result.rows[0] || null;

  if (resource) {
    console.log(`✅ Resource found: ${resource.title}`);
  } else {
    console.log(`⚠ Resource not found: ${resourceId}`);
  }

  return resource;
}

/**
 * Main API handler function
 */
async function handler(req, res) {
  console.log(`🚀 Starting get-resource API request`);

  // Only allow GET requests
  if (req.method !== 'GET') {
    console.error(`❌ Method ${req.method} not allowed`);
    return res.status(405).json({
      success: false,
      message: 'Método não permitido. Use GET.'
    });
  }

  // Get database connection
  const client_pg = await pool.connect();
  console.log(`🔌 Database connection established`);

  try {
    // === Authentication ===
    console.log(`🔐 Starting authentication`);
    const userId = await getAuthenticatedUserId(req);

    if (!userId) {
      console.error(`❌ Authentication failed`);
      return res.status(401).json({
        success: false,
        error: "Authentication required: No token provided."
      });
    }

    console.log(`✅ Authentication successful for user: ${userId}`);

    // === Parameter Validation ===
    const { resourceId, optionalParam } = req.query;

    if (!resourceId) {
      console.error('❌ Missing resourceId parameter');
      return res.status(400).json({
        success: false,
        message: 'Parâmetro resourceId é obrigatório.'
      });
    }

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(resourceId)) {
      console.error(`❌ Invalid UUID format for resourceId: ${resourceId}`);
      return res.status(400).json({
        success: false,
        message: 'Formato de resourceId inválido.'
      });
    }

    console.log(`🔍 Fetching data for resource: ${resourceId}`);

    // === Data Fetching ===
    const resource = await getResourceDetails(client_pg, resourceId);

    if (!resource) {
      return res.status(404).json({
        success: false,
        error: 'Recurso não encontrado.'
      });
    }

    // === Data Processing ===
    console.log(`🔄 Processing response data...`);
    const responseData = {
      resource: {
        id: resource.id,
        title: resource.title,
        description: resource.description,
        created_at: resource.created_at
      },
      additionalData: [] // Adicionar dados conforme necessário
    };

    console.log(`✅ Successfully fetched resource data`);

    // Return successful response
    return res.status(200).json({
      success: true,
      data: responseData
    });

  } catch (error) {
    console.error(`❌ Error in /api/get-resource:`, error);
    console.error(`❌ Error stack:`, error.stack);

    // Return generic error response
    return res.status(500).json({
      success: false,
      error: "Internal server error while fetching resource data."
    });

  } finally {
    // === Resource Cleanup ===
    if (client_pg) {
      console.log(`🔌 Releasing database connection`);
      client_pg.release();
    }

    console.log(`🏁 get-resource API request completed`);
  }
}

// Export the handler with CORS protection
export default allowCors(handler);
```

---

## 📋 **23. Troubleshooting Comum**

### **Problemas Frequentes:**

**1. Erro de Conexão de Base de Dados:**
```javascript
// ❌ Problema: Configuração manual do pool
const pool = new Pool({ ... });

// ✅ Solução: Usar pool centralizado
import pool from "@/lib/db";
```

**2. Estrutura de Resposta Inconsistente:**
```javascript
// ❌ Problema: Estrutura complexa
return res.json({
  success: true,
  data: result,
  meta: { timestamp: new Date() }
});

// ✅ Solução: Estrutura simples
return res.status(200).json({
  success: true,
  data: result
});
```

**3. Autenticação Inconsistente:**
```javascript
// ❌ Problema: Mensagem em português
return res.status(401).json({
  success: false,
  message: "Não autenticado"
});

// ✅ Solução: Mensagem padrão em inglês
return res.status(401).json({
  success: false,
  error: "Authentication required: No token provided."
});
```

**4. Falta de Cleanup de Recursos:**
```javascript
// ❌ Problema: Sem finally block
try {
  const client_pg = await pool.connect();
  // operations...
} catch (error) {
  // error handling...
}

// ✅ Solução: Sempre usar finally
try {
  const client_pg = await pool.connect();
  // operations...
} catch (error) {
  // error handling...
} finally {
  if (client_pg) {
    client_pg.release();
  }
}
```

---

## 🚀 **24. Próximos Passos**

### **Para Desenvolvedores:**
1. Estudar este documento completamente
2. Revisar APIs existentes como referência
3. Usar template fornecido para novas APIs
4. Seguir checklist de desenvolvimento
5. Solicitar revisão antes do deploy

### **Para Manutenção:**
1. Revisar APIs existentes periodicamente
2. Atualizar padrões conforme necessário
3. Manter documentação atualizada
4. Treinar novos desenvolvedores

---

**📌 Nota Final:** Este documento é a fonte única da verdade para padrões de APIs no sistema M3 Nexus. Deve ser consultado antes de criar qualquer nova API e atualizado sempre que novos padrões forem estabelecidos. Desvios só são permitidos em casos excepcionais e devem ser documentados e aprovados pela equipe técnica.
