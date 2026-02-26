# AGENTS.md - LLVM Backend Plugin for Mise

This is a **mise backend plugin** that manages LLVM toolchain installations (clang, lld, mlir, etc.). It follows the vfox-style backend architecture and builds LLVM from source.

## Build / Lint / Test Commands

### Running Tests

```bash
# Run the full test suite (links plugin, clears cache, tests version listing and installation)
mise run test

# Clear mise cache
mise run cache-clear

# Run a single test tool manually
mise ls-remote llvm:clang          # Test version listing
mise install llvm:clang@latest     # Test installation
mise exec llvm:clang@latest -- clang --version  # Test execution
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

## Supported Tools

The plugin currently supports building these LLVM tools from source:

| Tool | Project | Binary | Notes |
|------|---------|--------|-------|
| `clang` | clang | clang | C/C++ compiler |
| `lld` | lld | lld | Linker |
| `mlir` | mlir | mlir | Multi-Level IR |
| `bolt` | bolt | llvm-bolt | Bolt optimizer |
| `polly` | polly | polly | Polyhedral optimizations |
| `compiler-rt` | compiler-rt | | Runtime libraries |
| `libc` | libc | libc | C standard library |
| `libcxx` | libcxx | libcxx | C++ standard library |
| `libunwind` | libunwind | libunwind | Unwinding library |
| `openmp` | openmp | openmp | OpenMP runtime |

## Architecture

### Installation Flow
1. **Pre-build check**: Validates cmake, ninja, and C++ compiler are installed
2. **Download**: Fetches LLVM source tarball from GitHub releases (with locking)
3. **Extract**: Extracts source to download directory
4. **Core build**: Builds core LLVM libraries first (shared across tools)
5. **Tool build**: Builds requested tool against core libraries
6. **Install**: Installs to mise install path

### Build System
- Uses **cmake** with **ninja** for parallel builds
- Core LLVM built once, then shared across tool builds
- Supports both standard tools and runtimes (libc, libcxx, etc.)

## Code Structure

### Required Hooks (3 main hooks)
1. **`hooks/backend_list_versions.lua`** - Lists available LLVM versions from GitHub tags
2. **`hooks/backend_install.lua`** - Downloads source, builds core LLVM + requested tool
3. **`hooks/backend_exec_env.lua`** - Sets up PATH for the installed tool

| Hook | Available Variables |
|------|---------------------|
| BackendListVersions | `ctx.tool` |
| BackendInstall | `ctx.tool`, `ctx.version`, `ctx.install_path`, `ctx.download_path` |
| BackendExecEnv | `ctx.install_path`, `ctx.tool`, `ctx.version` |

### Core Modules

```
src/
├── config.lua           # Tool definitions (project name, binary, flags)
├── versions.lua        # Fetch/sort LLVM versions from GitHub
├── download.lua        # Download source tarball with locking
├── lock.lua            # Atomic lock with process health checking
├── cmake.lua           # CMake command builders
├── prebuild.lua        # Pre-build requirements validation
├── util.lua            # Utilities (escape_magic, get_parallel_cores)
└── build/
    ├── core.lua        # Core LLVM build logic
    ├── tool.lua        # Tool-specific build logic
    └── prebuilt.lua    # Prebuilt binary infrastructure (not yet implemented)
```

### Platform Detection
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

## Development Workflow

1. Link plugin: `mise plugin link --force llvm .`
2. Test: `mise run test`
3. Debug: `mise --debug install llvm:clang@latest`

## Requirements

### Core Build Requirements
- **cmake** - Build system generator
- **ninja** - Fast parallel build tool
- **C++ compiler** - g++, clang++, or MSVC

Install via mise:
```bash
mise install cmake@latest ninja@latest
```

### Tool-Specific Requirements
Some tools may require additional tools (documented in `src/config.lua`).

## Project Structure

```
/workspaces/llvm/
├── src/                        # Core modules
│   ├── config.lua              # Tool configuration definitions
│   ├── versions.lua            # Version fetching/parsing from GitHub
│   ├── download.lua            # Source tarball download with locking
│   ├── lock.lua                # Atomic lock with process health checking
│   ├── cmake.lua               # CMake command builders
│   ├── prebuild.lua            # Pre-build requirements validation
│   ├── util.lua                # Common utilities
│   └── build/
│       ├── core.lua            # Core LLVM build logic
│       ├── tool.lua            # Tool-specific build logic
│       └── prebuilt.lua        # Prebuilt binary infrastructure
├── hooks/                      # Backend hook implementations
│   ├── backend_list_versions.lua
│   ├── backend_install.lua
│   └── backend_exec_env.lua
├── tests/                      # Test infrastructure
├── types/                      # Lua type definitions
├── mise-tasks/test             # Test runner script
├── metadata.lua                # Plugin metadata
├── mise.toml                   # Dev tools and tasks config
├── stylua.toml                 # Formatting rules
└── .github/workflows/ci.yml    # CI pipeline
```

## Resources

- [mise Backend Plugin Docs](https://mise.jdx.dev/backend-plugin-development.html)
- [Lua Modules Reference](https://mise.jdx.dev/plugin-lua-modules.html)
- [Lua Language Server](https://luals.github.io/wiki/annotations/)
- [LLVM GitHub Releases](https://github.com/llvm/llvm-project/releases)
