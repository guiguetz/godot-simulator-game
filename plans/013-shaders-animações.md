# 013 — Shaders e animações visuais

- **Status:** Proposto
- **Prioridade:** Alta
- **Esforço:** G (semana+)
- **Depende de:** —
- **Arquivos-alvo:** `shaders/` (novo diretório), `scripts/` (diversos), `docs/shaders.md` (novo)

## Objetivo

Dar vida ao mundo com shaders e animações visuais: água fluindo, árvores
balançando ao vento, ciclo dia/noite atmosférico, efeitos de clima em GPU e
feedback visual nos NPCs.

## Motivação / Contexto

O jogo hoje tem:
- **Dia/noite:** `CanvasModulate` com lerp de cor (2 linhas de lógica).
- **Chuva:** overlay desenhado em CPU com `_draw()` (linhas + texturas).
- **Água:** tile estático, sem animação.
- **Árvores/vegetação:** tiles estáticos, sem vida.
- **NPCs:** `AnimatedSprite2D` com walk/idle, sem efeitos visuais.
- **Sem nenhum shader** no projeto (zero `.gdshader`).

Para um farming sim, a atmosfera é tão importante quanto a mecânica. Shaders
em GPU são mais performáticos que `_draw()` e permitem efeitos impossíveis em
CPU (ripple, distorção, iluminação per-pixel).

## Design técnico geral

- **Diretório:** `shaders/` na raiz, com subpastas por categoria.
- **Convenção:** cada shader `.gdshader` + um `.tres` ShaderMaterial preset.
- **Parâmetros globais:** uniforms setados por um `ShaderGlobalsManager`
  (autoload) que lê `TimeManager` e `Weather`:
  - `time_of_day` (float 0-1)
  - `wind_strength` (float 0-1)
  - `wind_direction` (vec2)
  - `rain_intensity` (float 0-1)
  - `season` (int 0-3)
- **Performance:** todos os shaders rodam em GPU; evitar `texture()` em
  loops grandes. Usar `hint_range` para facilitar tuning no editor.

---

## Sub-tarefa 13.1 — Água (tiles e corpos d'água)

**Prioridade:** Alta · **Esforço:** P (horas)

### Objetivo

Tiles de água têm ondulação, fluxo visual e reflexo sutil.

### Comportamento esperado

- Superfície da água ondula suavemente (ripple contínuo).
- Correnteza em rios (tiles com direção) têm fluxo visível.
- Reflexo de objetos próximos (simplificado, via distorção).
- Cor da água muda com dia/noite (mais escura à noite).
- Chuva cria respingos na superfície (integração com 13.4).

### Design técnico

- **Shader:** `shaders/water.gdshader` — noise-based ripple + scroll UV.
  ```glsl
  uniform sampler2D noise_texture;  // noise simplex/perlin
  uniform float ripple_speed = 0.5;
  uniform float ripple_strength = 0.02;
  uniform float flow_speed = 0.3;
  uniform vec2 flow_direction = vec2(1.0, 0.0);
  uniform float time_of_day = 1.0;  // setado pelo ShaderGlobalsManager
  ```
- **Aplicação:** o TileMap da água usa `ShaderMaterial` no tileset ou na
  camada de água.
- **Noise:** textura de noise simplex em `assets/shaders/noise_simplex.png`
  (pré-gerada ou via `FastNoiseLite` no editor).
- **Dia/noite:** multiplicar cor base por `mix(night_tint, day_tint, time_of_day)`.

### Tarefas

- [ ] Criar `shaders/water.gdshader` com ripple + flow
- [ ] Gerar noise texture em `assets/shaders/`
- [ ] Aplicar ShaderMaterial no tileset de água
- [ ] Integrar parâmetro `time_of_day` para cor
- [ ] Parâmetros tunáveis no editor (`@export` no material)

### Critérios de aceite

- [ ] Água ondula continuamente sem repetição óbvia.
- [ ] Fluxo é visível em tiles de rio.
- [ ] Cor da água é mais escura à noite.

---

## Sub-tarefa 13.2 — Vegetação (árvores, grama, plantas)

**Prioridade:** Alta · **Esforço:** P (horas)

### Objetivo

Árvores, arbustos e grama balançam com o vento; plantações têm feedback de
crescimento.

