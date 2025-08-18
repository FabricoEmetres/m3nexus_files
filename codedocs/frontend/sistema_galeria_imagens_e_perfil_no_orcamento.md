# Sistema de Galeria de Imagens e Foto de Perfil no Orçamento

Autor: Thúlio Silva

---

## 🎯 Objetivo

Documentar a implementação e os padrões do sistema de imagens no contexto da página de orçamento de componente 3D, cobrindo:
- Definição automática de foto de perfil (primeira imagem slice carregada com sucesso)
- Seleção manual de foto de perfil via ImageGallery
- Galeria fullscreen com zoom direcional, pan/arrasto, paginação e navegação por teclado
- Persistência em localStorage alinhada ao UploadManager
- Padrões visuais (spinner, botões) e UX de transição

---

## 🧭 Visão Geral da Solução

- A imagem de perfil do componente 3D é determinada por prioridade:
  1) Seleção do utilizador persistida em localStorage (`profileImageId`)
  2) Fallback: a primeira imagem `sliceImage` carregada (mais antiga por timestamp no `tempId`).
- A escolha de perfil pode ser feita diretamente na galeria fullscreen (ImageGallery) pelo botão “Definir como perfil”.
- O cabeçalho (ComponentBudgetTitle + ComponentProfileImage) atualiza imediatamente após a escolha, sem recarregar a página.
- A galeria suporta:
  - Zoom direcional (scroll do mouse e double-click), com foco no cursor
  - Pan/arrasto com limites dinâmicos por nível de zoom
  - Paginação por “bolinhas” no topo, centralizadas
  - Navegação wrap-around por setas (UI e teclado)
  - Zoom por teclado (+, -, =, _)
  - Spinner padronizado durante carregamento de imagem

---

## 🧩 Componentes e Arquivos Envolvidos

- 00_frontend/src/app/component/[basecomponentId]/[version]/budget/page.js
  - Orquestra a página de orçamento, recebendo atualizações da imagem de perfil.

- 00_frontend/src/components/forms/budgetforms/ComponentBudgetTitle.js
  - Cabeçalho do orçamento. Renderiza a imagem de perfil via `ComponentProfileImage`.
  - Recebe `profileImageData` (fallback) e utiliza storage quando disponível.

- 00_frontend/src/components/ui/ComponentProfileImage.js
  - Componente circular de imagem de perfil.
  - Integra ImageGallery fullscreen e o hook de storage.
  - Atualiza imediatamente a UI ao definir a imagem de perfil pela galeria.

- 00_frontend/src/components/ui/ImageGallery.js
  - Galeria fullscreen: zoom direcional, pan, paginação, setas, teclado e spinner.
  - Botão “Definir como perfil” ao lado do nome/tamanho (topo esquerdo).

- 00_frontend/src/components/forms/budgetforms/ForgeBudgetForm.js
  - Regras de extração de foto de perfil (selecionada > primeira carregada).
  - Integra com UploadManager/storage para leitura do `profileImageId`.

- 00_frontend/src/components/forms/uploads/UploadField.js
  - Grelha de ficheiros (staged/existentes). O botão “Definir como perfil” foi removido daqui por decisão de UX (migrou para ImageGallery).

- 00_frontend/src/hooks/useProfileImageFromStorage.js
  - Hook que resolve a imagem de perfil a partir do localStorage (seleção do utilizador > primeira slice carregada) e gera URL direta.

- 00_frontend/src/lib/uploadManager.js
  - Persistência: guarda ficheiros e preserva `profileImageId` entre salvamentos.

---

## 🧱 Persistência e Storage Key

- Padrão do UploadManager para chave de storage:
  - `uploadManager_[mode]_[componentId]_order_[orderId]_v[version]`
  - No contexto de orçamento: `mode = "budget"`
- A seleção de perfil é persistida no mesmo registo do localStorage via `profileImageId`.
- Componentes que precisam ler/escrever a seleção:
  - `ComponentProfileImage` (helper local `generateStorageKeyForBudget`)
  - `useProfileImageFromStorage` (helper `generateStorageKey`)
  - `uploadManager.saveToStorage` (preserva `profileImageId` existente)

---

## 🔎 Lógica de Seleção da Foto de Perfil

1) Carregamento de imagens `sliceImage` (status `success` e com `onedrive_item_id`).
2) Se existir `profileImageId` no storage, usar essa imagem.
3) Senão, ordenar por timestamp extraído de `tempId` (ascendente) e usar a primeira (mais antiga ⇒ “primeira carregada”).

