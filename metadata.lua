-- metadata.lua
-- Backend plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    -- Required: Plugin name (will be the backend name users reference)
    name = "llvm",

    -- Required: Plugin version (not the tool versions)
    version = "1.0.0",

    -- Required: Brief description of the backend and tools it manages
    description = "A mise backend plugin for llvm tools, such as clang, clangd, clang-tidy etc.",

    -- Required: Plugin author/maintainer
    author = "Quasiflo",

    -- Optional: Plugin homepage/repository URL
    homepage = "https://github.com/Quasiflo/llvm",

    -- Optional: Plugin license
    license = "MIT",

    -- Optional: Important notes for users
    notes = {
        -- "Requires a c++ compiler, cmake & ninja to be installed on your system in order to build LLVM tooling. You can add these using mise",
        -- "This plugin manages tools from the LLVM ecosystem, automatically building and making available the tools you select"
    },
}
