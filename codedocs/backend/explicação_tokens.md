## **1. Conceitos Básicos de Autenticação**

### **O que são JWT Tokens?**
JWT (JSON Web Token) é como um "passe de entrada" digital que prova que você é quem diz ser. Imagine como um cartão de identificação que contém:
- Seu ID de usuário
- Seu papel (Admin, Agent, etc.)
- Quando expira
- Uma "assinatura" digital que prova que é válido

### **Por que usamos 2 tokens diferentes?**

**Access Token (Token de Acesso)**
- **Duração**: 15 minutos apenas
- **Propósito**: Usado para fazer pedidos à API
- **Onde fica**: No `sessionStorage` do navegador
- **Analogia**: Como um bilhete de entrada temporário para um evento

**Refresh Token (Token de Renovação)**
- **Duração**: 7 dias
- **Propósito**: Usado para obter novos access tokens
- **Onde fica**: No `sessionStorage` + Base de dados
- **Analogia**: Como um passe VIP que te permite renovar o bilhete temporário

## **2. Como Funciona o Login**

### **Passo a Passo do Login:**

1. **Usuário insere credenciais** (email/password)
2. **Backend verifica** se as credenciais são válidas
3. **Se válidas**, o backend:
   - Gera um **fingerprint** único (segurança extra)
   - Cria um **access token** (15 min)
   - Cria um **refresh token** (7 dias)
   - Guarda o refresh token na base de dados
   - Envia cookies seguros com o fingerprint
4. **Frontend recebe** os tokens e:
   - Guarda no `sessionStorage`
   - Programa renovação automática
   - Redireciona para a área do usuário

### **Como os Tokens são Criados:**

```javascript
// Access Token contém:
{
  id: "123",
  email: "usuario@exemplo.com",
  role: "Admin",
  fingerprint: "hash_do_fingerprint",
  type: "access",
  exp: 1234567890, // expira em 15 minutos
}

// Refresh Token contém:
{
  id: "123",
  email: "usuario@exemplo.com", 
  tokenId: "token_unico_gerado",
  fingerprint: "hash_do_fingerprint",
  type: "refresh",
  exp: 1234567890, // expira em 7 dias
}
```

## **3. Segurança Avançada: O Sistema de Fingerprint**

### **O que é o Fingerprint?**
É um "código secreto" adicional que:
- É gerado aleatoriamente a cada login
- É guardado como cookie `HttpOnly` (não acessível por JavaScript)
- É incluído em ambos os tokens como hash
- Previne ataques de "roubo de tokens"

### **Como funciona:**
1. **Login**: Fingerprint é gerado e enviado como cookie seguro
2. **Requests**: Servidor verifica se o fingerprint do cookie coincide com o do token
3. **Se não coincidir**: Todos os tokens são invalidados (medida de segurança)

## **4. Renovação Automática de Tokens**

### **Quando acontece:**
- Quando o access token tem menos de 5 segundos para expirar (notificação)
- Automaticamente antes de operações críticas (uploads, etc.)
- Em segundo plano sem interromper o usuário
- **PROTEÇÃO ESPECIAL**: Antes de finalizar uploads longos

### **Como funciona:**
1. **TokenManager detecta** que o token vai expirar
2. **Chama** `/api/refresh-token` com o refresh token
3. **Backend verifica**:
   - Se o refresh token é válido
   - Se o fingerprint coincide
   - Se o token existe na base de dados
4. **Se tudo OK**:
   - Cria novos tokens (access + refresh)
   - Invalida os antigos
   - Atualiza a base de dados
   - Envia novos cookies

### **Rotação de Tokens:**
- A cada renovação, **ambos** os tokens são substituídos
- Isso significa que tokens antigos ficam inválidos
- Aumenta a segurança contra ataques

## **5. Gestão de Sessões no Frontend**

### **SessionContext:**
Este é o "cérebro" da gestão de sessão:
- **Monitora** se o usuário está logado
- **Protege rotas** baseado no papel do usuário
- **Coordena** login/logout
- **Gere** estados de carregamento

### **TokenManager:**
É o "guardião" dos tokens:
- **Armazena** tokens de forma segura
- **Programa** renovações automáticas
- **Sincroniza** entre abas do navegador
- **Gere** erros de token

