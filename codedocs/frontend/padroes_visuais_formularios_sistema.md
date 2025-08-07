# 📋 Padrões Visuais de Formulários - Sistema M3 Nexus

**Documento de Referência Completo para Desenvolvimento de Componentes de Formulário**

---

## 🎨 Sistema de Cores

### **Cores Primárias**
```css
/* Cor Corporativa Principal */
--primary-blue: #004587;

/* Backgrounds */
--bg-app: #000000;           /* Background geral da aplicação */
--bg-form: #ffffff;          /* Background de formulários */
--bg-section: #f9fafb;       /* Background de seções */
--bg-disabled: #f3f4f6;      /* Background de campos desabilitados */

/* Textos */
--text-primary: #111827;     /* Texto principal (gray-900) */
--text-secondary: #374151;   /* Texto secundário (gray-700) */
--text-muted: #6b7280;       /* Texto auxiliar (gray-500) */
--text-light: #9ca3af;       /* Texto claro (gray-400) */

/* Bordas */
--border-default: #e5e7eb;   /* Bordas padrão (gray-200) */
--border-input: #d1d5db;     /* Bordas de inputs (gray-300) */
--border-focus: #004587;     /* Bordas em foco */
```

### **Sistema de Cores por Contexto**
```css
/* Máquinas */
--machine-bg: #dbeafe;       /* bg-blue-100 */
--machine-text: #1e40af;     /* text-blue-800 */

/* Materiais */
--material-bg: #d1fae5;      /* bg-emerald-100 */
--material-text: #065f46;    /* text-emerald-800 */

/* Quantidades */
--quantity-bg: #ebf3fb;      /* bg-[#EBF3FB] */
--quantity-text: #004587;    /* text-[#004587] */

/* Dimensões */
--dimension-bg: #fef3c7;     /* bg-yellow-100 */
--dimension-text: #92400e;   /* text-yellow-800 */

/* Pesos */
--weight-bg: #e9d5ff;        /* bg-purple-100 */
--weight-text: #6b21a8;      /* text-purple-800 */

/* Acabamentos */
--finishing-bg: #fee2e2;     /* bg-red-100 */
--finishing-text: #991b1b;   /* text-red-800 */
```

### **Estados de Feedback**
```css
/* Sucesso */
--success-bg: #f0fdf4;       /* Fundo de mensagens de sucesso */
--success-border: #bbf7d0;   /* Borda de sucesso */
--success-text: #166534;     /* Texto de sucesso */
--success-icon: #22c55e;     /* Ícone de sucesso */

/* Erro */
--error-bg: #fef2f2;         /* Fundo de mensagens de erro */
--error-border: #fecaca;     /* Borda de erro */
--error-text: #dc2626;       /* Texto de erro (text-red-600) */
--error-field: #ef4444;      /* Texto de erro em campos (text-red-500) */

/* Aviso */
--warning-bg: #fffbeb;       /* Fundo de avisos */
--warning-border: #fed7aa;   /* Borda de avisos */
--warning-text: #d97706;     /* Texto de avisos (text-amber-600) */

/* Informação */
--info-bg: #eff6ff;          /* Fundo de informações */
--info-border: #bfdbfe;      /* Borda de informações */
--info-text: #2563eb;        /* Texto de informações */
```

---

## 🔤 Tipografia

### **Família de Fontes**
```css
/* Fonte Principal */
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;

/* Fonte Secundária (Títulos Especiais) */
font-family: 'Orbitron', monospace;
```

### **Hierarquia de Pesos**
```css
--font-normal: 400;          /* font-normal */
--font-medium: 500;          /* font-medium */
--font-semibold: 600;        /* font-semibold */
--font-bold: 700;            /* font-bold */
```

### **Tamanhos de Fonte por Contexto**
```css
/* Títulos de Formulário */
--title-main: 1.25rem;       /* text-xl (20px) */
--title-section: 1.125rem;   /* text-lg (18px) */
--title-subsection: 1rem;    /* text-base (16px) */

/* Labels e Textos */
--label-size: 0.875rem;      /* text-sm (14px) */
--input-size: 0.875rem;      /* text-sm (14px) */
--helper-size: 0.75rem;      /* text-xs (12px) */

/* Responsivo */
--input-size-mobile: 0.875rem;   /* text-sm em mobile */
--input-size-desktop: 1rem;      /* text-base em desktop */
```

