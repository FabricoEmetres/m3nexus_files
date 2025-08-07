# Upload Manager - Guia de Persistência localStorage

**Autor:** Thúlio Silva  
**Data:** Implementação Completa  
**Versão:** 1.0

## 🎯 **FUNCIONALIDADE IMPLEMENTADA**

O **uploadManager** agora suporta **persistência completa** de arquivos temporários no localStorage, permitindo que o usuário:

1. ✅ **Faça upload** de arquivos temporários
2. ✅ **Saia do formulário** ou faça refresh da página  
3. ✅ **Retorne** e os arquivos **ainda estejam lá**
4. ✅ **Continue interagindo** (remover, visualizar, adicionar mais)

---

## 🏗️ **ARQUITETURA DA SOLUÇÃO**

### **Persistência Inteligente**
- **Metadata Only**: Salva apenas metadados (não File objects)
- **TTL**: Limpeza automática após 24 horas (configurável)
- **Validation**: Verifica se arquivos ainda existem no OneDrive
- **Auto-cleanup**: Remove dados corrompidos ou expirados

### **Chave de Storage Contextual**
```javascript
// Formato: uploadManager_{mode}_{componentId}_{orderId}_{version}
// Exemplo: "uploadManager_budget_comp123_order456_v2"
```

### **Estrutura de Dados no localStorage**
```json
{
  "files": [
    {
      "tempId": "upload_1703123456789_abc123",
      "name": "modelo.stl",
      "status": "success",
      "progress": 100,
      "onedrive_item_id": "01BYE5RZ6QN3ZWBTUFORENF7UBBMA4RTMF",
      "budgetCategory": "slice",
      "fileSize": 1024000,
      "fileType": "application/octet-stream"
    }
  ],
  "timestamp": 1703123456789,
  "expiresAt": 1703209856789,
  "mode": "budget",
  "version": "1.0"
}
```

---

## 🚀 **IMPLEMENTAÇÃO STEP-BY-STEP**

### **1. Importar a Biblioteca**
```javascript
import { createBudgetUploadManager } from '@/lib/uploadManager';
```

### **2. Setup no Componente React**

#### **Método SIMPLES (Recomendado)**
```javascript
const MyComponent = ({ componentId, orderId, version }) => {
  const [uploadedFiles, setUploadedFiles] = useState([]);
  const uploadManagerRef = useRef(null);

  useEffect(() => {
    const initializeUploadManager = async () => {
      if (!uploadManagerRef.current) {
        // Criar upload manager com persistência
        uploadManagerRef.current = createBudgetUploadManager({
          enablePersistence: true,
          ttl: 24 * 60 * 60 * 1000, // 24 horas
        });

        // Inicializar com persistência (MÉTODO MÁGICO!)
        const mergedFiles = await uploadManagerRef.current.initializeWithPersistence(
          componentId,
          orderId,
          version?.toString(),
          uploadedFiles
        );

        // Atualizar estado com arquivos restaurados
        if (mergedFiles.length > uploadedFiles.length) {
          setUploadedFiles(mergedFiles);
          toast.success(`${mergedFiles.length - uploadedFiles.length} ficheiro(s) restaurado(s)!`);
        }

        // Setup callbacks com auto-save
        const enhancedCallbacks = uploadManagerRef.current.createReactCallbacks(
          setUploadedFiles
        );

        // Aplicar callbacks
        uploadManagerRef.current.onProgress = enhancedCallbacks.onProgress;
        uploadManagerRef.current.onStatusChange = enhancedCallbacks.onStatusChange;
        uploadManagerRef.current.onSuccess = enhancedCallbacks.onSuccess;
        uploadManagerRef.current.onError = enhancedCallbacks.onError;
      }
    };

    initializeUploadManager();
  }, [componentId, orderId, version]);

  // Resto da implementação...
};
```

### **3. Handlers Simplificados**