## **6. Proteção de Rotas**

### **Como funciona:**
1. **Usuário visita** uma página
2. **SessionContext verifica**:
   - Se tem tokens válidos
   - Se o papel permite acesso àquela rota
3. **Se não permitir**:
   - Redireciona para área correta
   - Ou para login se não autenticado

### **Exemplo prático:**
```javascript
// Admin pode acessar:
"/admin/*", "/agent/*", "/"

// Agent pode acessar apenas:
"/agent/*", "/"

// Se Admin tentar ir para /forge:
// → Redirecionado para /admin/orderslist
```

## **7. Processo de Logout**

### **O que acontece:**
1. **Usuário clica** logout
2. **Frontend chama** `/api/logout`
3. **Backend**:
   - Invalida todos os refresh tokens do usuário
   - Limpa cookies de fingerprint
4. **Frontend**:
   - Limpa tokens do sessionStorage
   - Notifica outras abas para fazer logout
   - Redireciona para página de login

## **8. Sincronização Entre Abas**

### **Problema:**
Se usuário tem aplicação aberta em várias abas, como manter sincronizado?

### **Solução:**
- **Eventos localStorage**: Quando uma aba faz logout, notifica outras
- **Renovação sincronizada**: Quando tokens são renovados, outras abas são atualizadas
- **Sessão partilhada**: SessionStorage é sincronizado entre abas

## **9. Tratamento de Erros**

### **Tipos de erro e como são tratados:**

**Token Expirado:**
- Tentativa automática de renovação
- Se falhar, pede login novamente

**Fingerprint Inválido:**
- Limpa todos os tokens imediatamente
- Força logout (medida de segurança)

**Servidor Indisponível:**
- Mantém sessão local
- Mostra aviso ao usuário
- Tenta reconectar

## **10. Base de Dados: Tabela RefreshTokens**

### **Estrutura:**
```sql
RefreshTokens {
  user_id: ID do usuário
  token_hash: Hash do token (não o token real)
  fingerprint_hash: Hash do fingerprint
  expires_at: Quando expira
  is_active: Se está ativo
  created_at: Quando foi criado
  last_used_at: Última vez usado
}
```

### **Constraint de Segurança:**
- **Apenas um token ativo por usuário**
- Tokens inativos são mantidos para auditoria
- Constraint especial permite múltiplos inativos

## **11. Medidas de Segurança Implementadas**

1. **Cookies HttpOnly**: Fingerprint não acessível por JavaScript
2. **Hashing**: Tokens são guardados como hash na BD
3. **Rotação**: Tokens são substituídos a cada renovação
4. **Expiração curta**: Access tokens só duram 15 minutos
5. **Invalidação em caso de suspeita**: Todos os tokens são limpos se detetado problema
6. **Sincronização multi-aba**: Logout em uma aba afeta todas
7. **🆕 Proteção Upload Longos**: Renovação automática antes de finalizações

## **12. Vantagens deste Sistema**

✅ **Segurança alta**: Múltiplas camadas de proteção
✅ **Experiência suave**: Renovação automática invisível
✅ **Controle granular**: Podemos invalidar sessões específicas
✅ **Auditoria**: Histórico de tokens na base de dados
✅ **Resistente a ataques**: Fingerprint previne roubo de tokens

Este sistema implementa as melhores práticas de segurança para autenticação web moderna, fornecendo um equilíbrio entre segurança robusta e experiência de usuário fluida!

## **13. 🆕 Proteção para Uploads Longos**

### **Problema Identificado:**
Em uploads grandes (arquivos 3D que podem demorar 5+ minutos), existe o risco do token expirar durante o upload, causando falha na finalização.

### **Solução Implementada:**

**🔍 Detecção Automática:**
- Sistema identifica automaticamente chamadas para APIs de finalização
- Endpoints protegidos: `/finalize-onedrive-upload`, `/finalize-budget-upload`, `/submit-component-budget`

**🔄 Renovação Preventiva:**
- Antes de cada finalização, verifica se token expira nos próximos 60 segundos
- Se sim, renova automaticamente de forma silenciosa
- Só procede com finalização se token estiver válido