Notas:
- O `tempId` tem formato `upload_TIMESTAMP_...`; o timestamp é extraído para ordenação.
- A atualização da UI ao definir perfil é imediata (set de estado + evento `uploadManager:filesUpdated`).

---

## 🖼️ ImageGallery: Funcionalidades-Chave

- Zoom Direcional (Scroll)
  - Direção correta: deltaY < 0 ⇒ zoom in; deltaY > 0 ⇒ zoom out.
  - Menos sensível: acumula delta e só aplica passo de zoom após `wheelStepThreshold` (padrão: 180). Configurável via `config.wheelStepThreshold`.
  - Ponto sob o cursor fica no foco: cálculo de `translate` proporcional ao factor de escala.

- Zoom Direcional (Double-Click)
  - Mesmo princípio do scroll, aplicando zoom focado no cursor.
  - Alterna níveis incrementais e reseta para 0 ao atingir o máximo.

- Pan/Arrasto
  - Ativo quando zoom > 0.
  - Movimento incremental com `translate(...) scale(...)` (translate antes de scale para estabilidade).
  - Limites dinâmicos por nível de zoom com `limitFactors`.

- Navegação
  - Wrap-around nas setas (UI e teclado): ao chegar ao fim/começo, “dá a volta”.
  - Teclado: ArrowLeft/ArrowRight para navegar; `+`/`=` para zoom in; `-`/`_` para zoom out.

- UI/UX
  - Spinner central padrão: `w-8 h-8 border-4 border-gray-200 border-t-[#004587] rounded-full animate-spin`.
  - Dots de paginação no topo, centrados entre as barras laterais de informação.
  - Botão “Definir como perfil” ao lado do nome/tamanho (usa `currentImage.isProfile` para estado desativado/ativado e rótulo apropriado).
  - Quando troca de imagem: imagem anterior some (opacity 0) e spinner aparece até `onLoad` da nova imagem.

---

## 🔧 Integrações e Contratos

- `ComponentProfileImage` ⇒ `ImageGallery`:
  - Passa `images` com `id`, `url`, `name`, `fileSize`, `isProfile`.
  - `onSetProfileImage(image)` persiste `profileImageId` e atualiza `displayUrl` para refletir imediatamente.

- `useProfileImageFromStorage`:
  - Resolve `profileImageData` e `profileImageUrl` a partir da mesma storage key.
  - Gera URLs diretas via `getImageUrl` (com token temporário) e mantém cache local.

- `uploadManager.saveToStorage`
  - Garante que o `profileImageId` anterior seja preservado ao atualizar o registo com nova lista de ficheiros concluídos.

---

## 🧪 Testes Sugeridos

1) Perfil por padrão
- Carregar 2+ imagens `sliceImage`. A primeira carregada (mais antiga no `tempId`) deve ser a foto de perfil.

2) Definir perfil manualmente
- Abrir ImageGallery, clicar “Definir como perfil” em outra imagem.
- Esperado: cabeçalho muda imediatamente; persistência confirmada após reload.

3) Scroll e double-click
- Verificar zoom direcional focado no cursor, sem “super zoom” com toques leves.

4) Pan e limites
- Com zoom > 0, arrastar e verificar clamp dos limites por nível.

5) Navegação e dots
- Navegar por setas (UI e teclado) com wrap-around; dots refletem o índice atual.

6) Spinner e transições
- Ao trocar de imagem: imagem anterior some (opacity 0) e spinner aparece até a nova carregar.

---

## 🛡️ Segurança e Operacional

- LocalStorage armazena apenas metadados de uploads e `profileImageId` (sem dados sensíveis).
- URLs de imagem usam helper central `getImageUrl` com tokens de curta duração.
- Eventos custom (DOM) usados apenas localmente (`uploadManager:filesUpdated`), sem exposição externa.
- Evitar vazamento de listeners: todos os addEventListener têm cleanup correspondente no `useEffect` global.

---

## ⚙️ Configuração e Extensibilidade

- Sensibilidade do scroll: `config.wheelStepThreshold` (default 180).
- Níveis/escala do zoom: `config.zoomLevels` (array com `{ scale, name }`).
- Duração de transições: `config.transitionDuration` (ms).
- Fácil extensão para:
  - Teclas adicionais (PageUp/PageDown, Home/End)
  - “Toggle” de double-click entre 0 e um nível preferido (ex.: 2x)
  - Indicador visual adicional de zoom

