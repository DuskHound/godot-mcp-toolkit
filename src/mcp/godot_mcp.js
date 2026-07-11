#!/usr/bin/env node

import { spawn } from "child_process";
import { readFileSync, existsSync, readdirSync, writeFileSync, mkdirSync, statSync, unlinkSync, renameSync, copyFileSync } from "fs";
import { join, dirname, basename, resolve, normalize, relative, extname } from "path";
import readline from "readline";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// =============================================================================
// CONFIGURATION
// =============================================================================

const CONFIG = {
  VERSION: "3.0.0",
  GODOT_PATH: process.env.GODOT_PATH || findGodotExecutable(),
  PROJECT_PATH: sanitizePath(process.env.PROJECT_PATH || process.cwd()),
  DEBUG: process.env.DEBUG === "true" || process.argv.includes("--debug"),
  READ_ONLY: process.env.READ_ONLY_MODE === "true",
  MAX_TIMEOUT: 300000,
  MIN_TIMEOUT: 1000,
  MAX_SEARCH_DEPTH: 3,
  MAX_OUTPUT_SIZE: 100000
};

// =============================================================================
// SECURITY UTILITIES
// =============================================================================

function findGodotExecutable() {
  const commonPaths = [
    "C:\\Program Files\\Godot\\Godot_v4.6-stable_win64.exe",
    "C:\\Program Files\\Godot\\Godot_v4.5-stable_win64.exe",
    "C:\\Program Files\\Godot\\Godot_v4.4-stable_win64.exe",
    "C:\\Program Files\\Godot\\Godot.exe",
    "C:\\Program Files (x86)\\Godot\\Godot.exe",
    "/Applications/Godot.app/Contents/MacOS/Godot",
    "/usr/local/bin/godot",
    "/usr/bin/godot",
    "/snap/bin/godot"
  ];
  for (const p of commonPaths) { if (existsSync(p)) return p; }
  return "godot";
}

function sanitizePath(inputPath) {
  if (!inputPath || typeof inputPath !== "string") return null;
  return normalize(inputPath).replace(/\0/g, "").replace(/\\/g, "/");
}

function isPathWithinProject(targetPath, projectPath = CONFIG.PROJECT_PATH) {
  if (!targetPath || !projectPath) return false;
  return resolve(projectPath, targetPath).startsWith(resolve(projectPath));
}

function validateResourcePath(resPath) {
  if (!resPath || typeof resPath !== "string") return { valid: false, error: "Path is required" };
  if (!resPath.startsWith("res://")) return { valid: false, error: "Path must start with res://" };
  if (resPath.includes("..")) return { valid: false, error: "Path traversal not allowed" };
  return { valid: true, path: resPath };
}

function resToAbsolute(resPath) {
  return join(CONFIG.PROJECT_PATH, resPath.replace("res://", ""));
}

function validateTimeout(timeout) {
  const t = parseInt(timeout, 10);
  if (isNaN(t)) return CONFIG.MIN_TIMEOUT;
  return Math.max(CONFIG.MIN_TIMEOUT, Math.min(t, CONFIG.MAX_TIMEOUT));
}

function sanitizeNodeName(name) {
  if (!name || typeof name !== "string") return null;
  return name.replace(/[^a-zA-Z0-9_\- ]/g, "").substring(0, 64);
}

function validateNodeType(nodeType) {
  if (!nodeType || typeof nodeType !== "string") return { valid: false, error: "Node type is required" };
  const safeNodeTypes = [
    "Node", "Node2D", "Node3D", "Control",
    "Sprite2D", "Sprite3D", "AnimatedSprite2D", "AnimatedSprite3D",
    "CharacterBody2D", "CharacterBody3D", "RigidBody2D", "RigidBody3D",
    "StaticBody2D", "StaticBody3D", "Area2D", "Area3D",
    "CollisionShape2D", "CollisionShape3D", "CollisionPolygon2D",
    "Camera2D", "Camera3D", "Light2D", "DirectionalLight3D", "OmniLight3D",
    "AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D",
    "Timer", "AnimationPlayer", "AnimationTree",
    "Label", "Button", "TextEdit", "LineEdit", "Panel", "Container",
    "HBoxContainer", "VBoxContainer", "GridContainer", "MarginContainer",
    "CanvasLayer", "ParallaxBackground", "ParallaxLayer",
    "TileMap", "TileMapLayer", "NavigationRegion2D", "NavigationRegion3D",
    "Path2D", "Path3D", "PathFollow2D", "PathFollow3D",
    "GPUParticles2D", "GPUParticles3D", "CPUParticles2D", "CPUParticles3D",
    "MeshInstance3D", "CSGBox3D", "CSGSphere3D", "CSGCylinder3D",
    "RayCast2D", "RayCast3D", "ShapeCast2D", "ShapeCast3D",
    "MultiMeshInstance3D", "QuadMesh", "Decal", "GPUParticlesAttractor3D",
    "AnimationMixer", "ResourcePreloader", "NodeGroup", "RemoteTransform2D"
  ];
  const isValidClassName = /^[A-Z][a-zA-Z0-9]*(\d?[A-Z][a-zA-Z0-9]*)*$/.test(nodeType);
  if (safeNodeTypes.includes(nodeType) || isValidClassName) return { valid: true, type: nodeType };
  return { valid: false, error: `Invalid or unsupported node type: ${nodeType}` };
}

// =============================================================================
// LOGGING
// =============================================================================

function log(level, message, data = null) {
  if (level === "debug" && !CONFIG.DEBUG) return;
  const timestamp = new Date().toISOString();
  const prefix = `[${timestamp}] [godot-mcp] [${level.toUpperCase()}]`;
  const safeMessage = String(message).substring(0, 1000);
  if (data) {
    const safeData = JSON.stringify(data, null, 2).substring(0, 5000);
    console.error(`${prefix} ${safeMessage}`, safeData);
  } else {
    console.error(`${prefix} ${safeMessage}`);
  }
}

// =============================================================================
// MCP PROTOCOL
// =============================================================================

function send(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }

function errorResponse(id, message, code = -32000) {
  send({ jsonrpc: "2.0", id, error: { code, message: String(message).substring(0, 500) } });
}