### Comportamento esperado

- Árvores balançam suavemente com o vento (tronco estático, copa se move).
- Grama/bushes balançam mais que árvores (mais leves).
- Força do balanço varia: calmo → ventania (integrar com `Weather`).
- Chuva intensifica o balanço.
- Plantações recém-plantadas têm "pop" de crescimento (scale ease-in).
- Estações mudam a cor da vegetação (verde → amarelo → marrom).

### Design técnico

- **Shader:** `shaders/vegetation.gdshader` — vertex displacement baseado
  em posição Y (só a copa balança) + noise para variação.
  ```glsl
  uniform float wind_strength = 0.3;
  uniform vec2 wind_direction = vec2(1.0, 0.3);
  uniform float sway_amount = 0.04;  // pixels de deslocamento
  uniform float sway_speed = 1.5;
  uniform vec3 season_tint = vec3(1.0);  // multiplicador de cor
  uniform sampler2D noise_texture;
  ```
- **Aplicação:** `ShaderMaterial` nos sprites de árvores/arbustos. Para
  tiles de grama, aplicar na camada do TileMap.
- **Crescimento de plantas:** uniform `growth` (0-1) controla scale Y e
  alpha com easing.
- **Estações:** `season_tint` setado pelo `ShaderGlobalsManager`:
  - Primavera: `vec3(0.85, 1.0, 0.85)` (verde claro)
  - Verão: `vec3(1.0)` (normal)
  - Outono: `vec3(1.0, 0.85, 0.6)` (amarelo/marrom)
  - Inverno: `vec3(0.8, 0.85, 0.9)` (acinzentado)

### Tarefas

- [ ] Criar `shaders/vegetation.gdshader` com sway + season tint
- [ ] Criar `shaders/crop_growth.gdshader` com pop de crescimento
- [ ] Aplicar em árvores e arbustos do mapa
- [ ] Integrar `wind_strength` com Weather (mais forte na chuva)
- [ ] Integrar `season_tint` com TimeManager (futuro: estações)
- [ ] Parâmetros tunáveis por tipo de planta (árvore vs grama)

### Critérios de aceite

- [ ] Árvores balançam suavemente, copa se move mas tronco não.
- [ ] Grama balança mais que árvores.
- [ ] Chuva intensifica o balanço visivelmente.
- [ ] Plantação recém-plantada tem animação de crescimento.

---

## Sub-tarefa 13.3 — Ciclo dia/noite (atmosfera e iluminação)

**Prioridade:** Alta · **Esforço:** P (horas)

### Objetivo

Transição dia/noite é atmosférica: color grading, vignette, luzes artificiais
à noite, céu gradiente.

### Comportamento esperado

- Manhã: tons quentes (laranja/dourado), transição suave.
- Meio-dia: cores normais (neutro).
- Tarde: tons quentes novamente (pôr do sol).
- Noite: azul escuro, vignette escuro nas bordas, estrelas.
- Luzes artificiais (janelas de casas, tochas) brilham à noite.
- Transições são suaves, sem "snap" de cor.

### Design técnico

- **Shader:** `shaders/day_night.gdshader` — post-processing no
  `CanvasLayer` com `ColorRect` fullscreen.
  ```glsl
  uniform float time_of_day = 0.5;  // 0=meia-noite, 0.5=meio-dia, 1=meia-noite
  uniform sampler2D gradient_texture;  // textura 1D com a paleta do dia
  uniform float vignette_strength = 0.3;
  uniform float saturation = 1.0;
  ```
- **Gradient:** textura 1D (`gradient_day_night.tres`) mapeia hora → cor.
  Amostra: noite(azul escuro) → manhã(laranja) → dia(branco) →
  tarde(laranja) → noite(azul escuro).
- **Vignette:** multiplicar bordas da tela por máscara radial.
- **Luzes artificiais:** `PointLight2D` em casas/tochas, alpha controlado
  por `time_of_day` (aparece à noite).
- **Substitui** o `CanvasModulate` atual por este shader mais rico.

### Tarefas

