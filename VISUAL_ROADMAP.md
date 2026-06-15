# 🌌 Horizon Notes Visual Roadmap

> **Legend:**
> 🟩 **Solid Green:** Built & Deployed
> 🟨 **Solid Yellow:** Active / In Progress
> 🟥 **Solid Red:** Known Bug / Blocked
> ⬛ **Dashed Gray:** Planned Future Feature

### 🗺️ The Architecture Board

```mermaid
graph TD
    %% Styling Classes
    classDef built fill:#1e4620,stroke:#4caf50,stroke-width:2px,color:#fff;
    classDef active fill:#4a3b00,stroke:#ffb300,stroke-width:2px,color:#fff;
    classDef bug fill:#4a0000,stroke:#ff5252,stroke-width:2px,color:#fff;
    classDef planned fill:#1e1e1e,stroke:#757575,stroke-width:2px,stroke-dasharray: 5 5,color:#fff;

    %% Top Level Data
    subgraph Data["💾 Persistence & State"]
        Hive["Hive Local Database (Adapters & Gen)"]:::built
        Workspace["Workspace Controller"]:::built
        Export["Export Engine (PDF / PNG / SVG)"]:::built
        UndoRedo["Undo & Redo Action Stack"]:::built
        TrashSystem["Soft-Delete & Trash System"]:::built
    end

    %% HUD / UI
    subgraph HUD["🖥️ UI & HUD"]
        Toolbar["Drawing Toolbar & Color Picker"]:::built
        Layers["Layers Panel (Z-Index Mgmt)"]:::built
        Scenes["Scenes & Bookmarks Panel (Slideshow)"]:::built
        Minimap["Viewport Minimap"]:::built
        RenameUI["Inline Renaming UX"]:::built
    end

    %% Core Engine
    subgraph Core["🧠 Core Engine"]
        Engine["⚙️ 2.5D Canvas Controller"]:::built
        Math["🧮 Geometry Interpolation"]:::built
        Performance["⚡ Performance Optimizations"]:::built
    end

    %% Tools & Selection
    subgraph Tools["🖌️ Interactive Tools"]
        Pens["Ink Pen, Normal Pen, Highlighter"]:::built
        Eraser["Pixel Eraser"]:::built
        Selection["Lasso Selection"]:::built
        BoundingBox["Bounding Box Transform (Scale, Rotate, Translate)"]:::built
        DirectDrag["Direct Object Dragging (No Lasso)"]:::built
    end

    %% Nodes
    subgraph Nodes["📦 Canvas Objects"]
        TextNode["Text Nodes (Editable TextField)"]:::built
        ImageNode["Image Nodes"]:::built
        DocNode["Document Nodes"]:::built
        Connectors["Node Connectors"]:::built
    end

    %% Viewport
    subgraph Viewport["🎥 Viewport"]
        Camera["Infinite Pan & Zoom (InteractiveViewer)"]:::built
        Background["Dynamic Background Patterns (Grid/Dots)"]:::built
    end

    %% Relations
    Data --> Core
    HUD --> Core
    Core --> Tools
    Core --> Nodes
    Core --> Viewport
    
    %% Detail Expansions
    Math --> Catmull["Catmull-Rom Splines<br>(Smooths sparse Ink Pen data)"]:::built
    Math --> QuadBezier["Quadratic Bezier Curves<br>(Flawless Normal Pen geometry)"]:::built
    
    Performance --> RDP["RDP Simplification<br>(Compresses tape/highlighter lines)"]:::built
    Performance --> AXTreeFix["RepaintBoundary Firewall<br>(Isolates CustomPaint crashes)"]:::built

    %% Future
    subgraph Roadmap["🔮 Future Expansion"]
        Extrusion["Pseudo 3D Extrusion<br>(Phase 2 Depth)"]:::planned
        Sync["Multiplayer Sync Engine"]:::planned
        AI["Local AI (Ollama) Integration"]:::planned
        MobileFit["Mobile UI Responsiveness & Layout"]:::planned
    end
    
    %% Bugs
    subgraph Issues["🪲 Known Issues"]
        AXSpam["ui::AXTree Windows Console Spam<br>(Harmless Flutter Engine Bug)"]:::built
    end

    Core -.-> Roadmap
```

### 🧠 Architectural Ledger (The 'Why')

If you forget why a system exists, click here to read its documentation:

- [Developer Handoff Guide](file:///c:/Users/Silver/Downloads/silver-os/50_IDEAS/Apps/Horizon_Notes/06_Architecture/Developer_Handoff.md) - Primary guide for code takeover, skeuomorphic theme parameters, and codebase checkpoints.
- [Architectural History](file:///c:/Users/Silver/Downloads/silver-os/50_IDEAS/Apps/Horizon_Notes/05_Session_Logs/HISTORY.md) - Chronological log of design pivots, engine selections, and system upgrades.
- [Phase 1: RDP Simplification](file:///c:/Users/Silver/Downloads/silver-os/50_IDEAS/Apps/Horizon_Notes/06_Architecture/2.5D_Canvas_Engine/Phase_1_RDP_Simplification.md) - Explains why we compress points from the highlighter tool to save RAM.
- [Phase 2: Pseudo 3D Extrusion](file:///c:/Users/Silver/Downloads/silver-os/50_IDEAS/Apps/Horizon_Notes/06_Architecture/2.5D_Canvas_Engine/Phase_2_Pseudo_3D_Extrusion.md) - The upcoming 3D tilt feature.
- **Catmull-Rom Interpolation (Ink Pen)** - Implemented to inject mathematical coordinates between sparse desktop mouse polling events, preventing jagged edges when drawing quickly without a stylus.
- **Quadratic Bezier Splines (Normal Pen)** - Implemented to bypass the complex polygon engine entirely for uniform pens, resulting in mathematically flawless curves regardless of hardware.
- **Undo / Redo System** - Implemented a memory-efficient action state stack storing canvas stroke, image, text, and connector deltas (capped at 50 steps) to allow error-free exploration.
- **Trash & Soft-Delete System** - Protects user data by adding an `isTrashed` flag to Hive models and displaying a dedicated Trash tab, preventing permanent deletion until requested.

*(This file will serve as your permanent visual anchor. Whenever we start a new feature or fix a bug, we will update this Mermaid diagram first so you can visually see the empire growing.)*