#### **Upload de Arquivos**
```javascript
const handleAddFiles = async (componentId, files) => {
  // Upload automático com persistência integrada
  await uploadManagerRef.current.uploadFiles(componentId, files);
  // Estado e localStorage são atualizados automaticamente!
};
```

#### **Remoção de Arquivos**  
```javascript
const handleRemoveFile = async (componentId, fileKey) => {
  // Remoção integrada com persistência
  await uploadManagerRef.current.handleFileRemoval(
    uploadedFiles,
    setUploadedFiles,
    fileKey
  );
  // OneDrive + estado + localStorage atualizados automaticamente!
};
```

#### **Download de Arquivos**
```javascript
const handleDownloadFile = async (oneDriveItemId, fileName) => {
  // Download automático (abre nova aba)
  await uploadManagerRef.current.downloadFile(oneDriveItemId, fileName, true);
};
```

#### **Reset Completo**
```javascript
const handleReset = async () => {
  // Limpa TUDO: OneDrive + estado + localStorage
  await uploadManagerRef.current.clearAllFiles(setUploadedFiles);
};
```

---

## 🔧 **CONFIGURAÇÃO AVANÇADA**

### **Personalizar TTL**
```javascript
const uploadManager = createBudgetUploadManager({
  enablePersistence: true,
  ttl: 7 * 24 * 60 * 60 * 1000, // 7 dias
});
```

### **Desabilitar Persistência**
```javascript
const uploadManager = createBudgetUploadManager({
  enablePersistence: false, // Sem localStorage
});
```

### **Callbacks Personalizados**
```javascript
const enhancedCallbacks = uploadManagerRef.current.createReactCallbacks(
  setUploadedFiles,
  {
    onSuccess: (fileId, result) => {
      console.log('Custom success handling!');
      // Sua lógica personalizada
    },
    onError: (fileId, error) => {
      console.log('Custom error handling!');
      // Sua lógica personalizada
    }
  }
);
```

---

## 📊 **DEBUGGING & MONITORING**

### **Verificar Storage Stats**
```javascript
const stats = uploadManagerRef.current.getStorageStats();
console.log('Storage Stats:', stats);
/*
{
  totalKeys: 15,
  uploadManagerKeys: 3,
  currentContextSize: 2048,
  totalSize: 51200
}
*/
```

### **Limpeza Manual**
```javascript
// Limpar apenas dados expirados
const cleanedCount = uploadManagerRef.current.cleanupExpiredStorage();
console.log(`Cleaned ${cleanedCount} expired entries`);

// Limpar contexto atual
uploadManagerRef.current.clearStorage();

// Limpar tudo
await uploadManagerRef.current.clearAllFiles(setUploadedFiles);
```

### **Logs Detalhados**
```javascript
// Os logs aparecem automaticamente no console:
// 📦 Storage context set: uploadManager_budget_comp123_order456_v2
// 💾 Saved 3 files to storage: uploadManager_budget_comp123_order456_v2  
// 📂 Loaded 3 files from storage (0 invalid)
// 🔄 Initialized with persistence: 0 current + 3 restored = 3 total
```

---

## 🔍 **VALIDAÇÃO DE ARQUIVOS**

### **Verificação Automática**
O sistema **automaticamente verifica** se os arquivos salvos ainda existem no OneDrive:

```javascript
// Ao carregar do localStorage:
const validatedFiles = await this.validateStoredFiles(storedFiles);

// Remove arquivos que não existem mais
// Mantém arquivos em progresso (não completamente carregados)
// Atualiza localStorage com dados válidos
```

### **Estados Mantidos**
- ✅ **'success'**: Arquivos carregados (validados)
- ✅ **'error'**: Arquivos com erro (mantidos)  
- ✅ **'queueing', 'carregando'**: Arquivos em progresso (mantidos)
- ❌ **Arquivos deletados**: Removidos automaticamente

---

## 🎯 **EXEMPLO COMPLETO DE IMPLEMENTAÇÃO**