function successResponse(id, result) {
  send({ jsonrpc: "2.0", id, result });
}

function textContent(text) {
  return { content: [{ type: "text", text: String(text).substring(0, CONFIG.MAX_OUTPUT_SIZE) }] };
}

function jsonContent(data) {
  return textContent(JSON.stringify(data, null, 2));
}

// =============================================================================
// PROCESS MANAGEMENT
// =============================================================================

let activeGodotProcess = null;
let outputBuffer = { stdout: [], stderr: [], errors: [], warnings: [], totalSize: 0 };

function clearOutputBuffer() {
  outputBuffer = { stdout: [], stderr: [], errors: [], warnings: [], totalSize: 0 };
}

function appendToBuffer(array, text) {
  if (outputBuffer.totalSize > CONFIG.MAX_OUTPUT_SIZE) return;
  const truncated = text.substring(0, CONFIG.MAX_OUTPUT_SIZE - outputBuffer.totalSize);
  array.push(truncated);
  outputBuffer.totalSize += truncated.length;
}

// =============================================================================
// GODOT OPERATIONS (via headless)
// =============================================================================

async function getGodotVersion() {
  return new Promise((resolve) => {
    const godot = spawn(CONFIG.GODOT_PATH, ["--version"], { timeout: 10000, windowsHide: true });
    let version = "";
    godot.stdout.on("data", (data) => { version += data.toString().substring(0, 100); });
    godot.on("close", () => { resolve(version.trim() || "unknown"); });
    godot.on("error", () => { resolve("error: could not run godot"); });
    setTimeout(() => { godot.kill(); resolve(version.trim() || "timeout"); }, 10000);
  });
}

async function launchEditor(projectPath) {
  const safePath = sanitizePath(projectPath) || CONFIG.PROJECT_PATH;
  if (!existsSync(join(safePath, "project.godot"))) return { success: false, error: "No project.godot found" };
  return new Promise((resolve) => {
    log("info", `Launching Godot editor for: ${safePath}`);
    const godot = spawn(CONFIG.GODOT_PATH, ["--path", safePath, "--editor"], { detached: true, stdio: "ignore", windowsHide: false });
    godot.unref();
    setTimeout(() => { resolve({ success: true, message: `Editor launched for ${basename(safePath)}`, pid: godot.pid }); }, 1000);
    godot.on("error", (err) => { resolve({ success: false, error: err.message }); });
  });
}

async function runProject(options = {}) {
  const { headless = false, timeout = 30000 } = options;
  const safeTimeout = validateTimeout(timeout);
  return new Promise((resolve) => {
    clearOutputBuffer();
    const startTime = Date.now();
    const args = ["--path", CONFIG.PROJECT_PATH];
    if (headless) { args.push("--headless", "--quit-after", String(Math.floor(safeTimeout / 1000))); }
    log("info", `Running project`, { headless, timeout: safeTimeout });
    const godot = spawn(CONFIG.GODOT_PATH, args, { windowsHide: true });
    activeGodotProcess = godot;
    godot.stdout.on("data", (data) => { const text = data.toString(); appendToBuffer(outputBuffer.stdout, text); parseOutputForErrors(text); });
    godot.stderr.on("data", (data) => { const text = data.toString(); appendToBuffer(outputBuffer.stderr, text); appendToBuffer(outputBuffer.errors, text.trim()); });
    godot.on("close", (code) => {
      activeGodotProcess = null;
      resolve({ success: code === 0, exitCode: code, duration: Date.now() - startTime, stdout: outputBuffer.stdout.join(""), stderr: outputBuffer.stderr.join(""), errors: outputBuffer.errors, warnings: outputBuffer.warnings });
    });
    godot.on("error", (err) => { activeGodotProcess = null; resolve({ success: false, error: err.message }); });
    setTimeout(() => { if (godot && !godot.killed) { godot.kill("SIGTERM"); setTimeout(() => { if (!godot.killed) godot.kill("SIGKILL"); }, 2000); } }, safeTimeout + 5000);
  });
}

function stopProject() {
  if (activeGodotProcess && !activeGodotProcess.killed) {
    log("info", "Stopping active Godot process");
    activeGodotProcess.kill("SIGTERM");
    setTimeout(() => { if (activeGodotProcess && !activeGodotProcess.killed) activeGodotProcess.kill("SIGKILL"); }, 2000);
    return { stopped: true, message: "Process terminated" };
  }
  return { stopped: false, message: "No active process" };
}

function getDebugOutput() {
  return { stdout: outputBuffer.stdout.join(""), stderr: outputBuffer.stderr.join(""), errors: outputBuffer.errors, warnings: outputBuffer.warnings, errorCount: outputBuffer.errors.length, warningCount: outputBuffer.warnings.length };
}

function parseOutputForErrors(text) {
  const lines = text.split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.includes("ERROR") || trimmed.includes("SCRIPT ERROR")) appendToBuffer(outputBuffer.errors, trimmed);
    if (trimmed.includes("WARNING") || trimmed.includes("SCRIPT WARNING")) appendToBuffer(outputBuffer.warnings, trimmed);
  }
}

// =============================================================================
// GDSCRIPT OPERATIONS (via headless Godot)
// =============================================================================

async function runGDScriptOperation(operation, params) {
  if (CONFIG.READ_ONLY && !["get_uid", "get_project_settings", "get_scene_tree", "list_scenes", "list_scripts", "validate_project", "read_script", "analyze_script", "list_shaders", "list_animations", "analyze_dependencies", "get_performance_report"].includes(operation)) {
    throw new Error("Operation not allowed in read-only mode");
  }
  const gdscriptPath = join(dirname(dirname(__dirname)), "addons", "godot_mcp", "godot_operations.gd");
  if (!existsSync(gdscriptPath)) throw new Error("GDScript operations file not found");
  return new Promise((resolve, reject) => {
    const paramsJson = JSON.stringify(params);
    const args = ["--headless", "--path", CONFIG.PROJECT_PATH, "--script", gdscriptPath, operation, paramsJson];
    log("debug", `Running GDScript operation: ${operation}`);
    const godot = spawn(CONFIG.GODOT_PATH, args, { windowsHide: true });
    let stdout = "";
    let stderr = "";
    godot.stdout.on("data", (data) => { stdout += data.toString().substring(0, CONFIG.MAX_OUTPUT_SIZE); });
    godot.stderr.on("data", (data) => { stderr += data.toString().substring(0, CONFIG.MAX_OUTPUT_SIZE); });
    godot.on("close", (code) => { resolve({ success: code === 0, output: stdout, stderr, exitCode: code }); });
    godot.on("error", (err) => { resolve({ success: false, error: err.message }); });
    setTimeout(() => { if (!godot.killed) { godot.kill(); resolve({ success: false, error: "Operation timed out" }); } }, 60000);
  });
}