---

## 📝 Decisões de Design

- Botão de “Definir como perfil” centralizado na ImageGallery:
  - Minimiza poluição da grelha de upload e coloca a ação no contexto de visualização detalhada.
- Foco no cursor para zoom (scroll/double-click):
  - Melhora precisão e UX em inspeção de detalhes.
- Translate antes de scale no CSS transform:
  - Garante estabilidade do pan em níveis altos de zoom.

---

## 📌 Boas Práticas Adotadas

- Código minimamente acoplado e reutilizável (helpers locais e hooks dedicados)
- Padrões visuais coerentes (spinner, botões, cores)
- Cleanup rigoroso de listeners e timers
- Logs úteis em desenvolvimento e tolerância a falhas do storage

---

## 📚 Referências de Código (principais)

- components/ui/ImageGallery.js
- components/ui/ComponentProfileImage.js
- components/forms/budgetforms/ComponentBudgetTitle.js
- components/forms/budgetforms/ForgeBudgetForm.js
- components/forms/uploads/UploadField.js (remoção do botão de perfil)
- hooks/useProfileImageFromStorage.js
- lib/uploadManager.js

---

## ✅ Resultado

- Sistema de imagens para orçamento com perfil consistente, UX moderna na galeria e persistência robusta.
- Manutenção simplificada: responsabilidades claras entre componentes, hooks e persistência.




---

## 🔒 Segurança e Backend (End‑to‑End)

- URL de imagem gerada centralmente por ::getImageUrl:: com preferência por token curto `it=` (tempo de vida curto, payload com binding ao item) e fallbacks controlados.
- Endpoint backend `/api/image/[oneDriveItemId]` com autenticação flexível (cookie, Bearer, `it=`), streaming do binário e headers seguros (nosniff, no-referrer, cache adequado).
- Emissor `/api/image-token` para token curto vinculado ao item (`oni`) e ao utilizador (`sub`).

Benefícios:
- Menor exposição de credenciais, melhor cacheabilidade e performance (streaming), e compatibilidade com `<img>` sem Origin/cookies.

---

## 🪝 Hook useProfileImageFromStorage – detalhes

- Gera storageKey conforme UploadManager e lê dados do localStorage.
- Seleciona sliceImage elegível e resolve URL via ::getImageUrl:: (com cache local).
- Assina `uploadManager:filesUpdated` (mesma aba) e `storage` (cross‑tab) para atualização reativa.
- API do hook (principal):
  - `profileImageUrl`, `profileImageData`, `isLoading`, `error`, `refresh()`, `clearCache()`

---

## 🧊 ComponentProfileImage – interface e estados

Props principais:
- `imageUrl`, `storageContext`, `size`, `alt`, `componentTitle`, `showBorder`, `enableLogs`, `onImageLoad`, `onImageError`

Estados e comportamento:
- `imageState`: `loading` → `loaded` → `error/empty` (com skeleton wave padrão durante loading)
- Fallback com iniciais e ícone quando não há imagem.
- Integração com ImageGallery para seleção manual e visualização fullscreen.

---

## 🧭 Histórico e Evolução (consolidação)

- Primeiras versões focavam apenas na foto de perfil com fallback e skeletons padronizados.
- Evoluímos para um hook reativo (localStorage + eventos) e geração de URL centralizada com tokens curtos.
- Implementámos a visualização fullscreen com zoom multi‑nível, depois refinada para zoom direcional (scroll e double‑click) e pan mais estável.
- A ação “Definir como perfil” foi centralizada na galeria para melhor UX e menor acoplamento.

Lições aprendidas:
- Centralizar construção de URL e persistência reduz bugs de integração.
- Eventos são ideais para sincronizar remoções/adicionamentos entre UploadManager e UI.
- Translate antes de scale mantém pan estável em zoom alto.

---

## 📌 Casos de Uso (resumo consolidado)

1) Carregamento inicial: skeleton → imagem (se presente via storage/prop).
2) Upload/remover imagem: atualização automática via eventos e hook.
3) Troca de versão: storageKey distinta e recálculo da imagem de perfil.
4) Interação avançada: zoom direcional (scroll/double‑click), pan com limites, teclado e dots.

---

## 🔗 Referências adicionais

- Backend de imagem e tokens: documentação interna de APIs (ver codedocs/backend)
- Persistência do UploadManager: `frontend/libs/uploadManager-persistence-guide.md`