### **Altura de Linha**
```css
--line-height-tight: 1.25;   /* leading-tight */
--line-height-normal: 1.5;   /* leading-normal */
--line-height-relaxed: 1.625; /* leading-relaxed */
```

---

## 📏 Sistema de Espaçamentos

### **Espaçamentos Internos (Padding)**
```css
/* Inputs e Campos */
--input-padding: 0.75rem;    /* p-3 (12px) */
--input-padding-large: 1rem; /* p-4 (16px) */

/* Botões */
--button-padding-y: 0.75rem; /* py-3 (12px) */
--button-padding-x: 1.5rem;  /* px-6 (24px) */

/* Containers */
--container-padding: 1rem;    /* p-4 (16px) */
--container-padding-large: 1.5rem; /* p-6 (24px) */

/* Modais */
--modal-padding: 1.5rem;     /* p-6 (24px) */
```

### **Espaçamentos Externos (Margin)**
```css
/* Entre Campos */
--field-margin: 1rem;        /* mb-4 (16px) */
--field-margin-large: 1.5rem; /* mb-6 (24px) */

/* Entre Seções */
--section-margin: 1.5rem;    /* mb-6 (24px) */
--section-margin-large: 2rem; /* mb-8 (32px) */
```

### **Gaps em Grids e Flex**
```css
--gap-small: 0.75rem;        /* gap-3 (12px) */
--gap-medium: 1rem;          /* gap-4 (16px) */
--gap-large: 1.5rem;         /* gap-6 (24px) */
```

---

## 🧩 Componentes de Formulário

### **Inputs de Texto**
```html
<!-- Estrutura Padrão -->
<div className="mb-4 w-full">
  <label className="block text-sm text-gray-500 mb-2">
    Nome do Campo *
  </label>
  <input
    type="text"
    className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#004587] focus:border-[#004587]"
    placeholder="Texto de exemplo..."
  />
  <p className="text-red-500 text-sm mt-1">Mensagem de erro</p>
</div>
```

**Classes CSS Específicas:**
```css
/* Input Base */
.input-base {
  @apply w-full px-3 py-2 border border-gray-200 rounded-lg;
  @apply focus:outline-none focus:ring-1 focus:ring-[#004587] focus:border-[#004587];
  @apply transition-all duration-300;
}

/* Input Disabled */
.input-disabled {
  @apply opacity-50 cursor-not-allowed bg-gray-50;
}

/* Input Error */
.input-error {
  @apply border-red-300 focus:ring-red-500 focus:border-red-500;
}
```

### **Selects/Dropdowns**
```html
<!-- Select Padrão -->
<div className="mb-4 w-full">
  <label className="block text-sm text-gray-500 mb-2">
    Selecionar Opção *
  </label>
  <select className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#004587] focus:border-[#004587]">
    <option value="">Selecionar...</option>
    <option value="1">Opção 1</option>
  </select>
</div>
```

### **Textareas**
```html
<!-- Textarea Padrão -->
<div className="mb-4 w-full">
  <label className="block text-sm text-gray-500 mb-2">
    Descrição
  </label>
  <textarea
    rows="4"
    className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#004587] focus:border-[#004587] resize-none"
    placeholder="Digite a descrição..."
  ></textarea>
</div>
```

### **Botões**
```html
<!-- Botão Primário -->
<button className="w-full sm:w-auto py-3 px-6 rounded-md text-center transition-all duration-300 bg-[#004587] text-white transform hover:-translate-y-0.5 active:translate-y-0">
  Submeter
</button>

<!-- Botão Secundário -->
<button className="w-full sm:w-auto py-3 px-6 rounded-md text-center transition-all duration-300 border border-gray-200 text-gray-500 transform hover:-translate-y-0.5 active:translate-y-0">
  Cancelar
</button>
```

**Variações de Botões:**
```css
/* Botão Primário */
.btn-primary {
  @apply py-3 px-6 rounded-md text-center transition-all duration-300;
  @apply bg-[#004587] text-white;
  @apply transform hover:-translate-y-0.5 active:translate-y-0;
  @apply disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none;
}

/* Botão Secundário */
.btn-secondary {
  @apply py-3 px-6 rounded-md text-center transition-all duration-300;
  @apply border border-gray-200 text-gray-500;
  @apply transform hover:-translate-y-0.5 active:translate-y-0;
}

/* Botão de Perigo */
.btn-danger {
  @apply py-3 px-6 rounded-md text-center transition-all duration-300;
  @apply bg-red-600 text-white;
  @apply transform hover:-translate-y-0.5 active:translate-y-0;
}
```