- [ ] Criar `shaders/day_night.gdshader` com color grading + vignette
- [ ] Criar gradiente 1D (`assets/shaders/gradient_day_night.tres`)
- [ ] Criar `DayNightOverlay` (ColorRect + shader) como substituto do CanvasModulate
- [ ] Adicionar PointLight2D em casas e tochas do mapa
- [ ] Integrar `time_of_day` do TimeManager como uniform
- [ ] Tunar transições (manhã/tarde mais longas, noite mais curta)
- [ ] Remover `day_night.gd` antigo (CanvasModulate)

### Critérios de aceite

- [ ] Transição de cor é suave e contínua ao longo do dia.
- [ ] Vignette aparece à noite e some de dia.
- [ ] Luzes artificiais brilham à noite e apagam de dia.
- [ ] Manhã e tarde têm tons quentes visíveis.

---

## Sub-tarefa 13.4 — Clima (chuva, neblina, neve futura)

**Prioridade:** Média · **Esforço:** M (dias)

### Objetivo

Efeitos de clima em GPU: chuva mais bonita, neblina atmosférica, preparo
para neve.

### Comportamento esperado

- Chuva com shader: gotas mais naturais, distorção na tela, splash em
  superfícies (especialmente água — integração com 13.1).
- Neblina leve em manhãs frias ou perto da água.
- Tela fica levemente mais saturada/contraste na chuva.
- Pára-quedas: respingos na câmera (lentes molhadas) em chuva forte.
- Preparo para neve (futuro): partículas + shader de acúmulo.

### Design técnico

- **Shader:** `shaders/rain.gdshader` — substitui o `_draw()` de `rain.gd`.
  ```glsl
  uniform float intensity = 1.0;
  uniform float drop_length = 8.0;
  uniform float drop_speed = 300.0;
  uniform float splash_strength = 0.5;
  uniform vec4 drop_color = vec4(0.72, 0.82, 1.0, 0.45);
  uniform sampler2D noise_texture;  // para variação de posição
  ```
- **Aplicação:** `ColorRect` fullscreen em CanvasLayer, como o overlay
  atual mas em GPU.
- **Neblina:** `shaders/fog.gdshader` — noise scrolling horizontal,
  alpha baixo, aplicado em camada atrás do player.
- **Integração:** `RainShaderController` gerencia uniforms do shader
  baseado em `Weather.rain_intensity`.
- **Distorção:** leve distorção de tela na chuva (displacement map sutil).

### Tarefas

- [ ] Criar `shaders/rain.gdshader` com gotas, splash e distorção
- [ ] Criar `shaders/fog.gdshader` com neblina scrolling
- [ ] Substituir `rain.gd` (_draw) pelo shader de chuva
- [ ] Criar `RainShaderController` para gerenciar uniforms
- [ ] Integrar splash com tiles de água (13.1)
- [ ] Tunar intensidade por força da chuva
- [ ] (Futuro) Preparar estrutura para shader de neve

### Critérios de aceite

- [ ] Chuva em shader é mais bonita e performática que _draw().
- [ ] Splash aparece na superfície da água.
- [ ] Neblina é visível em manhãs ou perto da água.
- [ ] Distorção sutil na tela durante chuva forte.

---

## Sub-tarefa 13.5 — NPCs (outline, dano, sombra)

**Prioridade:** Média · **Esforço:** P (horas)

### Objetivo

NPCs e player têm feedback visual: outline ao interagir, flash de dano,
sombra dinâmica.

### Comportamento esperado

- Quando player está perto de NPC interagível → outline branco no sprite.
- Quando NPC/player recebe dano → flash vermelho por ~0.2s.
- Sombra simples sob cada personagem (ellipse escuro).
- Outline pulsante sutil em NPCs com quest disponível (futuro).
- Inimigos ficam vermelhos brevemente ao serem atingidos (integração 011).

### Design técnico

- **Shader:** `shaders/character.gdshader` — outline + flash + tint.
  ```glsl
  uniform bool outline_enabled = false;
  uniform vec4 outline_color = vec4(1.0, 1.0, 1.0, 1.0);
  uniform float outline_thickness = 1.0;
  uniform float flash_intensity = 0.0;  // 0=normal, 1=totally red
  uniform vec4 flash_color = vec4(1.0, 0.0, 0.0, 1.0);
  uniform float shadow_alpha = 0.3;
  ```
- **Aplicação:** `ShaderMaterial` nos `AnimatedSprite2D` de NPCs e player.
  Sombra como sprite separado (ellipse) ou via shader no chão.
