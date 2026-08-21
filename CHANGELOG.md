# Changelog

## 3.2.1

- Added a non-interactive `--validate` mode behind `npm test`.
- Validation now checks the configured Godot executable, target project, and
  installed `addons/godot_mcp/godot_operations.gd` bridge before exiting with a
  JSON report suitable for CI and agent workflows.

## 3.3.0 — Frontier

### Fixed (bridge was unrunnable before this release)
- Bridge failed to parse on every engine version: reserved-keyword `var class_name`,
  nonexistent `ClassDB.class_get_constant_list` (now `class_get_integer_constant_list`),
  and `get_tree()` calls on a SceneTree script (now direct `root`/`process_frame`).
- Success paths never called `quit()`; a watchdog now guarantees termination with a
  machine-readable timeout result, and idle ops exit cleanly.
- Animation suite: client/bridge param-name mismatch (`animation_name` vs `anim_name`),
  removed `AnimationPlayer.add_animation()` API replaced with default-library add.
- `connect_signal` now uses CONNECT_PERSIST so saved scenes keep the connection.
- `analyze_signal_flow` no longer crashes on live connections (Callable.get_method).
- All ~45 direct `params.x` dereferences converted to safe `.get()` with defaults.
- Path joining in recursive file scans produced `res://dirFile.ext` (missing slash).

### Added
- Sentinel-delimited result protocol (`<<<MCP_RESULT>>>...<<<MCP_RESULT_END>>>`) with a
  brace-matched fallback parser: engine logs can no longer corrupt or clobber results.
- Future-proof Godot discovery: wildcard scan of known install roots picks the newest
  Godot_v4* binary automatically (validated on 4.6-stable and 4.8-dev3).
- Real path containment for all writes (`safeProjectWritePath`, relative-based).
