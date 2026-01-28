#!/usr/bin/env node

/**
 * Godot MCP Server v2.0.0
 * A secure, comprehensive MCP server for Godot game engine integration
 *
 * Security Features:
 * - Path traversal protection
 * - Input validation and sanitization
 * - Read-only mode support
 * - Configurable timeouts
 * - Safe process management
 *
 * @license MIT
 * @author Godot MCP Contributors
 */

import { spawn } from "child_process";
import { readFileSync, existsSync, readdirSync } from "fs";
import { join, dirname, basename, resolve, normalize, isAbsolute } from "path";
import readline from "readline";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// =============================================================================
// CONFIGURATION
// =============================================================================

const CONFIG = {
  VERSION: "2.0.0",
  GODOT_PATH: process.env.GODOT_PATH || findGodotExecutable(),
  PROJECT_PATH: sanitizePath(process.env.PROJECT_PATH || process.cwd()),
  DEBUG: process.env.DEBUG === "true" || process.argv.includes("--debug"),
  READ_ONLY: process.env.READ_ONLY_MODE === "true",
  MAX_TIMEOUT: 300000, // 5 minutes max
  MIN_TIMEOUT: 1000,   // 1 second min
  MAX_SEARCH_DEPTH: 3,
  MAX_OUTPUT_SIZE: 100000 // 100KB max output buffer
};

// =============================================================================
// SECURITY UTILITIES
// =============================================================================

/**
 * Find Godot executable in common locations
 */
function findGodotExecutable() {
  const commonPaths = [
    // Windows
    "C:\\Program Files\\Godot\\Godot_v4.3-stable_win64.exe",
    "C:\\Program Files\\Godot\\Godot.exe",
    "C:\\Program Files (x86)\\Godot\\Godot.exe",
    // macOS
    "/Applications/Godot.app/Contents/MacOS/Godot",
    "/usr/local/bin/godot",
    // Linux
    "/usr/bin/godot",
    "/usr/local/bin/godot",
    "/snap/bin/godot"
  ];

  for (const p of commonPaths) {
    if (existsSync(p)) {
      return p;
    }
  }

  // Return "godot" and hope it's in PATH
  return "godot";
}

/**
 * Sanitize and validate a file path
 * Prevents path traversal attacks
 */
function sanitizePath(inputPath) {
  if (!inputPath || typeof inputPath !== "string") {
    return null;
  }

  // Normalize the path
  let cleaned = normalize(inputPath);

  // Remove any null bytes (security)
  cleaned = cleaned.replace(/\0/g, "");

  // Convert backslashes to forward slashes for consistency
  cleaned = cleaned.replace(/\\/g, "/");

  return cleaned;
}

/**
 * Validate that a path is within the allowed project directory
 * Prevents directory traversal attacks
 */
function isPathWithinProject(targetPath, projectPath = CONFIG.PROJECT_PATH) {
  if (!targetPath || !projectPath) {
    return false;
  }

  const resolvedTarget = resolve(projectPath, targetPath);
  const resolvedProject = resolve(projectPath);

  // Ensure the resolved path starts with the project path
  return resolvedTarget.startsWith(resolvedProject);
}

/**
 * Validate a Godot resource path (res://...)
 */
