# Godot MCP Server

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Godot](https://img.shields.io/badge/Godot-4.4%2B-blue.svg)](https://godotengine.org)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green.svg)](https://nodejs.org)

A comprehensive Model Context Protocol (MCP) server for seamless AI assistant integration with the Godot game engine.

## Features

- **Project Management**: Launch editor, run projects, capture debug output
- **Scene Operations**: Create, edit, add/remove nodes, load textures
- **Runtime Testing**: Headless and windowed testing with error analysis
- **UID Management**: Get and update resource UIDs (Godot 4.4+)
- **Project Analysis**: Validate projects, analyze structure, list resources
- **Script Operations**: Read scripts, list project scripts
- **Cross-Platform**: Works on Windows, macOS, and Linux

## Compatibility

| Component | Version |
|-----------|---------|
| Godot | 4.4+ (some features work with 3.5+) |
| Node.js | 18.0.0+ |
| AI Platforms | Claude, Cursor, Cline, VS Code MCP extensions |

## Quick Start

### 1. Installation

Copy the files to your Godot project:

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/godot-mcp.git

# Copy to your project
cp -r godot-mcp/src/* your-godot-project/
```

Or download and extract manually.

### 2. Configuration

Add to your Claude Desktop MCP settings (`~/.claude/mcp_servers.json` or project `.claude/mcp_servers.json`):

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["mcp/godot_mcp.js"],
      "cwd": "PATH_TO_YOUR_GODOT_PROJECT",
      "env": {
        "GODOT_PATH": "PATH_TO_GODOT_EXECUTABLE",
        "PROJECT_PATH": "PATH_TO_YOUR_GODOT_PROJECT"
      }
    }
  }
}
```

### 3. Start Using

Once configured, your AI assistant can use commands like:
- "Run a quick test on my Godot project"
- "Create a new scene called player.tscn"
- "Add a Sprite2D node to the player scene"
- "Get project information"

## Available Tools

### System Tools
| Tool | Description |
|------|-------------|
| `godot_version` | Get installed Godot version |
| `godot_status` | Get MCP server status and configuration |

### Project Tools
| Tool | Description |
|------|-------------|
| `launch_editor` | Launch Godot editor for the project |
| `run_project` | Run project with output capture |
| `stop_project` | Stop running project |
| `get_debug_output` | Get captured debug output |
| `list_projects` | List Godot projects in directory |
| `get_project_info` | Get project metadata (name, main scene, autoloads) |
| `analyze_project` | Analyze project structure (scripts, scenes, resources) |

### Scene Tools
| Tool | Description |
|------|-------------|
| `create_scene` | Create new scene with specified root node type |
| `add_node` | Add node to existing scene |
| `edit_node` | Edit node properties |
| `remove_node` | Remove node from scene |
| `load_sprite` | Load texture into Sprite2D/Sprite3D node |
| `save_scene` | Save scene (optionally to new path) |

### UID Tools (Godot 4.4+)
| Tool | Description |
|------|-------------|
| `get_uid` | Get UID for resource file |
| `update_project_uids` | Update all project UID references |

### Testing Tools
| Tool | Description |
|------|-------------|
| `quick_test` | 10-second headless test with error report |
| `full_test` | 60-second comprehensive test with analysis |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GODOT_PATH` | Path to Godot executable | Auto-detect common locations |
| `PROJECT_PATH` | Path to Godot project | Current directory |
| `DEBUG` | Enable debug logging (`true`/`false`) | `false` |
| `READ_ONLY_MODE` | Restrict to analysis operations | `false` |

## Project Structure

```
godot-mcp/
├── README.md              # This file
├── LICENSE                # MIT License
├── package.json           # Node.js package configuration
│
├── src/                   # Source files to copy to your project
│   ├── mcp/
│   │   └── godot_mcp.js   # Main MCP server (Node.js)
│   │
│   └── addons/
│       └── godot_mcp/
│           └── godot_operations.gd  # GDScript operations
│
└── examples/              # Example configurations
    └── mcp_servers.json   # Example Claude configuration
```

## GDScript Operations

The server uses `godot_operations.gd` for complex Godot operations. It's executed via headless Godot and supports:

**Scene Operations:**
- `create_scene` - Create new scene files
- `add_node` - Add nodes with properties
- `edit_node` - Modify node properties
- `remove_node` - Remove nodes
- `load_sprite` - Load textures
- `save_scene` - Save scene files

**Resource Operations:**
- `export_mesh_library` - Export 3D scenes as MeshLibrary

**Project Operations:**
- `get_project_settings` - Read project.godot settings
- `get_scene_tree` - Get scene node hierarchy
- `list_scenes` - List all .tscn files
- `list_scripts` - List all .gd files
- `validate_project` - Check for common issues

**UID Operations:**
- `get_uid` - Read .uid files
- `resave_resources` - Regenerate UIDs

## Read-Only Mode

For CI/CD pipelines or collaborative environments, enable read-only mode:

```json
{
  "env": {
    "READ_ONLY_MODE": "true"
  }
}
```

This restricts operations to:
- Project inspection and analysis
- Debug output retrieval
- Metadata queries

## Troubleshooting

### Godot Not Found
```
Error: Godot executable not found
```
**Solution:** Set `GODOT_PATH` environment variable to your Godot executable.

### Connection Issues
1. Restart your AI assistant
2. Enable `DEBUG=true` for detailed logging
3. Verify Node.js 18+ is installed: `node --version`

### Scene Operations Failing
1. Use resource paths: `res://scenes/player.tscn`
2. Verify scene files exist
3. Check Godot console for specific errors

### Permission Errors
Ensure the MCP server has write access to your project directory.

## Examples

### Create a Player Scene
```
Create a new scene at res://scenes/player.tscn with CharacterBody2D as root,
then add a Sprite2D child and a CollisionShape2D child.
```

### Analyze Project for Issues
```
Run validate_project to check for missing files or configuration issues.
```

### Quick Error Check
```
Use quick_test to run the project headless for 10 seconds and report any errors.
```

## Contributing

Contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## Support

If you find this project useful, consider supporting its development:

[![PayPal](https://img.shields.io/badge/PayPal-Support-blue?logo=paypal)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=386AYZ3ZYDZM2)

No pressure at all - but any amount is appreciated!

### Connect

- **Discord**: [Join the community](https://discord.gg/fUXXTk3YgG)
- **Twitter**: [@duskhoundyt](https://www.twitter.com/duskhoundyt)
- **Twitch**: [duskhoundyt](https://www.twitch.tv/duskhoundyt)
- **TikTok**: [@duskhoundyt](https://www.tiktok.com/@duskhoundyt)

**Business inquiries**: Dusklpbuisness@gmail.com

## Credits

Inspired by:
- [bradypp/godot-mcp](https://github.com/bradypp/godot-mcp)
- [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)
- [ee0pdt/Godot-MCP](https://github.com/ee0pdt/Godot-MCP)

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

Made with care for the Godot community.