function parseGDScriptOutput(result) {
  if (!result.success) return { success: false, error: result.stderr || result.error || "Operation failed" };
  try {
    const lines = result.output.split("\n");
    const jsonLines = lines.filter(l => l.startsWith("{") || l.startsWith("["));
    if (jsonLines.length === 0) return { success: true, data: { raw: result.output } };
    return { success: true, data: JSON.parse(jsonLines[jsonLines.length - 1]) };
  } catch (e) {
    return { success: true, data: { raw: result.output } };
  }
}

// =============================================================================
// STATIC FILE OPERATIONS (Node.js native, no Godot needed)
// =============================================================================

function readScriptFile(scriptPath) {
  const absPath = resToAbsolute(scriptPath);
  if (!existsSync(absPath)) throw new Error(`Script not found: ${scriptPath}`);
  const content = readFileSync(absPath, "utf-8");
  return { path: scriptPath, content, lines: content.split("\n").length, size: statSync(absPath).size };
}

function writeScriptFile(scriptPath, content) {
  const absPath = resToAbsolute(scriptPath);
  const dir = dirname(absPath);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  writeFileSync(absPath, content, "utf-8");
  return { path: scriptPath, size: content.length };
}

function listProjectFiles(ext, searchPath = "res://") {
  const absPath = searchPath.startsWith("res://") ? join(CONFIG.PROJECT_PATH, searchPath.replace("res://", "")) : searchPath;
  const files = [];
  function scan(dir, depth = 0) {
    if (depth > 10) return;
    try {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        if (entry.isDirectory()) { if (!entry.name.startsWith(".") && entry.name !== ".godot") scan(join(dir, entry.name), depth + 1); }
        else if (entry.name.endsWith(ext)) files.push(join(dir, entry.name));
      }
    } catch {}
  }
  scan(absPath);
  return files.map(f => "res://" + relative(CONFIG.PROJECT_PATH, f).replace(/\\/g, "/"));
}

function analyzeScriptStatic(scriptPath) {
  const absPath = resToAbsolute(scriptPath);
  if (!existsSync(absPath)) throw new Error(`Script not found: ${scriptPath}`);
  const content = readFileSync(absPath, "utf-8");
  const lines = content.split("\n");
  const metrics = { total_lines: lines.length, code_lines: 0, comment_lines: 0, blank_lines: 0, functions: [], classes: [], signals: [], exports: [], onready_vars: [] };
  for (let i = 0; i < lines.length; i++) {
    const stripped = lines[i].trim();
    if (!stripped) { metrics.blank_lines++; continue; }
    if (stripped.startsWith("#")) { metrics.comment_lines++; continue; }
    metrics.code_lines++;
    if (stripped.startsWith("func ")) metrics.functions.push({ name: stripped.split("(")[0].replace("func ", ""), line: i + 1 });
    if (stripped.startsWith("class ") || stripped.startsWith("class_name ")) metrics.classes.push({ name: stripped.split(" ")[1].split(":")[0].split("(")[0], line: i + 1 });
    if (stripped.startsWith("signal ")) metrics.signals.push({ name: stripped.replace("signal ", "").split("(")[0], line: i + 1 });
    if (stripped.includes("@export")) {
      let varName = stripped.split(":")[0].strip_edges ? stripped.split(":")[0].trim() : stripped;
      metrics.exports.push({ name: varName, line: i + 1 });
    }
    if (stripped.includes("@onready")) {
      let varName = stripped.split(":")[0].trim();
      metrics.onready_vars.push({ name: varName, line: i + 1 });
    }
  }
  return { path: scriptPath, metrics };
}

// =============================================================================
// GODOT HEADLESS HELPER FUNCTIONS
// =============================================================================

async function callGDScript(operation, params) {
  const result = await runGDScriptOperation(operation, params);
  return parseGDScriptOutput(result);
}

// =============================================================================
// TOOL HANDLERS
// =============================================================================

async function handleGodotVersion() {
  return jsonContent({ version: await getGodotVersion(), path: CONFIG.GODOT_PATH });
}

function handleGodotStatus() {
  return jsonContent({ version: CONFIG.VERSION, godotPath: CONFIG.GODOT_PATH, projectPath: CONFIG.PROJECT_PATH, readOnlyMode: CONFIG.READ_ONLY, debugMode: CONFIG.DEBUG, activeProcess: activeGodotProcess !== null });
}

// Scene tools
async function handleCreateScene(args) {
  const r = await callGDScript("create_scene", { scene_path: args.scene_path, root_node_type: args.root_node_type || "Node2D" });
  return jsonContent(r);
}

async function handleAddNode(args) {
  const r = await callGDScript("add_node", { scene_path: args.scene_path, node_name: args.node_name, node_type: args.node_type, parent_node_path: args.parent_path || "root", properties: args.properties || {} });
  return jsonContent(r);
}

async function handleEditNode(args) {
  const r = await callGDScript("edit_node", { scene_path: args.scene_path, node_path: args.node_path, properties: args.properties || {} });
  return jsonContent(r);
}

async function handleRemoveNode(args) {
  const r = await callGDScript("remove_node", { scene_path: args.scene_path, node_path: args.node_path });
  return jsonContent(r);
}

async function handleLoadSprite(args) {
  const r = await callGDScript("load_sprite", { scene_path: args.scene_path, node_path: args.node_path, texture_path: args.texture_path });
  return jsonContent(r);
}