function validateResourcePath(resPath) {
  if (!resPath || typeof resPath !== "string") {
    return { valid: false, error: "Path is required" };
  }

  // Must start with res:// for Godot resource paths
  if (!resPath.startsWith("res://")) {
    return { valid: false, error: "Path must start with res://" };
  }

  // Check for path traversal attempts
  if (resPath.includes("..") || resPath.includes("./")) {
    return { valid: false, error: "Path traversal not allowed" };
  }

  // Check for suspicious characters
  const suspiciousPattern = /[<>:"|?*\x00-\x1f]/;
  if (suspiciousPattern.test(resPath)) {
    return { valid: false, error: "Invalid characters in path" };
  }

  return { valid: true, path: resPath };
}

/**
 * Validate and clamp a timeout value
 */
function validateTimeout(timeout) {
  const t = parseInt(timeout, 10);
  if (isNaN(t)) {
    return CONFIG.MIN_TIMEOUT;
  }
  return Math.max(CONFIG.MIN_TIMEOUT, Math.min(t, CONFIG.MAX_TIMEOUT));
}

/**
 * Sanitize a node name (alphanumeric, underscores, hyphens only)
 */
function sanitizeNodeName(name) {
  if (!name || typeof name !== "string") {
    return null;
  }
  // Allow alphanumeric, underscores, hyphens, and spaces
  return name.replace(/[^a-zA-Z0-9_\- ]/g, "").substring(0, 64);
}

/**
 * Validate a Godot node type
 */
function validateNodeType(nodeType) {
  if (!nodeType || typeof nodeType !== "string") {
    return { valid: false, error: "Node type is required" };
  }

  // Whitelist of common safe node types
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
    "RayCast2D", "RayCast3D", "ShapeCast2D", "ShapeCast3D"
  ];

  // Check if it's in the whitelist or looks like a valid class name
  const isValidClassName = /^[A-Z][a-zA-Z0-9]*$/.test(nodeType);

  if (safeNodeTypes.includes(nodeType) || isValidClassName) {
    return { valid: true, type: nodeType };
  }

  return { valid: false, error: `Invalid or unsupported node type: ${nodeType}` };
}

// =============================================================================
// LOGGING
// =============================================================================

function log(level, message, data = null) {
  if (level === "debug" && !CONFIG.DEBUG) return;

  const timestamp = new Date().toISOString();
  const prefix = `[${timestamp}] [godot-mcp] [${level.toUpperCase()}]`;

  // Sanitize log data to prevent log injection
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

function send(obj) {
  process.stdout.write(JSON.stringify(obj) + "\n");
}

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
  // Prevent buffer overflow
  if (outputBuffer.totalSize > CONFIG.MAX_OUTPUT_SIZE) {
    return;
  }
  const truncated = text.substring(0, CONFIG.MAX_OUTPUT_SIZE - outputBuffer.totalSize);
  array.push(truncated);
  outputBuffer.totalSize += truncated.length;
}

// =============================================================================
// GODOT OPERATIONS
// =============================================================================

async function getGodotVersion() {
  return new Promise((resolve) => {
    const godot = spawn(CONFIG.GODOT_PATH, ["--version"], {
      timeout: 10000,
      windowsHide: true
    });

    let version = "";

    godot.stdout.on("data", (data) => {
      version += data.toString().substring(0, 100);
    });

    godot.on("close", () => {
      resolve(version.trim() || "unknown");
    });

    godot.on("error", () => {
      resolve("error: could not run godot");
    });

    setTimeout(() => {
      godot.kill();
      resolve(version.trim() || "timeout");
    }, 10000);
  });
}

async function launchEditor(projectPath) {
  const safePath = sanitizePath(projectPath) || CONFIG.PROJECT_PATH;

  if (!existsSync(join(safePath, "project.godot"))) {
    return { success: false, error: "No project.godot found at specified path" };
  }

  return new Promise((resolve, reject) => {
    log("info", `Launching Godot editor for: ${safePath}`);

    const godot = spawn(CONFIG.GODOT_PATH, ["--path", safePath, "--editor"], {
      detached: true,
      stdio: "ignore",
      windowsHide: false
    });

    godot.unref();

    setTimeout(() => {
      resolve({
        success: true,
        message: `Editor launched for ${basename(safePath)}`,
        pid: godot.pid
      });
    }, 1000);

    godot.on("error", (err) => {
      resolve({ success: false, error: err.message });
    });
  });
}