---

## 📱 Responsividade

### **Breakpoints do Sistema**
```css
/* Mobile First Approach */
/* xs: 0px - 639px (padrão) */
/* sm: 640px+ */
/* md: 768px+ */
/* lg: 1024px+ */
/* xl: 1280px+ */
/* 2xl: 1536px+ */
```

### **Padrões de Layout Responsivo**
```html
<!-- Grid Responsivo Padrão -->
<div className="grid grid-cols-1 md:grid-cols-2 gap-6">
  <!-- Campos do formulário -->
</div>

<!-- Botões Responsivos -->
<div className="flex flex-col sm:flex-row gap-3 sm:gap-4">
  <button className="w-full sm:w-auto">Botão 1</button>
  <button className="w-full sm:w-auto">Botão 2</button>
</div>

<!-- Container Responsivo -->
<div className="w-full max-w-sm sm:max-w-2xl md:max-w-4xl lg:max-w-6xl xl:max-w-7xl mx-4">
  <!-- Conteúdo -->
</div>
```

### **Tamanhos de Fonte Responsivos**
```css
/* Input Text Size */
.input-responsive {
  @apply text-sm md:text-base;
}

/* Button Text Size */
.button-responsive {
  @apply text-sm md:text-base;
}
```

---

## 🎭 Estados Visuais

### **Estados de Campos**
```css
/* Estado Normal */
.field-normal {
  @apply border-gray-200 bg-white text-gray-900;
}

/* Estado Focus */
.field-focus {
  @apply focus:outline-none focus:ring-1 focus:ring-[#004587] focus:border-[#004587];
}

/* Estado Disabled */
.field-disabled {
  @apply opacity-50 cursor-not-allowed bg-gray-50 text-gray-500;
}

/* Estado Error */
.field-error {
  @apply border-red-300 focus:ring-red-500 focus:border-red-500;
}

/* Estado Success */
.field-success {
  @apply border-green-300 focus:ring-green-500 focus:border-green-500;
}
```

### **Estados de Loading**
```html
<!-- Spinner Principal -->
<div className="w-8 h-8 border-4 border-gray-200 border-t-[#004587] rounded-full animate-spin"></div>

<!-- Loading em Botão -->
<button disabled className="opacity-50 cursor-not-allowed">
  <FontAwesomeIcon icon={faSpinner} className="animate-spin mr-2" />
  Carregando...
</button>
```

---

## 🔄 Animações e Transições

### **Transições Padrão**
```css
/* Transição Base */
.transition-base {
  @apply transition-all duration-300;
}

/* Hover Effects */
.hover-lift {
  @apply transform hover:-translate-y-0.5 active:translate-y-0;
}

/* Focus Transitions */
.focus-transition {
  @apply transition-all duration-200 ease-in-out;
}
```

### **Animações de Loading (Skeleton)**
```css
/* Wave Animation */
@keyframes skeleton-shimmer {
  0% {
    background-position: -1000px 0;
    opacity: 0.8;
  }
  50% {
    opacity: 1;
  }
  100% {
    background-position: 1000px 0;
    opacity: 0.8;
  }
}

.animate-wave {
  background: linear-gradient(
    90deg,
    #f3f4f5 8%,
    #f3f4f5 18%,
    #f9fafb 33%,
    #f9fafb 50%,
    #f9fafb 55%,
    #f3f4f5 65%,
    #f3f4f5 82%,
    #f3f4f5 92%
  );
  background-size: 1000px 100%;
  animation: skeleton-shimmer 3s linear infinite;
}
```

### **Animações de Modal**
```css
/* Modal Appear */
@keyframes modal-appear {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

/* Modal Disappear */
@keyframes modal-disappear {
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.95);
  }
}
```

---

## ✅ Validações e Feedback

