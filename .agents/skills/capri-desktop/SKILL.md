---
name: capri-desktop
description: >-
  Comprehensive guide and architectural runbook for Capri Desktop (interactive Cyberpunk desktop companion
  for Antigravity, Claude Code, and Codex). Use this skill whenever inspecting, developing, extending,
  modifying shaders/visuals, editing dialogue lines, or configuring hooks for capri-desktop.
---

# Capri Desktop: Development & Architecture Guide

Capri Desktop is an open-source, interactive desktop companion (*desktop pet / construct*) inspired by *Cyberpunk: Edgerunners* (Project Capricorn). It runs as a full-screen, transparent, click-through overlay on Windows, reacting visually in real time to actions performed by AI coding assistants (**Antigravity CLI**, **Claude Code**, and **Codex**).

---

## 1. Technologies & Languages

| Domain | Technology / Library | Purpose |
| :--- | :--- | :--- |
| **Desktop Shell** | [Electron](https://www.electronjs.org/) (v44+) | Transparent fullscreen frameless window, system tray, global shortcuts, native OS integration. |
| **Animation & Rendering** | **WebGL (Custom Shaders)** + HTML5 Canvas | Cel-style animation (12–24 FPS), head tilt rigging, mane flaring, Relic glitch slices, chromatic aberration, smear frames. |
| **Audio** | **Web Audio API** | Pure live procedural sound synthesis (beeps, teleports, sparks, UI blips) — zero external copyright audio dependencies. |
| **Styling & Fonts** | CSS3 + `@fontsource/chakra-petch`, `@fontsource/jetbrains-mono` | Cyberpunk HUD, futuristic typography, pixel-perfect click-through masks. |
| **Window Tracking** | **PowerShell** (`windows.ps1`) | Windows API caller tracking active window bounding boxes so Capri can perch/sit on windows without reading screen content. |
| **IPC & Bridge** | **Node.js HTTP Server** (`127.0.0.1:47823`) | Fast, local, unauthenticated localhost bridge receiving lifecycle events from CLI hooks. |
| **Asset Pipeline** | **Python 3 + Pillow** (`tools/`) | Sprite slicing, cut-in frame extraction, and palette assembly. |
| **AI Chat & Models** | Multi-provider connector (`llm.js`, `ollama.js`) | Local Ollama integration (winget auto-installer), Gemini, Claude, OpenAI, Groq, DeepSeek, Pollinations. |
| **Packaging & Installer** | `electron-builder` (NSIS) | Compiles standalone Windows single-click installer (`Capri-Setup-x.y.z.exe`). |

---

## 2. Repository Structure

```
capri-desktop/
├── assets/                  # Sprites, cut-ins, sound overrides, icons
│   ├── capri/              # Sprite sheets, expressions, and cut-in frames
│   └── icons/              # App and tray icons (.ico, .png)
├── docs/                    # Screenshots, animation breakdowns, and guides
├── hooks/                   # CLI Event hook scripts
│   ├── capri-agy-hook.js   # ⭐ Antigravity CLI lifecycle hook
│   ├── capri-hook.js       # Claude Code lifecycle hook
│   └── capri-codex-hook.js # Codex lifecycle hook
├── scripts/                 # Setup and hook installation scripts
│   ├── install-hooks-agy.js# Installs hooks into ~/.gemini/config/hooks.json
│   ├── install-hooks.js    # Installs hooks into ~/.claude/settings.json
│   ├── install-codex-hooks.js # Installs hooks into ~/.codex/hooks.json
│   └── demo.js             # Standalone simulated demo session
├── src/
│   ├── main/               # Electron Main Process (Node.js runtime)
│   │   ├── main.js         # Window creation, tray, global keyboard shortcuts (Ctrl+Alt+C)
│   │   ├── bridge.js       # Local HTTP server on 127.0.0.1:47823 receiving hook POSTs
│   │   ├── windows.js/.ps1 # Windows bounding box tracker
│   │   ├── assistants.js   # Active assistant detection and switching
│   │   ├── config.js       # Encrypted configuration & persistent settings
│   │   ├── llm.js          # Chat API connectors (Gemini, OpenAI, Groq, Ollama)
│   │   └── ollama.js       # Local Ollama runner and model downloader
│   ├── renderer/           # Electron Renderer Process (Chromium WebGL/DOM)
│   │   ├── index.html      # Canvas root and DOM structure
│   │   ├── styles/capri.css# HUD styling, animations, fonts
│   │   └── js/
│   │       ├── app.js      # Bootstrap, IPC glue
│   │       ├── acting.js   # Hand-crafted exposure sheets (cel frame timings)
│   │       ├── brain.js    # Event interpreter (turns CLI events into reactions)
│   │       ├── capri.js    # Character state machine (sit, peek, float, sleep, fall)
│   │       ├── fx.js       # Particle effects, lightning bolts, shockwaves, impact frames
│   │       ├── sprite.js   # WebGL shaders and 2D mesh manipulation
│   │       ├── panel.js    # Action ticker and assistant response reader HUD
│   │       ├── chat.js     # "Talk to her" dialogue interface
│   │       ├── lines.js    # Localized dialogue text (PT-BR, EN, FR, ES, RU)
│   │       ├── chip.js     # Vector mask rendered during sleep or minimized state
│   │       └── voice.js    # Web Audio sound synthesizers
│   └── preload.js          # Secure context bridge between Main and Renderer
├── tests/                  # Unit and integration tests (node:test)
│   └── hooks.test.js       # Validates hook payloads and bridge communication
└── tools/                  # Python asset generation pipelines
    ├── build-sprite.py     # Rebuilds main sprite from cut-out
    ├── build-cutins.py     # Generates anime cut-in frames
    └── build-intro.py      # Generates intro frame assets
```

---

## 3. How the Antigravity Integration Works

Antigravity uses the standard **Antigravity Customization Hook System** via `~/.gemini/config/hooks.json`.

### Event Flow:
```
[ Antigravity CLI ]
        │  (SessionStart, PreInvocation, PreToolUse, PostToolUse, Stop)
        ▼
[ hooks/capri-agy-hook.js ]
        │  (Translates payload, maps tools, guarantees exit 0 in <2s)
        ▼  HTTP POST http://127.0.0.1:47823/event
[ src/main/bridge.js ]
        │  IPC: bridge:event
        ▼
[ src/renderer/js/brain.js ]
        │
   ┌────┴──────────────────────────┐
   ▼                               ▼
[ Ticker & HUD ]             [ Character Animation ]
(EDITS, RUNS, READS)         (Sparks, Teleport, Shockwave, Sit)
```

### Tool Mapping in `capri-agy-hook.js`:
- `read_file` / `view_file` ➔ Mapped to `Read` (Ticker shows `READS <path>`).
- `write_file` / `edit_file` ➔ Mapped to `Write` / `Edit` (Ticker shows `EDITS <path>`).
- `run_command` ➔ Mapped to `PowerShell` (Triggers finger sparks, window edge lightning, and permission alert).
- `ask_question` ➔ Mapped to `AskUserQuestion` (Triggers urgent cursor teleport and window pointing).
- `search_web` / `read_url_content` ➔ Mapped to `WebSearch` / `WebFetch`.
- `invoke_subagent` ➔ Mapped to `Agent` (Triggers SubagentStart / SubagentStop animations).
- `Stop` ➔ Triggers victory sequence, mission stats (`X actions · Y files · Z time`), and assistant output display.

---

## 4. Key Workflows & Commands

### Setup & Local Execution
```powershell
# 1. Install dependencies
npm install

# 2. Start Capri in normal mode
npm start

# 3. Start Capri in developer mode (enables debug routes and console inspection)
npm run dev
```

### Managing Antigravity Hooks
```powershell
# Check installation status
node scripts/install-hooks-agy.js --status

# Install hooks into ~/.gemini/config/hooks.json
npm run hooks:agy:install

# Remove hooks
npm run hooks:agy:uninstall
```

### Running Tests and Demos
```powershell
# Run the built-in test suite
npm run test:hooks

# Run interactive showcase demo in Portuguese
npm run demo -- pt

# Run interactive demo in English
npm run demo -- en
```

### Building the Windows Installer
```powershell
npm run dist
```
Outputs the standalone `Capri-Setup-<version>.exe` inside the `dist/` folder.

---

## 5. Enhancement & Customization Runbook

### A. Adding Custom Reactions to Antigravity Tools (e.g. MCP Tools)
1. Open [`hooks/capri-agy-hook.js`](file:///C:/Users/TZone/Documents/Projects/Capri/hooks/capri-agy-hook.js).
2. Inside `mapTool(toolCall)`, add a case for your custom MCP tool or action:
   ```javascript
   case "mcp_kaneo_create_task":
     return {
       tool_name: "Kaneo",
       tool_input: { description: "Creating task in Kaneo" }
     };
   ```
3. Open [`src/renderer/js/brain.js`](file:///C:/Users/TZone/Documents/Projects/Capri/src/renderer/js/brain.js) to customize the reaction, ticker phrase, or trigger special animations.

### B. Customizing Dialogue & Personality (PT-BR)
1. Open [`src/renderer/js/lines.js`](file:///C:/Users/TZone/Documents/Projects/Capri/src/renderer/js/lines.js).
2. Locate the `pt` section.
3. Edit existing lines or add new contextual voice lines for task completion, errors, thinking pauses, or idle clicks.

### C. Adjusting Visuals & Shaders
1. **WebGL Shader logic**: [`src/renderer/js/sprite.js`](file:///C:/Users/TZone/Documents/Projects/Capri/src/renderer/js/sprite.js) (modifies lighting, colors, chromatic aberration, mane flares).
2. **Animation timing & poses**: [`src/renderer/js/acting.js`](file:///C:/Users/TZone/Documents/Projects/Capri/src/renderer/js/acting.js) (exposure sheets, duration in frames).
3. **Special effects & particles**: [`src/renderer/js/fx.js`](file:///C:/Users/TZone/Documents/Projects/Capri/src/renderer/js/fx.js).

---

## 6. Git Synchronization (Fork Workflow)

The repository is configured with two remotes:
- `origin`: `git@github.com:TZoneDRKN/capri-desktop.git` (Your personal fork).
- `upstream`: `https://github.com/mochiiwuff/capri-desktop.git` (Original upstream repo).

```powershell
# Fetch updates from original upstream repository
git fetch upstream

# Rebase or merge upstream updates into your main branch
git merge upstream/main

# Push changes to your fork
git push origin main
```