async function runProject(options = {}) {
  const { headless = false, timeout = 30000 } = options;
  const safeTimeout = validateTimeout(timeout);

  return new Promise((resolve) => {
    clearOutputBuffer();
    const startTime = Date.now();

    const args = ["--path", CONFIG.PROJECT_PATH];
    if (headless) {
      args.push("--headless");
      args.push("--quit-after", String(Math.floor(safeTimeout / 1000)));
    }

    log("info", `Running project`, { headless, timeout: safeTimeout });

    const godot = spawn(CONFIG.GODOT_PATH, args, { windowsHide: true });
    activeGodotProcess = godot;

    godot.stdout.on("data", (data) => {
      const text = data.toString();
      appendToBuffer(outputBuffer.stdout, text);
      parseOutputForErrors(text);
    });

    godot.stderr.on("data", (data) => {
      const text = data.toString();
      appendToBuffer(outputBuffer.stderr, text);
      appendToBuffer(outputBuffer.errors, text.trim());
    });

    godot.on("close", (code) => {
      activeGodotProcess = null;
      resolve({
        success: code === 0,
        exitCode: code,
        duration: Date.now() - startTime,
        stdout: outputBuffer.stdout.join(""),
        stderr: outputBuffer.stderr.join(""),
        errors: outputBuffer.errors,
        warnings: outputBuffer.warnings
      });
    });

    godot.on("error", (err) => {
      activeGodotProcess = null;
      resolve({ success: false, error: err.message });
    });

    // Safety timeout
    setTimeout(() => {
      if (godot && !godot.killed) {
        godot.kill("SIGTERM");
        setTimeout(() => {
          if (!godot.killed) godot.kill("SIGKILL");
        }, 2000);
      }
    }, safeTimeout + 5000);
  });
}

function stopProject() {
  if (activeGodotProcess && !activeGodotProcess.killed) {
    log("info", "Stopping active Godot process");
    activeGodotProcess.kill("SIGTERM");

    setTimeout(() => {
      if (activeGodotProcess && !activeGodotProcess.killed) {
        activeGodotProcess.kill("SIGKILL");
      }
    }, 2000);

    return { stopped: true, message: "Process terminated" };
  }
  return { stopped: false, message: "No active process" };
}

function getDebugOutput() {
  return {
    stdout: outputBuffer.stdout.join(""),
    stderr: outputBuffer.stderr.join(""),
    errors: outputBuffer.errors,
    warnings: outputBuffer.warnings,
    errorCount: outputBuffer.errors.length,
    warningCount: outputBuffer.warnings.length
  };
}

function parseOutputForErrors(text) {
  const lines = text.split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.includes("ERROR") || trimmed.includes("SCRIPT ERROR")) {
      appendToBuffer(outputBuffer.errors, trimmed);
    }
    if (trimmed.includes("WARNING") || trimmed.includes("SCRIPT WARNING")) {
      appendToBuffer(outputBuffer.warnings, trimmed);
    }
  }
}

// =============================================================================
// GDSCRIPT OPERATIONS
// =============================================================================

async function runGDScriptOperation(operation, params) {
  if (CONFIG.READ_ONLY && !["get_uid", "get_project_settings", "get_scene_tree", "list_scenes", "list_scripts", "validate_project"].includes(operation)) {
    throw new Error("Operation not allowed in read-only mode");
  }

  const gdscriptPath = join(dirname(__dirname), "addons", "godot_mcp", "godot_operations.gd");

  if (!existsSync(gdscriptPath)) {
    throw new Error("GDScript operations file not found. Please ensure addons/godot_mcp/godot_operations.gd exists.");
  }

  return new Promise((resolve, reject) => {
    const paramsJson = JSON.stringify(params);
    const args = [
      "--headless",
      "--path", CONFIG.PROJECT_PATH,
      "--script", gdscriptPath,
      operation,
      paramsJson
    ];

    log("debug", `Running GDScript operation: ${operation}`);

    const godot = spawn(CONFIG.GODOT_PATH, args, { windowsHide: true });
    let stdout = "";
    let stderr = "";

    godot.stdout.on("data", (data) => {
      stdout += data.toString().substring(0, CONFIG.MAX_OUTPUT_SIZE);
    });

    godot.stderr.on("data", (data) => {
      stderr += data.toString().substring(0, CONFIG.MAX_OUTPUT_SIZE);
    });

    godot.on("close", (code) => {
      resolve({ success: code === 0, output: stdout, stderr, exitCode: code });
    });

    godot.on("error", (err) => {
      resolve({ success: false, error: err.message });
    });

    setTimeout(() => {
      if (!godot.killed) {
        godot.kill();
        resolve({ success: false, error: "Operation timed out" });
      }
    }, 60000);
  });
}

// =============================================================================
// SCENE OPERATIONS
// =============================================================================