async function handleSaveScene(args) {
  const p = { scene_path: args.scene_path };
  if (args.new_path) p.new_path = args.new_path;
  const r = await callGDScript("save_scene", p);
  return jsonContent(r);
}

async function handleCompareScenes(args) {
  const r = await callGDScript("compare_scenes", { scene_path_1: args.scene_path_1, scene_path_2: args.scene_path_2 });
  return jsonContent(r);
}

// Script tools
function handleReadScript(args) {
  try { return jsonContent(readScriptFile(args.script_path)); }
  catch (e) { return jsonContent({ error: e.message }); }
}

async function handleEditScript(args) {
  const r = await callGDScript("edit_script", { script_path: args.script_path, content: args.content, line_number: args.line_number || -1, new_content: args.new_content || "" });
  return jsonContent(r);
}

function handleListScripts(args) {
  try { const scripts = listProjectFiles(".gd", args.path || "res://"); return jsonContent({ path: args.path || "res://", count: scripts.length, scripts }); }
  catch (e) { return jsonContent({ error: e.message }); }
}

function handleAnalyzeScript(args) {
  try { return jsonContent(analyzeScriptStatic(args.script_path)); }
  catch (e) { if (CONFIG.GODOT_PATH) return callGDScript("analyze_script", { script_path: args.script_path }).then(r => jsonContent(r)); return jsonContent({ error: e.message }); }
}

async function handleRefactorRename(args) {
  const r = await callGDScript("refactor_rename", { script_path: args.script_path, old_name: args.old_name, new_name: args.new_name });
  return jsonContent(r);
}

async function handleRefactorExtractMethod(args) {
  const r = await callGDScript("refactor_extract_method", { script_path: args.script_path, start_line: args.start_line, end_line: args.end_line, method_name: args.method_name });
  return jsonContent(r);
}

async function handleFindScriptReferences(args) {
  const r = await callGDScript("find_script_references", { search_term: args.search_term, path: args.path || "res://" });
  return jsonContent(r);
}

async function handleCreateScript(args) {
  if (!args.script_path || (!args.content && !args.template)) return jsonContent({ error: "script_path and content or template required" });
  let content = args.content;
  if (!content && args.template) {
    const templates = {
      "node": "extends Node\n\nfunc _ready():\n\tpass\n\nfunc _process(delta):\n\tpass\n",
      "node2d": "extends Node2D\n\nfunc _ready():\n\tpass\n\nfunc _process(delta):\n\tpass\n",
      "node3d": "extends Node3D\n\nfunc _ready():\n\tpass\n\nfunc _process(delta):\n\tpass\n",
      "characterbody2d": "extends CharacterBody2D\n\nfunc _physics_process(delta):\n\tpass\n",
      "characterbody3d": "extends CharacterBody3D\n\nfunc _physics_process(delta):\n\tpass\n",
      "area2d": "extends Area2D\n\nfunc _on_body_entered(body):\n\tpass\n",
      "area3d": "extends Area3D\n\nfunc _on_body_entered(body):\n\tpass\n",
      "control": "extends Control\n\nfunc _ready():\n\tpass\n",
      "label": "extends Label\n\nfunc _ready():\n\ttext = \"Hello, World!\"\n",
      "button": "extends Button\n\nfunc _ready():\n\tpressed.connect(_on_pressed)\n\nfunc _on_pressed():\n\tprint(\"Button pressed!\")\n",
      "autoload": "extends Node\n\n# Autoload singleton\n\nfunc _ready():\n\tprint(\"Autoload initialized\")\n",
      "state_machine": "extends Node\n\nenum State { IDLE, ACTIVE, COOLDOWN }\nvar current_state: State = State.IDLE\n\nfunc _process(delta):\n\tmatch current_state:\n\t\tState.IDLE:\n\t\t\tpass\n\t\tState.ACTIVE:\n\t\t\tpass\n\t\tState.COOLDOWN:\n\t\t\tpass\n"
    };
    content = templates[args.template.toLowerCase()] || `extends Node\n\n# ${args.script_path.split("/").pop()}\n`;
  }
  try { const r = writeScriptFile(args.script_path, content); return jsonContent({ success: true, ...r }); }
  catch (e) { return jsonContent({ error: e.message }); }
}

// Project tools
function handleGetProjectInfo() {
  const projectFile = join(CONFIG.PROJECT_PATH, "project.godot");
  if (!existsSync(projectFile)) return jsonContent({ error: "No project.godot found" });
  const content = readFileSync(projectFile, "utf-8");
  const info = { path: CONFIG.PROJECT_PATH, name: basename(CONFIG.PROJECT_PATH), mainScene: null, autoloads: [], features: [] };
  let currentSection = "";
  for (const line of content.split("\n")) {
    if (line.startsWith("[")) { currentSection = line.slice(1, -1); continue; }
    if (currentSection === "application") {
      const nameMatch = line.match(/config\/name\s*=\s*"([^"]+)"/); if (nameMatch) info.name = nameMatch[1];
      const sceneMatch = line.match(/run\/main_scene\s*=\s*"([^"]+)"/); if (sceneMatch) info.mainScene = sceneMatch[1];
    }
    if (currentSection === "autoload") {
      const match = line.match(/(\w+)\s*=\s*"([^"]+)"/); if (match) info.autoloads.push({ name: match[1], path: match[2] });
    }
  }
  return jsonContent(info);
}

function handleListProjects(args) {
  const safePath = sanitizePath(args.search_path) || CONFIG.PROJECT_PATH;
  const projects = [];
  function searchDir(dir, depth = 0) {
    if (depth > CONFIG.MAX_SEARCH_DEPTH) return;
    try {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        if (entry.name === "project.godot") { projects.push({ path: dir, name: basename(dir) }); return; }
        if (entry.isDirectory() && !entry.name.startsWith(".") && entry.name !== "node_modules") searchDir(join(dir, entry.name), depth + 1);
      }
    } catch {}
  }
  if (existsSync(join(safePath, "project.godot"))) projects.push({ path: safePath, name: basename(safePath) });
  else searchDir(safePath);
  return jsonContent(projects);
}

