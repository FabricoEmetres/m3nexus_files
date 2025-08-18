# Componente de Tela: ImageGallery

Autor: Thúlio Silva

---

## 🎯 Objetivo

Descrever a API, arquitetura interna, comportamentos de interação e padrões de uso do componente de tela `ImageGallery`, usado para visualização fullscreen de imagens com zoom, pan e navegação entre múltiplas imagens.

---

## 🧩 Localização e Integração

- Arquivo: `00_frontend/src/components/ui/ImageGallery.js`
- Uso típico: embutido por `ComponentProfileImage` para abrir a galeria fullscreen ao clicar na imagem de perfil do orçamento.

Props principais:
```ts
interface ImageItem {
  id: string;
  url: string;
  name?: string;
  fileSize?: number | null;
  isProfile?: boolean; // marcação visual e estado do botão
}

interface ImageGalleryProps {
  isOpen: boolean;
  images: ImageItem[];
  initialIndex?: number;
  onClose?: () => void;
  onIndexChange?: (index: number) => void;
  onSetProfileImage?: (image: ImageItem) => void; // opcional
  config?: {
    zoomLevels?: { scale: number; name: string }[];
    dragDelay?: number;             // default 50ms
    autoHideDelay?: number;         // default 2000ms
    transitionDuration?: number;    // default 500ms
    wheelStepThreshold?: number;    // default 180
  };
}
```

---

## 🧠 Arquitetura e Estados

- `zoomLevel` (0..N-1) com vetor `ZOOM_LEVELS` configurável
- `imagePosition` (x,y) – pan acumulado, clampado por nível
- `isDragging` – controla cursor e auto-hide
- `showModals` – auto-hide de UI (top bar/dots)
- `isImageLoaded` – controla spinner e transição da imagem

Refs auxiliares:
- `imageRef` – bounding rect para cálculos de focal e limites
- `zoomLevelRef` e `imagePositionRef` – evitam stale closures
- `dragTimeoutRef`, `mouseIdleTimerRef` – coordenação de interação

---

## 🖱️ Interações

- Scroll do mouse (zoom direcional):
  - Acumula delta até `wheelStepThreshold`, então aplica ±1 nível
  - Foco no cursor: ajusta translate para manter ponto sob o mouse
- Duplo clique (zoom direcional):
  - Mesmo princípio do scroll; sobe nível até o máximo e reseta para 0
- Pan/arrasto:
  - Ativo com `zoomLevel > 0`, atualiza `imagePosition` com clamp dinâmico
- Teclado:
  - `ArrowRight/ArrowLeft`: navegação wrap-around de imagens
  - `+`/`=`: zoom in; `-`/`_`: zoom out
- Fechar:
  - Clique fora, tecla `Escape` ou botão X

---

## 🎛️ UI e Estilo

- Top bar (esquerda: X + nome + tamanho; centro: dots; direita: indicador de zoom)
- Botão “Definir como perfil” (se `onSetProfileImage`):
  - Desativado e com rótulo “Definido como perfil” quando `isProfile`
- Spinner central padrão enquanto `isImageLoaded === false`
- Container responsivo; transições com `transitionDuration`

---

## 🧮 Cálculo de Limites e Transform

- Transform: `translate(x, y) scale(scale)` para estabilidade do pan
- Limites por nível: fator por nível (`{1:0.9, 2:0.7, 3:0.5, 4:0.3}`) aplicado ao excedente
- Recalculo de limites ao mudar `zoomLevel` e ao aplicar zoom focal

---

## 🔌 Contratos e Integrações

- Recebe `images` de `ComponentProfileImage` com campos suficientes para a UI
- Chama `onSetProfileImage(image)` para persistir `profileImageId` (localStorage via UploadManager) e atualização imediata do cabeçalho

---

## 🧪 Testes rápidos

1) Navegação wrap-around por setas (UI e teclado)
2) Zoom direcional por scroll sem “super zoom”
3) Double‑click direcional focado no cursor
4) Pan com clamp visível em zoom alto
5) Botão de perfil desativado na imagem atual definida
6) Spinner aparece ao trocar de imagem até `onLoad`

---

## ⚙️ Extensões sugeridas

- `PageUp/PageDown` e `Home/End` para navegação
- Toggle de double-click entre 0 ↔ nível preferido (ex.: 2x)
- Animação/label adicional para o dot ativo ou nível de zoom

---

## 🛡️ Boas práticas

- Cleanup rigoroso de listeners no `useEffect` principal
- Tudo encapsulado no componente; sem vazamento global de estado
- Cálculos numéricos prontos para SSR (guards em DOM)

---

## 📎 Exemplos

Uso básico:
```tsx
<ImageGallery
  isOpen={isOpen}
  images={images}
  initialIndex={index}
  onClose={() => setOpen(false)}
  onIndexChange={setIndex}
  onSetProfileImage={(img) => persistProfile(img.id)}
  config={{ wheelStepThreshold: 200 }}
/>
```