async function createScene(scenePath, rootNodeType = "Node2D") {
  const pathValidation = validateResourcePath(scenePath);
  if (!pathValidation.valid) {
    return { success: false, error: pathValidation.error };
  }

  const typeValidation = validateNodeType(rootNodeType);
  if (!typeValidation.valid) {
    return { success: false, error: typeValidation.error };
  }

  return runGDScriptOperation("create_scene", {
    scene_path: pathValidation.path,
    root_node_type: typeValidation.type
  });
}

async function addNode(scenePath, nodeName, nodeType, parentPath = "root", properties = {}) {
  const pathValidation = validateResourcePath(scenePath);
  if (!pathValidation.valid) {
    return { success: false, error: pathValidation.error };
  }

  const safeName = sanitizeNodeName(nodeName);
  if (!safeName) {
    return { success: false, error: "Invalid node name" };
  }

  const typeValidation = validateNodeType(nodeType);
  if (!typeValidation.valid) {
    return { success: false, error: typeValidation.error };
  }

  return runGDScriptOperation("add_node", {
    scene_path: pathValidation.path,
    node_name: safeName,
    node_type: typeValidation.type,
    parent_node_path: sanitizeNodeName(parentPath) || "root",
    properties: properties || {}
  });
}

async function editNode(scenePath, nodePath, properties) {
  const pathValidation = validateResourcePath(scenePath);
  if (!pathValidation.valid) {
    return { success: false, error: pathValidation.error };
  }

  return runGDScriptOperation("edit_node", {
    scene_path: pathValidation.path,
    node_path: nodePath,
    properties: properties || {}
  });
}

async function removeNode(scenePath, nodePath) {
  const pathValidation = validateResourcePath(scenePath);
  if (!pathValidation.valid) {
    return { success: false, error: pathValidation.error };
  }

  return runGDScriptOperation("remove_node", {
    scene_path: pathValidation.path,
    node_path: nodePath
  });
}

async function loadSprite(scenePath, nodePath, texturePath) {
  const sceneValidation = validateResourcePath(scenePath);
  if (!sceneValidation.valid) {
    return { success: false, error: sceneValidation.error };
  }

  const textureValidation = validateResourcePath(texturePath);
  if (!textureValidation.valid) {
    return { success: false, error: textureValidation.error };
  }

  return runGDScriptOperation("load_sprite", {
    scene_path: sceneValidation.path,
    node_path: nodePath,
    texture_path: textureValidation.path
  });
}

async function saveScene(scenePath, newPath = null) {
  const pathValidation = validateResourcePath(scenePath);
  if (!pathValidation.valid) {
    return { success: false, error: pathValidation.error };
  }

  const params = { scene_path: pathValidation.path };

  if (newPath) {
    const newPathValidation = validateResourcePath(newPath);
    if (!newPathValidation.valid) {
      return { success: false, error: newPathValidation.error };
    }
    params.new_path = newPathValidation.path;
  }

  return runGDScriptOperation("save_scene", params);
}

// =============================================================================
// UID OPERATIONS
// =============================================================================

async function getUid(filePath) {
  const pathValidation = validateResourcePath(filePath);
  if (!pathValidation.valid) {
    return { success: false, error: pathValidation.error };
  }

  return runGDScriptOperation("get_uid", { file_path: pathValidation.path });
}

async function updateProjectUids() {
  return runGDScriptOperation("resave_resources", { project_path: "" });
}

// =============================================================================
// PROJECT ANALYSIS
// =============================================================================

function listProjects(searchPath) {
  const safePath = sanitizePath(searchPath) || CONFIG.PROJECT_PATH;
  const projects = [];

  function searchDir(dir, depth = 0) {
    if (depth > CONFIG.MAX_SEARCH_DEPTH) return;

    try {
      const entries = readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        if (entry.name === "project.godot") {
          projects.push({ path: dir, name: basename(dir) });
          return;
        }

        if (entry.isDirectory() && !entry.name.startsWith(".") && entry.name !== "node_modules") {
          searchDir(join(dir, entry.name), depth + 1);
        }
      }
    } catch {
      // Ignore permission errors
    }
  }

  if (existsSync(join(safePath, "project.godot"))) {
    projects.push({ path: safePath, name: basename(safePath) });
  } else {
    searchDir(safePath);
  }

  return projects;
}