- **Outline:** sample pixels vizinhos; se pixel atual é transparente mas
  vizinho não é → desenha outline.
- **Flash:** misturar cor do pixel com `flash_color` por `flash_intensity`.
- **Integração:** `NPCInteraction` seta `outline_enabled = true` quando
  player entra na área de interação. Combat seta `flash_intensity` via
  tween.

### Tarefas

- [ ] Criar `shaders/character.gdshader` com outline + flash
- [ ] Aplicar no AnimatedSprite2D do player e NPCs
- [ ] Criar `InteractionHighlight` que gerencia outline por proximidade
- [ ] Integrar flash com sistema de combate (plano 011)
- [ ] Adicionar sombra simples (ellipse sob o sprite)
- [ ] Tunar espessura e cor do outline

### Critérios de aceite

- [ ] Outline branco aparece quando player está perto de NPC.
- [ ] Flash vermelho aparece ao receber dano e desaparece em ~0.2s.
- [ ] Sombra é visível sob player e NPCs.
- [ ] Shader não afeta performance (mantém 60fps).

---

## Sub-tarefa 13.6 — ShaderGlobalsManager (infraestrutura)

**Prioridade:** Alta · **Esforço:** P (horas)

### Objetivo

Autoload central que seta uniforms globais dos shaders a cada frame.

### Comportamento esperado

- Todos os shaders leem de variáveis globais em vez de cada um setar
  individualmente.
- Mudança de hora → todos os shaders atualizam automaticamente.
- Mudança de clima → shaders de chuva/vento reagem.

### Design técnico

- **Autoload:** `ShaderGlobalsManager` (res://scripts/shader_globals.gd)
- **A cada frame** (ou a cada sinal de `TimeManager.time_changed`):
  ```gdscript
  RenderingServer.global_shader_parameter_set("time_of_day", TimeManager.daylight())
  RenderingServer.global_shader_parameter_set("wind_strength", _wind)
  RenderingServer.global_shader_parameter_set("wind_direction", Vector2(1, 0.3))
  RenderingServer.global_shader_parameter_set("rain_intensity", _rain)
  RenderingServer.global_shader_parameter_set("season", _season)
  ```
- **Registrar** no Project Settings > Globals > Shader Parameters.
- **Sinais:** conectar em `TimeManager.time_changed` e `Weather.changed`.

### Tarefas

- [ ] Criar `scripts/shader_globals.gd` como autoload
- [ ] Registrar parâmetros globais no Project Settings
- [ ] Conectar sinais do TimeManager e Weather
- [ ] Documentar em `docs/shaders.md`

### Critérios de aceite

- [ ] Mudar `time_of_day` no autoload atualiza todos os shaders.
- [ ] Parâmetros são visíveis no Project Settings > Globals.

---

## Escopo geral

- **Incluído:** todos os shaders acima, ShaderGlobalsManager, substituição
  do day_night.gd e rain.gd atuais, documentação.
- **Fora do escopo:** shaders de neve/acúmulo (futuro), pós-processamento
  avançado (bloom, CRT), shader de câmera (shake, zoom).

## Ordem de implementação

1. **13.6** — ShaderGlobalsManager (infraestrutura, sem ela os outros não funcionam)
2. **13.1** — Água (efeito mais impactante visualmente)
3. **13.2** — Vegetação (segundo mais impactante)
4. **13.3** — Dia/noite (melhora atmosfera drasticamente)
5. **13.5** — NPCs (outline e dano, necessário para combate)
6. **13.4** — Clima (chuva em GPU, mais complexo)

## Riscos / Notas

- **Compatibilidade:** shaders GLES3/WebGL — Godot 4.6 usa Vulkan por
  padrão, mas shaders são compatíveis com fallback. Testar em WebGL se
  exportar para web.
- **Performance em hardware fraco:** shaders com muitas texturas podem
  ser pesados. Mitigar: parâmetros de qualidade (low/medium/high).
- **Complexidade:** é o plano mais visual do projeto — requer tuning
  iterativo. Reserve tempo para ajustar parâmetros no editor.
- **Breaking change:** substituir `day_night.gd` e `rain.gd` pode
  quebrar referências. Mitigar: manter API pública dos autoloads
  (`Weather.is_raining()`, `TimeManager.daylight()`).