### **Mensagens de Erro**
```html
<!-- Erro em Campo Individual -->
<p className="text-red-500 text-sm mt-1">Este campo é obrigatório</p>

<!-- Erro Geral do Formulário -->
<div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
  <div className="flex">
    <FontAwesomeIcon icon={faExclamationTriangle} className="text-red-400 mr-3 mt-0.5" />
    <div>
      <h3 className="text-sm font-medium text-red-800">Erros encontrados</h3>
      <ul className="text-sm text-red-700 mt-1 list-disc list-inside">
        <li>Campo nome é obrigatório</li>
        <li>Email deve ter formato válido</li>
      </ul>
    </div>
  </div>
</div>
```

### **Mensagens de Sucesso**
```html
<!-- Sucesso Geral -->
<div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
  <div className="flex">
    <FontAwesomeIcon icon={faCheckCircle} className="text-green-400 mr-3 mt-0.5" />
    <div>
      <h3 className="text-sm font-medium text-green-800">Sucesso!</h3>
      <p className="text-sm text-green-700 mt-1">Formulário submetido com sucesso.</p>
    </div>
  </div>
</div>
```

### **Campos Obrigatórios**
```html
<!-- Label com Asterisco -->
<label className="block text-sm text-gray-500 mb-2">
  Nome do Campo <span className="text-red-500">*</span>
</label>
```

### **Validação em Tempo Real**
```css
/* Classes para Validação */
.field-valid {
  @apply border-green-300 focus:ring-green-500 focus:border-green-500;
}

.field-invalid {
  @apply border-red-300 focus:ring-red-500 focus:border-red-500;
}

.field-validating {
  @apply border-yellow-300 focus:ring-yellow-500 focus:border-yellow-500;
}
```

---

## 🗂️ Modais

### **Estrutura Base de Modal**
```html
<!-- Modal Container -->
<div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
  <!-- Modal Content -->
  <div className="bg-white rounded-lg shadow-xl w-full max-w-sm sm:max-w-2xl md:max-w-4xl lg:max-w-6xl xl:max-w-7xl h-[90vh] overflow-hidden transform transition-all duration-300 mx-4 flex flex-col">

    <!-- Modal Header -->
    <div className="border-b border-gray-200 p-6 flex-shrink-0">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-gray-900">Título do Modal</h2>
          <p className="text-sm text-gray-600 mt-1">Descrição do modal</p>
        </div>
        <button className="p-1.5 sm:p-2 rounded-lg text-gray-400 hover:bg-white hover:text-gray-500 focus:outline-none focus:ring-1 focus:ring-[#004587] focus:ring-offset-2">
          <FontAwesomeIcon icon={faTimes} className="w-4 h-4 sm:w-5 sm:h-5" />
        </button>
      </div>
    </div>

    <!-- Modal Body -->
    <div className="flex-1 overflow-y-auto min-h-0 p-6">
      <!-- Conteúdo do modal -->
    </div>

    <!-- Modal Footer -->
    <div className="border-t border-gray-200 p-6 bg-white flex-shrink-0">
      <div className="flex flex-col sm:flex-row justify-end gap-3 sm:gap-4">
        <button className="btn-secondary">Cancelar</button>
        <button className="btn-primary">Confirmar</button>
      </div>
    </div>
  </div>
</div>
```

### **Tamanhos de Modal**
```css
/* Pequeno */
.modal-sm { @apply max-w-sm; }

/* Médio */
.modal-md { @apply max-w-2xl; }

/* Grande */
.modal-lg { @apply max-w-4xl; }

/* Extra Grande */
.modal-xl { @apply max-w-6xl; }

/* Full Width */
.modal-full { @apply max-w-7xl; }
```

### **Modal de Confirmação**
```html
<!-- Modal de Confirmação Simples -->
<div className="bg-white rounded-lg shadow-xl max-w-md mx-4 p-6">
  <div className="flex items-center mb-4">
    <FontAwesomeIcon icon={faExclamationTriangle} className="text-amber-500 mr-3 text-xl" />
    <h3 className="text-lg font-medium text-gray-900">Confirmar Ação</h3>
  </div>
  <p className="text-sm text-gray-600 mb-6">
    Tem certeza que deseja realizar esta ação? Esta operação não pode ser desfeita.
  </p>
  <div className="flex justify-end gap-3">
    <button className="btn-secondary">Cancelar</button>
    <button className="btn-danger">Confirmar</button>
  </div>
</div>
```

---

## 💬 Tooltips