function getProjectInfo(projectPath) {
  const safePath = sanitizePath(projectPath) || CONFIG.PROJECT_PATH;
  const projectFile = join(safePath, "project.godot");

  if (!existsSync(projectFile)) {
    throw new Error("No project.godot found");
  }

  const content = readFileSync(projectFile, "utf-8");
  const info = {
    path: safePath,
    name: basename(safePath),
    mainScene: null,
    autoloads: [],
    features: []
  };

  const lines = content.split("\n");
  let currentSection = "";

  for (const line of lines) {
    if (line.startsWith("[")) {
      currentSection = line.slice(1, -1);
      continue;
    }

    if (currentSection === "application") {
      if (line.includes("config/name")) {
        const match = line.match(/="([^"]+)"/);
        if (match) info.name = match[1];
      }
      if (line.includes("run/main_scene")) {
        const match = line.match(/="([^"]+)"/);
        if (match) info.mainScene = match[1];
      }
    }

    if (currentSection === "autoload") {
      const match = line.match(/(\w+)="([^"]+)"/);
      if (match) {
        info.autoloads.push({ name: match[1], path: match[2] });
      }
    }
  }

  return info;
}

function analyzeProject(projectPath) {
  const safePath = sanitizePath(projectPath) || CONFIG.PROJECT_PATH;
  const analysis = {
    scripts: { total: 0 },
    scenes: { total: 0, list: [] },
    resources: { total: 0 }
  };

  function scanDir(dir, depth = 0) {
    if (depth > 10) return; // Prevent infinite recursion

    try {
      const entries = readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        if (entry.isDirectory()) {
          if (!entry.name.startsWith(".") && entry.name !== "addons" && entry.name !== ".godot") {
            scanDir(join(dir, entry.name), depth + 1);
          }
        } else {
          if (entry.name.endsWith(".gd")) analysis.scripts.total++;
          else if (entry.name.endsWith(".tscn")) {
            analysis.scenes.total++;
            if (analysis.scenes.list.length < 50) {
              analysis.scenes.list.push(entry.name);
            }
          }
          else if (entry.name.endsWith(".tres") || entry.name.endsWith(".res")) {
            analysis.resources.total++;
          }
        }
      }
    } catch {
      // Ignore errors
    }
  }

  scanDir(safePath);
  return analysis;
}

// =============================================================================
// ERROR ANALYSIS
// =============================================================================

function categorizeErrors(errors) {
  const categories = {
    scriptErrors: [],
    resourceErrors: [],
    nullReferenceErrors: [],
    typeErrors: [],
    parseErrors: [],
    other: []
  };

  for (const err of errors.slice(0, 100)) { // Limit to 100 errors
    if (err.includes("null") || err.includes("Null")) {
      categories.nullReferenceErrors.push(err);
    } else if (err.includes("SCRIPT ERROR") || err.includes("Parse Error")) {
      categories[err.includes("Parse Error") ? "parseErrors" : "scriptErrors"].push(err);
    } else if (err.includes("Resource") || err.includes("Failed to load")) {
      categories.resourceErrors.push(err);
    } else if (err.includes("type") || err.includes("cannot be assigned")) {
      categories.typeErrors.push(err);
    } else {
      categories.other.push(err);
    }
  }

  return categories;
}

async function quickTest(timeout = 10000) {
  const result = await runProject({ headless: true, timeout: validateTimeout(timeout) });
  const categories = categorizeErrors(result.errors || []);

  return {
    status: (result.errors?.length || 0) === 0 ? "PASS" : "FAIL",
    duration: result.duration,
    errorCount: result.errors?.length || 0,
    warningCount: result.warnings?.length || 0,
    categories,
    criticalErrors: categories.parseErrors.length + categories.nullReferenceErrors.length
  };
}

async function fullTest(timeout = 60000) {
  const result = await runProject({ headless: true, timeout: validateTimeout(timeout) });
  const categories = categorizeErrors(result.errors || []);

  let projectInfo = {};
  let analysis = {};

  try {
    projectInfo = getProjectInfo();
    analysis = analyzeProject();
  } catch {
    // Ignore if project info fails
  }

  return {
    project: projectInfo,
    analysis,
    runtime: {
      status: (result.errors?.length || 0) === 0 ? "PASS" : "FAIL",
      duration: result.duration,
      exitCode: result.exitCode
    },
    errors: {
      total: result.errors?.length || 0,
      categories
    },
    warnings: {
      total: result.warnings?.length || 0,
      list: (result.warnings || []).slice(0, 20)
    }
  };
}

