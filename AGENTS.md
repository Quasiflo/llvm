# AGENTS.md - LLVM Backend Plugin for Mise

This is a **mise backend plugin** that manages LLVM toolchain installations (clang, lld, mlir, etc.). It follows the vfox-style backend architecture.

## Build / Lint / Test Commands

### Running Tests

```bash
# Run the full test suite (links plugin, clears cache, tests version listing and installation)
mise run test

# Run a single test tool manually
mise ls-remote llvm:clangd          # Test version listing
mise install llvm:clangd@latest       # Test installation
mise exec llvm:clangd@latest -- clangd --version  # Test execution
```

### Linting & Formatting

```bash
# Run all linters (luacheck, stylua, actionlint)
mise run lint
hk check

# Auto-fix linting issues
mise run lint-fix
hk fix

# Format Lua code only
mise run format
stylua metadata.lua hooks/
```

### CI Pipeline

```bash
# Run full CI (lint + test)
mise run ci
```

## Code Style Guidelines

### Language & Runtime
- **Lua 5.4** - This is a Lua-based mise backend plugin
- Use built-in mise modules: `require("cmd")`, `require("http")`, `require("json")`, `require("file")`

### Formatting (stylua)
From `stylua.toml`:
- **Indent**: 4 spaces (no tabs)
- **Column width**: 120 characters max
- **Line endings**: Unix (LF)
- **Quote style**: AutoPreferDouble
- **Call parentheses**: Always (e.g., `table.insert()`, not `table.insert`)

### Naming Conventions
- **Hook functions**: PascalCase with `PLUGIN:` prefix (e.g., `PLUGIN:BackendListVersions`)
- **Variables**: snake_case (e.g., `install_path`, `core_name`)
- **Constants**: UPPER_SNAKE_CASE for module-level constants
- **File names**: snake_case.lua (e.g., `backend_install.lua`)

### Type Annotations
Use LuaCATS annotations for IDE support (see `types/mise-plugin.lua`):

```lua
--- @param ctx {tool: string, version: string, install_path: string} Context
--- @return {versions: string[]} Table containing list of available versions
function PLUGIN:BackendListVersions(ctx)
    -- function body
end
```

### Error Handling
- Use `error("descriptive message")` for failures
- Validate inputs at the start of functions
- Provide helpful error messages with available options:

```lua
if not tool or tool == "" then
    error("Tool name cannot be empty")
end
```

### Code Structure

#### Required Hooks (3 main hooks)
1. **`hooks/backend_list_versions.lua`** - Lists available tool versions
2. **`hooks/backend_install.lua`** - Installs a specific version
3. **`hooks/backend_exec_env.lua`** - Sets up PATH/environment variables

| Hook | Available Variables |
|------|---------------------|
| BackendListVersions | `ctx.tool` |
| BackendInstall | `ctx.tool`, `ctx.version`, `ctx.install_path`, `ctx.download_path` |
| BackendExecEnv | `ctx.install_path`, `ctx.tool`, `ctx.version` |

#### Platform Detection
```lua
if RUNTIME.osType == "linux" then
    -- Linux-specific
elseif RUNTIME.osType == "darwin" then
    -- macOS-specific
elseif RUNTIME.osType == "windows" then
    -- Windows-specific
end
```

### Imports & Module Usage
```lua
local cmd = require("cmd")    -- Execute shell commands
local file = require("file")  -- File system operations
local http = require("http")  -- HTTP client
local json = require("json")  -- JSON parsing
```
```lua
-- List versions: return {versions = {"1.0.0", "2.0.0"}}
-- Install (success): return {}
-- Environment: return {env_vars = {{key = "PATH", value = bin_path}}}

-- File operations
local path = file.join_path(dir1, dir2, "file.txt")
if file.exists(path) then end

-- Command execution
local result = cmd.exec("git ls-remote --tags https://github.com/llvm/llvm-project.git")
```

### Project Structure
```
/workspaces/llvm/
├── src/                        # Core modules
│   ├── init.lua                # Module loader
│   ├── util.lua                # Utilities (escape_magic, wait, etc.)
│   ├── versions.lua            # Version parsing/sorting
│   ├── config.lua              # Tool configuration
│   ├── cmake.lua               # CMake command builders
│   ├── download.lua            # Download logic with locking
│   └── build/
│       ├── init.lua            # Build module loader
│       ├── core.lua            # Core LLVM build
│       ├── tool.lua            # Tool-specific build
│       └── prebuilt.lua        # Prebuilt binary downloads
├── hooks/                      # Backend hook implementations
├── tests/                      # Test infrastructure
├── mise-tasks/test             # Test runner script
├── types/mise-plugin.lua       # Lua type definitions
├── metadata.lua                # Plugin metadata
├── mise.toml                   # Dev tools config
└── stylua.toml                 # Formatting rules
```

### Development Workflow
1. Link plugin: `mise plugin link --force llvm .`
2. Test: `mise run test`
3. Debug: `mise --debug install llvm:clangd@latest`

### Resources
- [mise Backend Plugin Docs](https://mise.jdx.dev/backend-plugin-development.html)
- [Lua Modules Reference](https://mise.jdx.dev/plugin-lua-modules.html)
- [Lua Language Server](https://luals.github.io/wiki/annotations/)