function handleListScenes(args) {
  try { const scenes = listProjectFiles(".tscn", args.path || "res://"); return jsonContent({ path: args.path || "res://", count: scenes.length, scenes }); }
  catch (e) { return jsonContent({ error: e.message }); }
}

async function handleGetSceneTree(args) {
  const r = await callGDScript("get_scene_tree", { scene_path: args.scene_path });
  return jsonContent(r);
}

async function handleGetProjectSettings() {
  const r = await callGDScript("get_project_settings", {});
  return jsonContent(r);
}

async function handleValidateProject() {
  const r = await callGDScript("validate_project", {});
  return jsonContent(r);
}

async function handleAnalyzeDependencies(args) {
  const r = await callGDScript("analyze_dependencies", { scene_path: args.scene_path });
  return jsonContent(r);
}

// UID tools
async function handleGetUid(args) {
  const r = await callGDScript("get_uid", { file_path: args.file_path });
  return jsonContent(r);
}

async function handleUpdateProjectUids() {
  const r = await callGDScript("resave_resources", {});
  return jsonContent(r);
}

// Signal tools
async function handleConnectSignal(args) {
  const r = await callGDScript("connect_signal", { scene_path: args.scene_path, source_node: args.source_node, signal_name: args.signal_name, target_node: args.target_node, method_name: args.method_name });
  return jsonContent(r);
}

async function handleDisconnectSignal(args) {
  const r = await callGDScript("disconnect_signal", { scene_path: args.scene_path, source_node: args.source_node, signal_name: args.signal_name, target_node: args.target_node, method_name: args.method_name });
  return jsonContent(r);
}

async function handleListSignals(args) {
  const r = await callGDScript("list_signals", { scene_path: args.scene_path, node_path: args.node_path || "" });
  return jsonContent(r);
}

async function handleEmitSignal(args) {
  const r = await callGDScript("emit_signal", { scene_path: args.scene_path, node_path: args.node_path, signal_name: args.signal_name, args: args.args || [] });
  return jsonContent(r);
}

async function handleGetSignalConnections(args) {
  const r = await callGDScript("get_signal_connections", { scene_path: args.scene_path, signal_name: args.signal_name || "" });
  return jsonContent(r);
}

async function handleAnalyzeSignalFlow(args) {
  const r = await callGDScript("analyze_signal_flow", { scene_path: args.scene_path });
  return jsonContent(r);
}

// Performance tools
async function handleProfileScene(args) {
  const r = await callGDScript("profile_scene", { scene_path: args.scene_path, duration: args.duration || 5.0 });
  return jsonContent(r);
}

async function handleAnalyzePerformance(args) {
  const r = await callGDScript("analyze_performance", { path: args.path || "res://" });
  return jsonContent(r);
}

async function handleGetPerformanceReport() {
  const r = await callGDScript("get_performance_report", {});
  return jsonContent(r);
}

async function handleProfileScript(args) {
  const r = await callGDScript("profile_script", { script_path: args.script_path, iterations: args.iterations || 100 });
  return jsonContent(r);
}

async function handleAnalyzeMemoryUsage() {
  const r = await callGDScript("analyze_memory_usage", {});
  return jsonContent(r);
}

async function handleDetectBottlenecks(args) {
  const r = await callGDScript("detect_bottlenecks", { path: args.path || "res://" });
  return jsonContent(r);
}

// Shader & Material tools
async function handleEditShader(args) {
  const r = await callGDScript("edit_shader", { shader_path: args.shader_path, content: args.content, code: args.code || "" });
  return jsonContent(r);
}

async function handleCreateMaterial(args) {
  const r = await callGDScript("create_material", { material_path: args.material_path, material_type: args.material_type || "StandardMaterial3D" });
  return jsonContent(r);
}

async function handleEditMaterial(args) {
  const r = await callGDScript("edit_material", { material_path: args.material_path, properties: args.properties || {} });
  return jsonContent(r);
}

async function handleListShaders(args) {
  const r = await callGDScript("list_shaders", { path: args.path || "res://" });
  return jsonContent(r);
}

async function handleCreateShader(args) {
  const r = await callGDScript("create_shader", { shader_path: args.shader_path, shader_type: args.shader_type || "spatial", content: args.content || "" });
  return jsonContent(r);
}

async function handleOptimizeShader(args) {
  const r = await callGDScript("optimize_shader", { shader_path: args.shader_path });
  return jsonContent(r);
}

// Animation tools
async function handleCreateAnimation(args) {
  const r = await callGDScript("create_animation", { scene_path: args.scene_path, animation_name: args.animation_name, length: args.length || 1.0 });
  return jsonContent(r);
}

async function handleEditAnimation(args) {
  const r = await callGDScript("edit_animation", { scene_path: args.scene_path, animation_name: args.animation_name, properties: args.properties || {} });
  return jsonContent(r);
}

async function handleListAnimations(args) {
  const r = await callGDScript("list_animations", { scene_path: args.scene_path });
  return jsonContent(r);
}

async function handleCreateAnimationLibrary(args) {
  const r = await callGDScript("create_animation_library", { scene_path: args.scene_path, library_name: args.library_name });
  return jsonContent(r);
}

async function handleAddAnimationTrack(args) {
  const r = await callGDScript("add_animation_track", { scene_path: args.scene_path, animation_name: args.animation_name, track_path: args.track_path, track_type: args.track_type || "value", track_index: args.track_index || -1 });
  return jsonContent(r);
}

async function handleEditKeyframe(args) {
  const r = await callGDScript("edit_keyframe", { scene_path: args.scene_path, animation_name: args.animation_name, track_index: args.track_index, keyframe_index: args.keyframe_index, properties: args.properties || {} });
  return jsonContent(r);
}

async function handlePlayAnimation(args) {
  const r = await callGDScript("play_animation", { scene_path: args.scene_path, animation_name: args.animation_name });
  return jsonContent(r);
}

async function handleExportAnimation(args) {
  const r = await callGDScript("export_animation", { scene_path: args.scene_path, animation_name: args.animation_name, output_path: args.output_path });
  return jsonContent(r);
}