// =============================================================================
// TOOL DEFINITIONS
// =============================================================================

const TOOLS = [
  {
    name: "godot_version",
    description: "Get the installed Godot version",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "godot_status",
    description: "Get current MCP server status and configuration",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "launch_editor",
    description: "Launch the Godot editor for the project",
    inputSchema: {
      type: "object",
      properties: {
        project_path: { type: "string", description: "Path to Godot project (optional)" }
      }
    }
  },
  {
    name: "run_project",
    description: "Run the Godot project and capture output",
    inputSchema: {
      type: "object",
      properties: {
        headless: { type: "boolean", description: "Run in headless mode", default: false },
        timeout: { type: "number", description: "Timeout in milliseconds (1000-300000)", default: 30000 }
      }
    }
  },
  {
    name: "stop_project",
    description: "Stop the currently running Godot project",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "get_debug_output",
    description: "Get captured debug output from running project",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "list_projects",
    description: "List Godot projects in a directory",
    inputSchema: {
      type: "object",
      properties: {
        search_path: { type: "string", description: "Directory to search" }
      }
    }
  },
  {
    name: "get_project_info",
    description: "Get detailed information about a Godot project",
    inputSchema: {
      type: "object",
      properties: {
        project_path: { type: "string", description: "Path to Godot project (optional)" }
      }
    }
  },
  {
    name: "analyze_project",
    description: "Analyze project structure, scripts, and resources",
    inputSchema: {
      type: "object",
      properties: {
        project_path: { type: "string", description: "Path to Godot project (optional)" }
      }
    }
  },
  {
    name: "create_scene",
    description: "Create a new Godot scene with specified root node type",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: { type: "string", description: "Path for new scene (res://...)" },
        root_node_type: { type: "string", description: "Type of root node", default: "Node2D" }
      },
      required: ["scene_path"]
    }
  },
  {
    name: "add_node",
    description: "Add a new node to an existing scene",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: { type: "string", description: "Path to scene (res://...)" },
        node_name: { type: "string", description: "Name for new node" },
        node_type: { type: "string", description: "Type of node to add" },
        parent_path: { type: "string", description: "Path to parent node", default: "root" },
        properties: { type: "object", description: "Node properties to set" }
      },
      required: ["scene_path", "node_name", "node_type"]
    }
  },
  {
    name: "edit_node",
    description: "Edit properties of an existing node in a scene",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: { type: "string", description: "Path to scene (res://...)" },
        node_path: { type: "string", description: "Path to node within scene" },
        properties: { type: "object", description: "Properties to update" }
      },
      required: ["scene_path", "node_path", "properties"]
    }
  },
  {
    name: "remove_node",
    description: "Remove a node from a scene",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: { type: "string", description: "Path to scene (res://...)" },
        node_path: { type: "string", description: "Path to node to remove" }
      },
      required: ["scene_path", "node_path"]
    }
  },
  {
    name: "load_sprite",
    description: "Load a texture into a Sprite2D node",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: { type: "string", description: "Path to scene (res://...)" },
        node_path: { type: "string", description: "Path to sprite node" },
        texture_path: { type: "string", description: "Path to texture file (res://...)" }
      },
      required: ["scene_path", "node_path", "texture_path"]
    }
  },
  {
    name: "save_scene",
    description: "Save a scene, optionally to a new path",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: { type: "string", description: "Path to scene (res://...)" },
        new_path: { type: "string", description: "New path to save as (res://...)" }
      },
      required: ["scene_path"]
    }
  },
  {
    name: "get_uid",
    description: "Get the UID for a resource file (Godot 4.4+)",
    inputSchema: {
      type: "object",
      properties: {
        file_path: { type: "string", description: "Path to resource file (res://...)" }
      },
      required: ["file_path"]
    }
  },
  {
    name: "update_project_uids",
    description: "Update all UID references in the project",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "quick_test",
    description: "Run a quick headless test and report errors",
    inputSchema: {
      type: "object",
      properties: {
        timeout: { type: "number", description: "Timeout in ms (1000-300000)", default: 10000 }
      }
    }
  },
  {
    name: "full_test",
    description: "Run a comprehensive test with full analysis",
    inputSchema: {
      type: "object",
      properties: {
        timeout: { type: "number", description: "Timeout in ms (1000-300000)", default: 60000 }
      }
    }
  }
];