```javascript
import React, { useState, useEffect, useRef } from 'react';
import { createBudgetUploadManager } from '@/lib/uploadManager';
import { toast } from 'react-toastify';

const ComponentWithPersistence = ({ componentId, orderId, version }) => {
  const [uploadedFiles, setUploadedFiles] = useState([]);
  const uploadManagerRef = useRef(null);

  // 1. Inicialização com persistência
  useEffect(() => {
    const init = async () => {
      uploadManagerRef.current = createBudgetUploadManager({
        enablePersistence: true,
        ttl: 24 * 60 * 60 * 1000,
      });

      const mergedFiles = await uploadManagerRef.current.initializeWithPersistence(
        componentId,
        orderId,
        version,
        uploadedFiles
      );

      if (mergedFiles.length > 0) {
        setUploadedFiles(mergedFiles);
        if (mergedFiles.length > uploadedFiles.length) {
          toast.success(`${mergedFiles.length - uploadedFiles.length} arquivo(s) restaurado(s)!`);
        }
      }

      const callbacks = uploadManagerRef.current.createReactCallbacks(setUploadedFiles);
      Object.assign(uploadManagerRef.current, callbacks);
    };

    init();
  }, [componentId, orderId, version]);

  // 2. Handlers simples
  const handleUpload = async (files) => {
    await uploadManagerRef.current.uploadFiles(componentId, files);
  };

  const handleRemove = async (fileKey) => {
    await uploadManagerRef.current.handleFileRemoval(uploadedFiles, setUploadedFiles, fileKey);
  };

  const handleDownload = async (oneDriveItemId, fileName) => {
    await uploadManagerRef.current.downloadFile(oneDriveItemId, fileName, true);
  };

  const handleClear = async () => {
    await uploadManagerRef.current.clearAllFiles(setUploadedFiles);
  };

  // 3. UI
  return (
    <div>
      <input
        type="file"
        multiple
        onChange={(e) => handleUpload(Array.from(e.target.files))}
      />
      
      {uploadedFiles.map(file => (
        <div key={file.tempId}>
          <span>{file.name}</span>
          <span>{file.status}</span>
          {file.status === 'success' && (
            <button onClick={() => handleDownload(file.onedrive_item_id, file.name)}>
              Ver Arquivo
            </button>
          )}
          <button onClick={() => handleRemove(file.tempId)}>
            Remover
          </button>
        </div>
      ))}
      
      <button onClick={handleClear}>Limpar Tudo</button>
    </div>
  );
};

export default ComponentWithPersistence;
```

---

## 🔒 **SEGURANÇA & LIMITAÇÕES**

### **Segurança**
- ✅ Não salva File objects (apenas metadata)
- ✅ TTL automático previne acúmulo infinito
- ✅ Validação garante arquivos não deletados externamente  
- ✅ Cleanup automático de dados corrompidos

### **Limitações**
- 📏 **localStorage limit**: ~5-10MB por domínio
- ⏰ **TTL default**: 24 horas (configurável)
- 🌐 **OneDrive dependency**: Precisa validar arquivos online
- 📱 **Private browsing**: Pode não funcionar

### **Boas Práticas**
- 🔄 Sempre chamar `initializeWithPersistence()` na inicialização
- 💾 Usar `autoSave()` ou callbacks integrados
- 🧹 Implementar limpeza na submissão de formulários
- ⚠️ Tratar erros de quota do localStorage

---

## 🎉 **RESULTADO FINAL**

**✅ FUNCIONALIDADE COMPLETA IMPLEMENTADA:**

1. **Upload temporários** → Salvos no localStorage automaticamente
2. **Sair/Refresh** → Dados mantidos com TTL de 24h
3. **Retornar** → Arquivos restaurados automaticamente  
4. **Interação completa** → Upload, download, remoção funcionam normalmente
5. **Validação** → Apenas arquivos válidos são restaurados
6. **Limpeza automática** → Dados expirados removidos automaticamente

**O usuário pode agora trabalhar de forma totalmente fluída, saindo e voltando ao formulário sem perder nenhum arquivo!** 🚀