// Export & Testing tools
async function handleExportMeshLibrary(args) {
  const r = await callGDScript("export_mesh_library", { scene_path: args.scene_path, output_path: args.output_path });
  return jsonContent(r);
}

async function handleGetExportPresets() {
  const r = await callGDScript("get_export_presets", {});
  return jsonContent(r);
}

// Asset tools
async function handleImportTexture(args) {
  const r = await callGDScript("import_texture", { source_path: args.source_path, dest_path: args.dest_path });
  return jsonContent(r);
}

async function handleImportModel(args) {
  const r = await callGDScript("import_model", { source_path: args.source_path, dest_path: args.dest_path });
  return jsonContent(r);
}

async function handleImportAudio(args) {
  const r = await callGDScript("import_audio", { source_path: args.source_path, dest_path: args.dest_path });
  return jsonContent(r);
}

// Testing
async function handleQuickTest(args) {
  return jsonContent(await runProject({ headless: true, timeout: validateTimeout(args.timeout || 10000) }));
}

async function handleFullTest(args) {
  const result = await runProject({ headless: true, timeout: validateTimeout(args.timeout || 60000) });
  let projectInfo = {};
  try { projectInfo = JSON.parse((await callGDScript("get_project_settings", {})).data?.raw || "{}"); } catch {}
  return jsonContent({ runtime: { status: result.success ? "PASS" : "FAIL", duration: result.duration, exitCode: result.exitCode }, errors: { total: result.errors.length }, warnings: { total: result.warnings.length } });
}

// =============================================================================
// TOOL DEFINITIONS (55+ tools)
// =============================================================================