// =============================================================================
// TOOL HANDLER
// =============================================================================

async function handleToolCall(name, args = {}) {
  log("debug", `Tool call: ${name}`);

  try {
    switch (name) {
      case "godot_version":
        return jsonContent({ version: await getGodotVersion(), path: CONFIG.GODOT_PATH });

      case "godot_status":
        return jsonContent({
          version: CONFIG.VERSION,
          godotPath: CONFIG.GODOT_PATH,
          projectPath: CONFIG.PROJECT_PATH,
          readOnlyMode: CONFIG.READ_ONLY,
          debugMode: CONFIG.DEBUG,
          activeProcess: activeGodotProcess !== null
        });

      case "launch_editor":
        return jsonContent(await launchEditor(args.project_path));

      case "run_project":
        return jsonContent(await runProject({ headless: args.headless, timeout: args.timeout }));

      case "stop_project":
        return jsonContent(stopProject());

      case "get_debug_output":
        return jsonContent(getDebugOutput());

      case "list_projects":
        return jsonContent(listProjects(args.search_path));

      case "get_project_info":
        return jsonContent(getProjectInfo(args.project_path));

      case "analyze_project":
        return jsonContent(analyzeProject(args.project_path));

      case "create_scene":
        return jsonContent(await createScene(args.scene_path, args.root_node_type));

      case "add_node":
        return jsonContent(await addNode(args.scene_path, args.node_name, args.node_type, args.parent_path, args.properties));

      case "edit_node":
        return jsonContent(await editNode(args.scene_path, args.node_path, args.properties));

      case "remove_node":
        return jsonContent(await removeNode(args.scene_path, args.node_path));

      case "load_sprite":
        return jsonContent(await loadSprite(args.scene_path, args.node_path, args.texture_path));

      case "save_scene":
        return jsonContent(await saveScene(args.scene_path, args.new_path));

      case "get_uid":
        return jsonContent(await getUid(args.file_path));

      case "update_project_uids":
        return jsonContent(await updateProjectUids());

      case "quick_test":
        return jsonContent(await quickTest(args.timeout));

      case "full_test":
        return jsonContent(await fullTest(args.timeout));

      default:
        return jsonContent({ error: `Unknown tool: ${name}` });
    }
  } catch (e) {
    log("error", `Tool error: ${name}`, { error: e.message });
    return jsonContent({ error: e.message, tool: name });
  }
}

// =============================================================================
// MCP SERVER
// =============================================================================

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stderr,
  terminal: false
});

log("info", `Godot MCP Server v${CONFIG.VERSION} started`);
log("info", `Project: ${CONFIG.PROJECT_PATH}`);
log("info", `Read-only: ${CONFIG.READ_ONLY}`);

rl.on("line", async (line) => {
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    return;
  }

  const { id, method, params } = msg;

  try {
    if (method === "initialize") {
      successResponse(id, {
        protocolVersion: "2024-11-05",
        serverInfo: { name: "godot-mcp", version: CONFIG.VERSION },
        capabilities: { tools: {} }
      });
      return;
    }

    if (method === "tools/list") {
      successResponse(id, { tools: TOOLS });
      return;
    }

    if (method === "tools/call") {
      const result = await handleToolCall(params.name, params.arguments || {});
      successResponse(id, result);
      return;
    }

    if (method.startsWith("notifications/")) {
      return;
    }

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

process.on("SIGINT", () => {
  if (activeGodotProcess) activeGodotProcess.kill();
  process.exit(0);
});

process.on("SIGTERM", () => {
  if (activeGodotProcess) activeGodotProcess.kill();
  process.exit(0);
});

process.on("uncaughtException", (err) => {
  log("error", `Uncaught exception: ${err.message}`);
  if (activeGodotProcess) activeGodotProcess.kill();
  process.exit(1);
});
