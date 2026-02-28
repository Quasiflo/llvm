# Contributing to LLVM Backend Plugin

This plugin is built in Lua 5.4 following the mise backend plugin architecture.

## Development Setup

### Prerequisites
- **cmake** - Build system generator
- **ninja** - Fast parallel build tool
- **python** - Required for LLVM build system
- **C++ compiler** - g++, clang++, or MSVC

#### Install via mise:
```bash
mise install -g cmake@latest ninja@latest python@latest
```

### Link Plugin for Development

```bash
mise plugin link --force llvm .
```

## Build / Lint / Test Commands

### Running Tests

```bash
# Run the full test suite (NEEDS WORK)
mise run test

# Clear mise cache
mise run cache-clear
```

### Linting & Formatting

```bash
# Run all linters
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

### Naming Conventions
- **Variables**: snake_case (e.g., `install_path`, `core_name`)
- **Constants**: UPPER_SNAKE_CASE for module-level constants
- **File names**: snake_case.lua (e.g., `backend_install.lua`)

### Type Annotations
Use LuaCATS annotations for IDE support:

```lua
--- @param ctx {tool: string, version: string, install_path: string} Context
--- @return {versions: string[]} Table containing list of available versions
function PLUGIN:BackendListVersions(ctx)
    -- function body
end
```

### Logging
- Use `local logger = require("src.logger")`
- `logger.step("Configuring " .. tool .. "...")`
- `logger.success("Checksum computed and saved")`
- `logger.debug("Lock owner is still alive, PID: " .. (info and info.pid))` etc.

### Error Handling
- Use `error("descriptive message")` for failures
- Validate inputs at the start of functions

## Debugging

Enable debug output:
```bash
mise --debug install llvm:clang@latest
```

## Architecture Overview

### Required Hooks (3 main hooks)
1. **`hooks/backend_list_versions.lua`** - Lists available LLVM versions from GitHub tags
2. **`hooks/backend_install.lua`** - Downloads source, builds core LLVM + requested tool
3. **`hooks/backend_exec_env.lua`** - Sets up PATH for the installed tool

### Core Modules

| File | Purpose |
|------|---------|
| `src/config.lua` | Tool definitions (project name, binary, flags) |
| `src/versions.lua` | Fetch/sort LLVM versions from GitHub |
| `src/download.lua` | Download source tarball with locking |
| `src/lock.lua` | Atomic lock with inter-process health checking |
| `src/logger.lua` | Centralized logging (milestone, step, debug, warn, success) |
| `src/cmake.lua` | CMake command builders |
| `src/prebuild.lua` | Pre-build requirements validation |
| `src/prefs.lua` | User configuration from mise.toml |
| `src/util.lua` | Utilities (escape_magic, get_parallel_cores) |
| `src/build/core.lua` | Core LLVM build logic |
| `src/build/tool.lua` | Tool-specific build logic |

## Resources

- [mise Backend Plugin Docs](https://mise.jdx.dev/backend-plugin-development.html)
- [Lua Modules Reference](https://mise.jdx.dev/plugin-lua-modules.html)
- [Lua Language Server](https://luals.github.io/wiki/annotations/)
- [LLVM GitHub Releases](https://github.com/llvm/llvm-project/releases)
