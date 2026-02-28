# LLVM Backend Plugin for Mise

A [mise](https://mise.jdx.dev) backend plugin that builds LLVM tools (clang, lld, mlir, etc.) from source. Based on the [vfox-style backend architecture](https://mise.jdx.dev/backend-plugin-development.html).

## Purpose

This plugin manages LLVM toolchain installations by downloading the LLVM source and building requested tools from scratch. It handles version listing, source downloading with locking, core LLVM library builds, and tool-specific compilation.

## TODO

### Done
- LLVM build system with cmake/ninja
- Version listing from GitHub releases
- Multiple tool support: clang, lld, mlir, bolt, polly, compiler-rt, libc, libcxx, libunwind, openmp
- `build_cores` option for setting symultaneous build threads
- `clang_extras` option to enable/disable clang-tools-extra
- `build_sequentially` option for serializing symultaneously requested builds
- Core build caching (built once, shared across tools)

### TODO
- Windows compatibility testing
- Download prebuilt binaries option
- Improve PATH/LIB settings in exec_env
- Add remaining LLVM tools (lldb, flang, libclc, offload)
- Better detection/skipping of already-built tools
- Comprehensive testing

## Installation

Add the plugin to your mise configuration:

```toml
[plugins]
llvm = "https://github.com/Quasiflo/llvm"
```

Then use tools:

```bash
mise use llvm:clang@latest
```

## Requirements

These tools need to be available on path for the LLVM build to succeed. You can generally use system inbuilt or global mise installed versions.

- **cmake** - Build system generator
- **ninja** - Fast parallel build tool
- **python** - Required for LLVM build system
- **C++ compiler** - g++, clang++, or MSVC


#### Install via mise:
```bash
mise use -g cmake@latest ninja@latest python@latest
```

## Available Tools

| Tool | Project | Notes |
| --- | --- | --- |
| `clang` | clang + clang-tools-extra | C/C++ compiler (+ clangd, clang-tidy etc) |
| `lld` | lld | Linker |
| `mlir` | mlir | Multi-Level IR |
| `bolt` | bolt | Bolt optimizer |
| `polly` | polly | Polyhedral optimizations |
| `compiler-rt` | compiler-rt | Runtime libraries |
| `libc` | libc | C standard library |
| `libcxx` | libcxx | C++ standard library |
| `libunwind` | libunwind | Unwinding library |
| `openmp` | openmp | OpenMP runtime |

## Variables

Configure tool builds in your mise.toml:

```toml
[tools]
"llvm:clang" = { 
version = "latest", 
build_cores = 8, # Number of parallel cores for building (Default: auto-detect)
clang_extras = false, # Enable/disable clang extra tools (clangd, clang-tidy, etc. Default: true)
build_sequentially = true # Force builds to run sequentially (useful when installing multiple tools at once)
}
```