const TOOLS = [
  // System
  { name: "godot_version", description: "Get installed Godot version", inputSchema: { type: "object", properties: {} } },
  { name: "godot_status", description: "Get MCP server status and configuration", inputSchema: { type: "object", properties: {} } },
  { name: "launch_editor", description: "Launch Godot editor for the project", inputSchema: { type: "object", properties: { project_path: { type: "string", description: "Path to Godot project" } } } },
  { name: "run_project", description: "Run the Godot project and capture output", inputSchema: { type: "object", properties: { headless: { type: "boolean", description: "Headless mode", default: false }, timeout: { type: "number", description: "Timeout in ms", default: 30000 } } } },
  { name: "stop_project", description: "Stop the running Godot project", inputSchema: { type: "object", properties: {} } },
  { name: "get_debug_output", description: "Get captured debug output", inputSchema: { type: "object", properties: {} } },

  // Scene (7)
  { name: "create_scene", description: "Create a new Godot scene", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, root_node_type: { type: "string", default: "Node2D" } }, required: ["scene_path"] } },
  { name: "add_node", description: "Add a node to an existing scene", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, node_name: { type: "string" }, node_type: { type: "string" }, parent_path: { type: "string", default: "root" }, properties: { type: "object" } }, required: ["scene_path", "node_name", "node_type"] } },
  { name: "edit_node", description: "Edit node properties in a scene", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, node_path: { type: "string" }, properties: { type: "object" } }, required: ["scene_path", "node_path", "properties"] } },
  { name: "remove_node", description: "Remove a node from a scene", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, node_path: { type: "string" } }, required: ["scene_path", "node_path"] } },
  { name: "load_sprite", description: "Load a texture into a sprite node", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, node_path: { type: "string" }, texture_path: { type: "string", description: "res://..." } }, required: ["scene_path", "node_path", "texture_path"] } },
  { name: "save_scene", description: "Save a scene", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, new_path: { type: "string", description: "Optional new path" } }, required: ["scene_path"] } },
  { name: "compare_scenes", description: "Compare two scenes for differences", inputSchema: { type: "object", properties: { scene_path_1: { type: "string", description: "res://..." }, scene_path_2: { type: "string", description: "res://..." } }, required: ["scene_path_1", "scene_path_2"] } },

  // Script (8)
  { name: "read_script", description: "Read a script file (static, fast)", inputSchema: { type: "object", properties: { script_path: { type: "string", description: "res://..." } }, required: ["script_path"] } },
  { name: "edit_script", description: "Edit a script file", inputSchema: { type: "object", properties: { script_path: { type: "string", description: "res://..." }, content: { type: "string" }, line_number: { type: "number" }, new_content: { type: "string" } }, required: ["script_path"] } },
  { name: "create_script", description: "Create a new GDScript file from template or content", inputSchema: { type: "object", properties: { script_path: { type: "string", description: "res://..." }, content: { type: "string" }, template: { type: "string", description: "Template name: node, node2d, node3d, characterbody2d, control, autoload, state_machine" } }, required: ["script_path"] } },
  { name: "list_scripts", description: "List all GDScript files in the project", inputSchema: { type: "object", properties: { path: { type: "string", description: "Search path", default: "res://" } } } },
  { name: "analyze_script", description: "Analyze a script for metrics and structure", inputSchema: { type: "object", properties: { script_path: { type: "string", description: "res://..." } }, required: ["script_path"] } },
  { name: "find_script_references", description: "Find all references to a symbol across the project", inputSchema: { type: "object", properties: { search_term: { type: "string" }, path: { type: "string", default: "res://" } }, required: ["search_term"] } },
  { name: "refactor_rename", description: "Rename a symbol across a script", inputSchema: { type: "object", properties: { script_path: { type: "string", description: "res://..." }, old_name: { type: "string" }, new_name: { type: "string" } }, required: ["script_path", "old_name", "new_name"] } },
  { name: "refactor_extract_method", description: "Extract lines into a new method", inputSchema: { type: "object", properties: { script_path: { type: "string", description: "res://..." }, start_line: { type: "number" }, end_line: { type: "number" }, method_name: { type: "string" } }, required: ["script_path", "start_line", "end_line", "method_name"] } },

  // Project (6)
  { name: "get_project_info", description: "Get detailed project information", inputSchema: { type: "object", properties: {} } },
  { name: "get_project_settings", description: "Get Godot project settings", inputSchema: { type: "object", properties: {} } },
  { name: "list_projects", description: "Find Godot projects in a directory", inputSchema: { type: "object", properties: { search_path: { type: "string", description: "Directory to search" } } } },
  { name: "list_scenes", description: "List all .tscn files", inputSchema: { type: "object", properties: { path: { type: "string", description: "Search path", default: "res://" } } } },
  { name: "get_scene_tree", description: "Get scene node hierarchy", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." } }, required: ["scene_path"] } },
  { name: "validate_project", description: "Validate project for issues", inputSchema: { type: "object", properties: {} } },
  { name: "analyze_dependencies", description: "Analyze scene dependencies", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." } }, required: ["scene_path"] } },

  // Asset (3)
  { name: "import_texture", description: "Import a texture file into the project", inputSchema: { type: "object", properties: { source_path: { type: "string" }, dest_path: { type: "string", description: "res://..." } }, required: ["source_path", "dest_path"] } },
  { name: "import_model", description: "Import a 3D model file into the project", inputSchema: { type: "object", properties: { source_path: { type: "string" }, dest_path: { type: "string", description: "res://..." } }, required: ["source_path", "dest_path"] } },
  { name: "import_audio", description: "Import an audio file into the project", inputSchema: { type: "object", properties: { source_path: { type: "string" }, dest_path: { type: "string", description: "res://..." } }, required: ["source_path", "dest_path"] } },

  // UID (2)
  { name: "get_uid", description: "Get UID for a resource file", inputSchema: { type: "object", properties: { file_path: { type: "string", description: "res://..." } }, required: ["file_path"] } },
  { name: "update_project_uids", description: "Regenerate all project UIDs", inputSchema: { type: "object", properties: {} } },

  // Signal (6)
  { name: "connect_signal", description: "Connect a signal between nodes", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, source_node: { type: "string" }, signal_name: { type: "string" }, target_node: { type: "string" }, method_name: { type: "string" } }, required: ["scene_path", "source_node", "signal_name", "target_node", "method_name"] } },
  { name: "disconnect_signal", description: "Disconnect a signal", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, source_node: { type: "string" }, signal_name: { type: "string" }, target_node: { type: "string" }, method_name: { type: "string" } }, required: ["scene_path", "source_node", "signal_name", "target_node", "method_name"] } },
  { name: "list_signals", description: "List signals for a scene or node", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, node_path: { type: "string", description: "Optional filter" } }, required: ["scene_path"] } },
  { name: "emit_signal", description: "Emit a signal for testing", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, node_path: { type: "string" }, signal_name: { type: "string" }, args: { type: "array" } }, required: ["scene_path", "node_path", "signal_name"] } },
  { name: "get_signal_connections", description: "Get all signal connections in a scene", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, signal_name: { type: "string", description: "Optional filter" } }, required: ["scene_path"] } },
  { name: "analyze_signal_flow", description: "Analyze signal flow through a scene", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." } }, required: ["scene_path"] } },

  // Performance (6)
  { name: "profile_scene", description: "Profile scene performance", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, duration: { type: "number", default: 5.0 } }, required: ["scene_path"] } },
  { name: "analyze_performance", description: "Analyze project-wide performance", inputSchema: { type: "object", properties: { path: { type: "string", default: "res://" } } } },
  { name: "get_performance_report", description: "Get comprehensive performance report", inputSchema: { type: "object", properties: {} } },
  { name: "profile_script", description: "Profile script execution performance", inputSchema: { type: "object", properties: { script_path: { type: "string", description: "res://..." }, iterations: { type: "number", default: 100 } }, required: ["script_path"] } },
  { name: "analyze_memory_usage", description: "Analyze project memory usage", inputSchema: { type: "object", properties: {} } },
  { name: "detect_bottlenecks", description: "Detect performance bottlenecks", inputSchema: { type: "object", properties: { path: { type: "string", default: "res://" } } } },

  // Shader & Material (6)
  { name: "edit_shader", description: "Edit a shader file", inputSchema: { type: "object", properties: { shader_path: { type: "string", description: "res://..." }, content: { type: "string" } }, required: ["shader_path"] } },
  { name: "create_material", description: "Create a new material resource", inputSchema: { type: "object", properties: { material_path: { type: "string", description: "res://..." }, material_type: { type: "string", default: "StandardMaterial3D" } }, required: ["material_path"] } },
  { name: "edit_material", description: "Edit material properties", inputSchema: { type: "object", properties: { material_path: { type: "string", description: "res://..." }, properties: { type: "object" } }, required: ["material_path", "properties"] } },
  { name: "list_shaders", description: "List all shader files", inputSchema: { type: "object", properties: { path: { type: "string", default: "res://" } } } },
  { name: "create_shader", description: "Create a new shader file", inputSchema: { type: "object", properties: { shader_path: { type: "string", description: "res://..." }, shader_type: { type: "string", default: "spatial" } }, required: ["shader_path"] } },
  { name: "optimize_shader", description: "Analyze and suggest shader optimizations", inputSchema: { type: "object", properties: { shader_path: { type: "string", description: "res://..." } }, required: ["shader_path"] } },

  // Animation (8)
  { name: "create_animation", description: "Create a new animation", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, animation_name: { type: "string" }, length: { type: "number", default: 1.0 } }, required: ["scene_path", "animation_name"] } },
  { name: "edit_animation", description: "Edit animation properties", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, animation_name: { type: "string" }, properties: { type: "object" } }, required: ["scene_path", "animation_name"] } },
  { name: "list_animations", description: "List animations in a scene", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." } }, required: ["scene_path"] } },
  { name: "create_animation_library", description: "Create an animation library", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, library_name: { type: "string" } }, required: ["scene_path", "library_name"] } },
  { name: "add_animation_track", description: "Add a track to an animation", inputSchema: { type: "object", properties: { scene_path: { type: "string" }, animation_name: { type: "string" }, track_path: { type: "string" }, track_type: { type: "string", default: "value" } }, required: ["scene_path", "animation_name", "track_path"] } },
  { name: "edit_keyframe", description: "Edit a keyframe", inputSchema: { type: "object", properties: { scene_path: { type: "string" }, animation_name: { type: "string" }, track_index: { type: "number" }, keyframe_index: { type: "number" }, properties: { type: "object" } }, required: ["scene_path", "animation_name", "track_index", "keyframe_index"] } },
  { name: "play_animation", description: "Preview an animation", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, animation_name: { type: "string" } }, required: ["scene_path", "animation_name"] } },
  { name: "export_animation", description: "Export animation data", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, animation_name: { type: "string" }, output_path: { type: "string", description: "res://..." } }, required: ["scene_path", "animation_name", "output_path"] } },

  // Export & Testing (4)
  { name: "export_mesh_library", description: "Export scene as MeshLibrary", inputSchema: { type: "object", properties: { scene_path: { type: "string", description: "res://..." }, output_path: { type: "string", description: "res://..." } }, required: ["scene_path", "output_path"] } },
  { name: "get_export_presets", description: "List export presets", inputSchema: { type: "object", properties: {} } },
  { name: "quick_test", description: "Quick headless test (10s)", inputSchema: { type: "object", properties: { timeout: { type: "number", default: 10000 } } } },
  { name: "full_test", description: "Comprehensive test with analysis", inputSchema: { type: "object", properties: { timeout: { type: "number", default: 60000 } } } }
];