**📊 Fluxo Protegido:**
```
1. Usuário inicia upload (token válido)
2. Upload para OneDrive (direto, sem nosso token)
3. Antes de finalizar: Verifica token
4. Se necessário: Renova automaticamente
5. Finaliza upload (token garantidamente válido)
```

### **Benefícios:**
✅ **Uploads nunca falham por token expirado**
✅ **Processo invisível ao usuário**
✅ **Funciona para todos os tipos de upload**
✅ **Mantém segurança do sistema**

### **Configuração:**
- **Buffer de segurança**: 60 segundos antes da expiração
- **Renovação silenciosa**: Sem interromper o upload
- **Fallback**: Se renovação falhar, mostra erro claro ao usuário

### **🆕 Suspensão de Notificações Durante Uploads:**

**Detecção Inteligente:**
- Sistema detecta quando upload está ativo
- Suspende automaticamente notificações de expiração
- Resume notificações após upload completo

**Gestão de Estado:**
- `registerActiveUpload(uploadId)`: Registra início do upload
- `unregisterActiveUpload(uploadId)`: Marca fim do upload
- `suspendNotifications()`: Bloqueia notificações
- `resumeNotifications()`: Reativa após uploads

**Cenário Completo Protegido:**
```
00:00 - Inicia upload (registra no sistema)
00:05 - Token deveria expirar → Notificação SUSPENSA
00:20 - Upload completo → Desregistra upload
00:20 - Sistema resume notificações normais
```

### **🔧 Correções Técnicas Importantes:**

**Problema Resolvido - Headers XMLHttpRequest:**
- **Issue**: Header `Content-Length` manual causava erro 400 no OneDrive
- **Causa**: Navegadores modernos rejeitam definição manual por segurança
- **Solução**: Removido `xhr.setRequestHeader('Content-Length', ...)` 
- **Resultado**: Navegador define automaticamente o valor correto

**Problema Crítico - Limitações OneDrive API:**
- **Issue**: Uploads >4MB falhavam com 400 Bad Request mesmo após correção de headers
- **Root Cause**: OneDrive API **requer** upload fragmentado para arquivos >4MB
- **Limitações descobertas**:
  - **Single PUT**: Máximo 4MB apenas
  - **Arquivos grandes**: DEVEM usar upload session + fragmentos
  - **Tamanho fragmento**: Múltiplos de 320 KiB (recomendado 10MB)

**✅ Solução Implementada - Upload Fragmentado:**
```javascript
// Sistema detecta automaticamente tamanho do arquivo
if (fileSize < 4 * 1024 * 1024) {
  // Arquivos <4MB: Single PUT (método original)
  return await uploadSingleChunk(uploadUrl, file, 0, fileSize, fileSize);
} else {
  // Arquivos ≥4MB: Upload fragmentado (10MB chunks)
  while (currentByte < fileSize) {
    const nextByte = Math.min(currentByte + chunkSize, fileSize);
    const chunk = file.slice(currentByte, nextByte);
    await uploadSingleChunk(uploadUrl, chunk, currentByte, nextByte - 1, fileSize);
    currentByte = nextByte;
  }
}
```

**Headers Corretos para Upload OneDrive:**
```javascript
// ❌ ERRO - Causa 400 Bad Request
xhr.setRequestHeader('Content-Length', file.size.toString());

// ✅ CORRETO - Upload fragmentado
xhr.setRequestHeader('Content-Range', `bytes ${startByte}-${endByte}/${totalSize}`);
xhr.setRequestHeader('Content-Type', 'application/octet-stream');

// Status codes esperados:
// 202 Accepted - Fragmento intermediário recebido
// 200/201 Created - Upload final completo
```

**Benefícios da Implementação:**
✅ **Uploads ilimitados**: Arquivos de qualquer tamanho (testado até 1GB+)
✅ **Compatibilidade total**: Funciona com arquivos pequenos e grandes
✅ **Progresso preciso**: Tracking em tempo real mesmo para fragmentos
✅ **Robustez**: Resiliência a interrupções de rede
✅ **Performance**: Chunks de 10MB otimizados para velocidade