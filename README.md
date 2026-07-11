# Godot MCP Toolkit v3.0

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Godot](https://img.shields.io/badge/Godot-4.4%2B-blue.svg)](https://godotengine.org)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green.svg)](https://nodejs.org)

**55+ tools** for AI-assisted Godot game development. Works with Claude, Cursor, Cline, opencode, and any MCP-compatible client.

## Features

| Category | Tools | Description |
|----------|-------|-------------|
| **Scene** | 7 | Create/edit scenes, add/remove nodes, load sprites, save, compare |
| **Script** | 8 | Read/write/analyze GDScript, create from templates, refactor, find references |
| **Project** | 7 | Settings, scene tree, validate, list projects/scenes, analyze dependencies |
| **Asset** | 3 | Import textures, models, audio |
| **UID** | 2 | Get/regenerate resource UIDs |
| **Signal** | 6 | Connect/disconnect/list/emit signals, analyze flow |
| **Performance** | 6 | Profile scenes/scripts, analyze memory, detect bottlenecks |
| **Shader** | 6 | Edit/create/optimize shaders and materials |
| **Animation** | 8 | Create/edit/animate, tracks, keyframes, export |
| **Export** | 4 | MeshLibrary, export presets, quick/full testing |
| **System** | 6 | Version, status, launch editor, run/stop project, debug output |

## Quick Start

### 1. Clone & Configure

```bash
git clone https://github.com/DuskHound/godot-mcp-toolkit.git
cd godot-mcp-toolkit
```

### 2. Copy to Your Godot Project

```bash
cp -r src/addons/godot_mcp /path/to/your/godot/project/addons/
```

### 3. Configure MCP Client

Add to your MCP client config (`.mcp.json` or Claude Desktop settings):

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": ["path/to/godot-mcp-toolkit/src/mcp/godot_mcp.js"],
      "env": {
        "GODOT_PATH": "C:\\Path\\To\\Godot.exe",
        "PROJECT_PATH": "C:\\Path\\To\\Your\\Godot\\Project"
      }
    }
  }
}
```

## Tool Reference

### Scene
| Tool | Description |
|------|-------------|
| `create_scene` | Create scene with root node type |
| `add_node` | Add child node with properties |
| `edit_node` | Edit node properties |
| `remove_node` | Remove a node |
| `load_sprite` | Load texture onto sprite |
| `save_scene` | Save scene to path |
| `compare_scenes` | Diff two scenes |

### Script
| Tool | Description |
|------|-------------|
| `read_script` | Read file (fast, static) |
| `edit_script` | Write/edit file |
| `create_script` | Create from template (node2d, characterbody2d, autoload, state_machine, etc.) |
| `list_scripts` | List all .gd files |
| `analyze_script` | Get metrics (functions, classes, signals) |
| `find_script_references` | Search symbol references project-wide |
| `refactor_rename` | Rename symbol in file |
| `refactor_extract_method` | Extract lines to new method |

### Project
| Tool | Description |
|------|-------------|
| `get_project_info` | Name, main scene, autoloads |
| `get_project_settings` | Full project.godot settings |
| `list_projects` | Find Godot projects in directory |
| `list_scenes` | List all .tscn files |
| `get_scene_tree` | Node hierarchy as JSON |
| `validate_project` | Check for missing files, broken autoloads |
| `analyze_dependencies` | Scene asset dependencies |

### Signals
| Tool | Description |
|------|-------------|
| `connect_signal` | Wire signal source→target |
| `disconnect_signal` | Remove signal connection |
| `list_signals` | List all signals in scene |
| `emit_signal` | Test-fire a signal |
| `get_signal_connections` | Map all connections |
| `analyze_signal_flow` | Signal flow graph |

### Performance
| Tool | Description |
|------|-------------|
| `profile_scene` | Node count, draw call estimate |
| `analyze_performance` | Project-wide perf scan |
| `get_performance_report` | Full report |
| `profile_script` | Script execution profile |
| `analyze_memory_usage` | Memory analysis |
| `detect_bottlenecks` | Find slow spots |

### Shaders & Materials
| Tool | Description |
|------|-------------|
| `edit_shader` | Edit .gdshader file |
| `create_material` | Create .tres material |
| `edit_material` | Set material properties |
| `list_shaders` | List all shaders |
| `create_shader` | New shader file |
| `optimize_shader` | Optimization suggestions |

### Animation
| Tool | Description |
|------|-------------|
| `create_animation` | New animation |
| `edit_animation` | Edit animation params |
| `list_animations` | List animations |
| `create_animation_library` | New library |
| `add_animation_track` | Add track |
| `edit_keyframe` | Edit keyframe data |
| `play_animation` | Preview animation |
| `export_animation` | Export animation data |

### Export & Test
| Tool | Description |
|------|-------------|
| `export_mesh_library` | Scene→MeshLibrary |
| `get_export_presets` | List presets |
| `quick_test` | 10s headless test |
| `full_test` | 60s comprehensive test |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GODOT_PATH` | Path to Godot executable | Auto-detect |
| `PROJECT_PATH` | Path to Godot project | Current directory |
| `DEBUG` | Enable debug logging | `false` |
| `READ_ONLY_MODE` | Analysis only, no writes | `false` |

## Architecture

```
AI Client (Claude, Cursor, opencode)
  ↕ stdio (MCP protocol)
Node.js MCP Server (godot_mcp.js)
  ↕ headless Godot spawn
GDScript Operations (godot_operations.gd)
  ↕ Godot Engine API
Your Project
```

## Security

- Path traversal protection
- Input sanitization (null bytes, special chars)
- Node type whitelist
- Read-only mode for CI/CD
- Bounded output buffers
- Process lifecycle management

## License

MIT

---

Made by DuskHound for the Godot community.