// =============================================================================
// TOOL HANDLER DISPATCH
// =============================================================================

const HANDLERS = {
  "godot_version": handleGodotVersion,
  "godot_status": handleGodotStatus,
  "launch_editor": (a) => launchEditor(a.project_path).then(jsonContent),
  "run_project": (a) => runProject({ headless: a.headless, timeout: a.timeout }).then(jsonContent),
  "stop_project": () => jsonContent(stopProject()),
  "get_debug_output": () => jsonContent(getDebugOutput()),

  "create_scene": handleCreateScene,
  "add_node": handleAddNode,
  "edit_node": handleEditNode,
  "remove_node": handleRemoveNode,
  "load_sprite": handleLoadSprite,
  "save_scene": handleSaveScene,
  "compare_scenes": handleCompareScenes,

  "read_script": handleReadScript,
  "edit_script": handleEditScript,
  "create_script": handleCreateScript,
  "list_scripts": handleListScripts,
  "analyze_script": handleAnalyzeScript,
  "find_script_references": handleFindScriptReferences,
  "refactor_rename": handleRefactorRename,
  "refactor_extract_method": handleRefactorExtractMethod,

  "get_project_info": handleGetProjectInfo,
  "get_project_settings": handleGetProjectSettings,
  "list_projects": handleListProjects,
  "list_scenes": handleListScenes,
  "get_scene_tree": handleGetSceneTree,
  "validate_project": handleValidateProject,
  "analyze_dependencies": handleAnalyzeDependencies,

  "import_texture": handleImportTexture,
  "import_model": handleImportModel,
  "import_audio": handleImportAudio,

  "get_uid": handleGetUid,
  "update_project_uids": handleUpdateProjectUids,

  "connect_signal": handleConnectSignal,
  "disconnect_signal": handleDisconnectSignal,
  "list_signals": handleListSignals,
  "emit_signal": handleEmitSignal,
  "get_signal_connections": handleGetSignalConnections,
  "analyze_signal_flow": handleAnalyzeSignalFlow,

  "profile_scene": handleProfileScene,
  "analyze_performance": handleAnalyzePerformance,
  "get_performance_report": handleGetPerformanceReport,
  "profile_script": handleProfileScript,
  "analyze_memory_usage": handleAnalyzeMemoryUsage,
  "detect_bottlenecks": handleDetectBottlenecks,

  "edit_shader": handleEditShader,
  "create_material": handleCreateMaterial,
  "edit_material": handleEditMaterial,
  "list_shaders": handleListShaders,
  "create_shader": handleCreateShader,
  "optimize_shader": handleOptimizeShader,

  "create_animation": handleCreateAnimation,
  "edit_animation": handleEditAnimation,
  "list_animations": handleListAnimations,
  "create_animation_library": handleCreateAnimationLibrary,
  "add_animation_track": handleAddAnimationTrack,
  "edit_keyframe": handleEditKeyframe,
  "play_animation": handlePlayAnimation,
  "export_animation": handleExportAnimation,

  "export_mesh_library": handleExportMeshLibrary,
  "get_export_presets": handleGetExportPresets,
  "quick_test": handleQuickTest,
  "full_test": handleFullTest
};

// =============================================================================
// MCP SERVER
// =============================================================================

const rl = readline.createInterface({ input: process.stdin, output: process.stderr, terminal: false });

log("info", `Godot MCP Server v${CONFIG.VERSION} started`);
log("info", `Project: ${CONFIG.PROJECT_PATH}`);
log("info", `Read-only: ${CONFIG.READ_ONLY}`);
log("info", `Tools available: ${TOOLS.length}`);

rl.on("line", async (line) => {
  let msg;
  try { msg = JSON.parse(line); } catch { return; }
  const { id, method, params } = msg;
  try {
    if (method === "initialize") {
      successResponse(id, { protocolVersion: "2024-11-05", serverInfo: { name: "godot-mcp-toolkit", version: CONFIG.VERSION }, capabilities: { tools: {} } });
      return;
    }
    if (method === "tools/list") { successResponse(id, { tools: TOOLS }); return; }
    if (method === "tools/call") {
      const handler = HANDLERS[params.name];
      if (!handler) { errorResponse(id, `Unknown tool: ${params.name}`); return; }
      const result = await handler(params.arguments || {});
      successResponse(id, result);
      return;
    }
    if (method.startsWith("notifications/")) return;
    errorResponse(id, `Unknown method: ${method}`);
  } catch (e) {
    log("error", `Request error: ${e.message}`);
    errorResponse(id, e.message);
  }
});

rl.on("close", () => {
  log("info", "Server stopped");
  if (activeGodotProcess) activeGodotProcess.kill();
  process.exit(0);
});

process.on("SIGINT", () => { if (activeGodotProcess) activeGodotProcess.kill(); process.exit(0); });
process.on("SIGTERM", () => { if (activeGodotProcess) activeGodotProcess.kill(); process.exit(0); });
process.on("uncaughtException", (err) => {
  log("error", `Uncaught exception: ${err.message}`);
  if (activeGodotProcess) activeGodotProcess.kill();
  process.exit(1);
});