### **Tooltip Básico**
```html
<!-- Tooltip Container -->
<div className="relative group">
  <button className="p-2 text-gray-400 hover:text-gray-600">
    <FontAwesomeIcon icon={faQuestionCircle} />
  </button>

  <!-- Tooltip Content -->
  <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-gray-900 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none whitespace-nowrap z-10">
    Texto do tooltip
    <!-- Arrow -->
    <div className="absolute top-full left-1/2 transform -translate-x-1/2 border-4 border-transparent border-t-gray-900"></div>
  </div>
</div>
```

### **Tooltip com Conteúdo Rico**
```html
<!-- Tooltip Avançado -->
<div className="fixed z-[9999] pointer-events-none bg-white border border-gray-200 rounded-lg shadow-lg p-3 text-sm leading-relaxed max-w-xs">
  <h4 className="font-medium text-gray-900 mb-1">Título do Tooltip</h4>
  <p className="text-gray-600">Descrição detalhada do elemento com mais informações.</p>
</div>
```

---

## 📁 Accordions

### **Accordion Padrão**
```html
<!-- Accordion Container -->
<div className="border border-gray-200 rounded-lg overflow-hidden">
  <!-- Accordion Header -->
  <button className="w-full px-6 py-4 text-left bg-gray-50 hover:bg-gray-100 focus:outline-none focus:ring-1 focus:ring-[#004587] focus:ring-inset transition-colors duration-200">
    <div className="flex items-center justify-between">
      <div className="flex items-center">
        <FontAwesomeIcon icon={faRectangleList} className="text-[#004587] mr-3" />
        <h3 className="text-lg font-medium text-gray-900">Título da Seção</h3>
      </div>
      <FontAwesomeIcon
        icon={isOpen ? faChevronUp : faChevronDown}
        className="text-gray-400 transition-transform duration-200"
      />
    </div>
  </button>

  <!-- Accordion Content -->
  <div className={`overflow-hidden transition-all duration-400 ease-in-out ${isOpen ? 'max-h-screen' : 'max-h-0'}`}>
    <div className="p-6 bg-white border-t border-gray-200">
      <!-- Conteúdo do accordion -->
    </div>
  </div>
</div>
```

---

## 📤 Upload de Arquivos

### **Campo de Upload**
```html
<!-- Upload Field Container -->
<div className="mb-6">
  <label className="block text-sm text-gray-500 mb-2">
    Arquivos <span className="text-gray-500">(Opcional)</span>
  </label>

  <!-- Upload Grid -->
  <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">

    <!-- Upload Button -->
    <div className="relative">
      <input
        type="file"
        multiple
        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
        accept=".pdf,.jpg,.jpeg,.png,.dwg,.step,.stl"
      />
      <div className="border-2 border-dashed border-gray-200 rounded-lg p-4 text-center hover:border-[#004587] hover:bg-blue-50 transition-colors duration-200 min-h-[120px] flex flex-col items-center justify-center">
        <FontAwesomeIcon icon={faPlus} className="text-gray-400 text-2xl mb-2" />
        <span className="text-sm text-gray-500">Adicionar</span>
      </div>
    </div>

    <!-- File Item -->
    <div className="relative flex flex-col items-center rounded-lg overflow-hidden bg-white border border-gray-200 group cursor-pointer">
      <!-- File Status Indicator -->
      <div className="absolute top-0 inset-x-0 h-1 bg-green-500"></div>

      <!-- File Icon -->
      <div className="p-3 flex-1 flex items-center justify-center">
        <FontAwesomeIcon icon={faFile} className="text-gray-400 text-2xl" />
      </div>

      <!-- File Name -->
      <div className="w-full px-2 py-2 bg-gray-50 border-t border-gray-200">
        <p className="text-xs text-gray-600 truncate text-center">arquivo.pdf</p>
      </div>

      <!-- Remove Button -->
      <button className="absolute top-1 right-1 p-1 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-200">
        <FontAwesomeIcon icon={faTimes} className="text-xs" />
      </button>
    </div>
  </div>
</div>
```

### **Estados de Upload**
```css
/* Upload Success */
.upload-success {
  @apply border-green-200 bg-green-50;
}
.upload-success .status-bar {
  @apply bg-green-500;
}

/* Upload Error */
.upload-error {
  @apply border-red-200 bg-red-50;
}
.upload-error .status-bar {
  @apply bg-red-500;
}

/* Upload Loading */
.upload-loading {
  @apply border-blue-200 bg-blue-50;
}
.upload-loading .status-bar {
  @apply bg-blue-500;
}
```

---

## 🏷️ Tags e Pills

### **Pills de Status**
```html
<!-- Status Pills -->
<span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
  Máquina
</span>

<span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">
  Material
</span>

<span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-[#EBF3FB] text-[#004587]">
  Quantidade: 5
</span>
```

### **Tags Removíveis**
```html
<!-- Removable Tag -->
<span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800">
  Tag Name
  <button className="ml-2 text-gray-400 hover:text-gray-600">
    <FontAwesomeIcon icon={faTimes} className="text-xs" />
  </button>
</span>
```

---

## 📊 Tabelas em Formulários

### **Tabela Responsiva**
```html
<!-- Table Container -->
<div className="overflow-x-auto">
  <table className="min-w-full divide-y divide-gray-200">
    <!-- Table Header -->
    <thead className="bg-gray-50">
      <tr>
        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
          Nome
        </th>
        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
          Status
        </th>
        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
          Ações
        </th>
      </tr>
    </thead>

    <!-- Table Body -->
    <tbody className="bg-white divide-y divide-gray-200">
      <tr className="hover:bg-gray-50">
        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
          Item 1
        </td>
        <td className="px-6 py-4 whitespace-nowrap">
          <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
            Ativo
          </span>
        </td>
        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
          <button className="text-[#004587] hover:text-blue-700">Editar</button>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

---

## 🔄 Loading States

### **Skeleton Loading para Formulários**
```html
<!-- Form Skeleton -->
<div className="space-y-6">
  <!-- Title Skeleton -->
  <div className="animate-wave h-6 bg-gray-200 rounded w-1/3"></div>

  <!-- Field Skeletons -->
  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
    <div className="space-y-2">
      <div className="animate-wave h-4 bg-gray-200 rounded w-1/4"></div>
      <div className="animate-wave h-10 bg-gray-200 rounded"></div>
    </div>
    <div className="space-y-2">
      <div className="animate-wave h-4 bg-gray-200 rounded w-1/3"></div>
      <div className="animate-wave h-10 bg-gray-200 rounded"></div>
    </div>
  </div>

  <!-- Button Skeleton -->
  <div className="flex justify-end">
    <div className="animate-wave h-12 bg-gray-200 rounded w-32"></div>
  </div>
</div>
```

### **Loading Spinner Inline**
```html
<!-- Inline Spinner -->
<div className="flex items-center justify-center py-4">
  <div className="w-6 h-6 border-2 border-gray-200 border-t-[#004587] rounded-full animate-spin"></div>
  <span className="ml-2 text-sm text-gray-500">Carregando...</span>
</div>
```

---

## 📋 Checklists e Guidelines

### **Checklist para Novos Formulários**

#### ✅ **Estrutura Base**
- [ ] Container com `space-y-6` para espaçamento entre seções
- [ ] Labels com `text-sm font-medium text-gray-700 mb-2`
- [ ] Campos obrigatórios marcados com asterisco vermelho
- [ ] Mensagens de erro com `text-red-500 text-sm mt-1`

#### ✅ **Responsividade**
- [ ] Grid responsivo: `grid-cols-1 md:grid-cols-2`
- [ ] Botões responsivos: `w-full sm:w-auto`
- [ ] Texto responsivo: `text-sm md:text-base`
- [ ] Padding responsivo em containers

#### ✅ **Estados Visuais**
- [ ] Estados de focus com `focus:ring-1 focus:ring-[#004587]`
- [ ] Estados disabled com `opacity-50 cursor-not-allowed`
- [ ] Transições com `transition-all duration-300`
- [ ] Hover effects em botões

#### ✅ **Acessibilidade**
- [ ] Labels associados aos inputs
- [ ] Aria-labels em botões de ação
- [ ] Contraste adequado de cores
- [ ] Navegação por teclado funcional

#### ✅ **Validação**
- [ ] Validação em tempo real implementada
- [ ] Mensagens de erro claras e específicas
- [ ] Estados visuais para campos válidos/inválidos
- [ ] Prevenção de submissão com erros

---

*Documento criado por: Thúlio Silva*
*Sistema: M3 Nexus - Padrões Visuais de Formulários*
