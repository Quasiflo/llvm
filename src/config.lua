--- Tool configuration definitions
local M = {}

local file = require("file")
local prefs = require("src.prefs")

local function get_clang_extra_flags(core_source_dir)
    local clang_extras = prefs.opts.clang_extras
    if clang_extras == false then
        return ""
    end
    return "-DLLVM_EXTERNAL_CLANG_TOOLS_EXTRA_SOURCE_DIR=" .. file.join_path(core_source_dir, "clang-tools-extra")
end

-- TODO update bin to toolcheck system
local function tool_configs(core_source_dir)
    local CONFIGS = {
        ["bolt"] = {
            project = "bolt",
            bin = "llvm-bolt",
            extra_flags = "",
            required_tools = {},
        },
        ["clang"] = {
            project = "clang",
            bin = "clang",
            extra_flags = get_clang_extra_flags(core_source_dir),
            required_tools = {
                --! EXAMPLE { name = "clang", aliases = {"clang-18", "clang-17"}, help = "Clang >= 15 recommended" },
            },
        },
        ["compiler-rt"] = {
            project = "compiler-rt",
            bin = "",
            extra_flags = "",
            required_tools = {},
        },
        ["libc"] = {
            project = "libc",
            bin = "libc",
            extra_flags = '-DLLVM_ENABLE_RUNTIMES="libc"',
            runtime = true,
            required_tools = {},
        },
        ["libcxx"] = {
            project = "libcxx",
            bin = "libcxx",
            extra_flags = '-DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind"',
            runtime = true,
            required_tools = {},
        },
        ["libunwind"] = {
            project = "libunwind",
            bin = "libunwind",
            extra_flags = '-DLLVM_ENABLE_RUNTIMES="libunwind"',
            runtime = true,
            required_tools = {},
        },
        ["lld"] = {
            project = "lld",
            bin = "lld",
            extra_flags = "",
            required_tools = {},
        },
        ["mlir"] = {
            project = "mlir",
            bin = "mlir",
            extra_flags = "",
            required_tools = {},
        },
        ["openmp"] = {
            project = "openmp",
            bin = "openmp",
            extra_flags = "",
            required_tools = {},
        },
        ["polly"] = {
            project = "polly",
            bin = "polly",
            extra_flags = "-DCMAKE_CXX_STANDARD=17",
            required_tools = {},
        },
        -- ["flang"] = { -- TODO error with MLIR_TABLEGEN not getting found properly for out of tree builds
        --     project = "flang",
        --     bin = "flang",
        --     extra_flags = "-DClang_DIR=" ..
        --         file.join_path(install_path:gsub(escape_magic(tool), "clang"), "lib", "cmake", "clang") ..
        --         " -DMLIR_DIR=" .. file.join_path(install_path:gsub(escape_magic(tool), "mlir"), "lib", "cmake", "mlir") ..
        --         " -DLLVM_DIR=" .. file.join_path(install_path:gsub(escape_magic(tool), "llvm"), "lib", "cmake", "llvm")
        -- },
        -- ["libclc"] = { -- TODO
        --     project = "libclc",
        --     bin = "libclc",
        --     extra_flags = "-DLLVM_ENABLE_RUNTIMES=\"libclc\"" .. "-DClang_DIR=" ..
        --         file.join_path(install_path:gsub(escape_magic(tool), "clang"), "lib", "cmake", "clang"),
        --     runtime = true
        -- },
        -- ["lldb"] = { -- TODO requires python to generate particular files at compile time (search SBLanguages.h)
        --     project = "lldb",
        --     bin = "lldb",
        --     extra_flags = "-DLLDB_INCLUDE_TESTS=OFF -DLLDB_ENABLE_PYTHON=OFF" .. " -DClang_DIR=" ..
        --         file.join_path(install_path:gsub(escape_magic(tool), "clang"), "lib", "cmake", "clang")
        -- },
        -- ["offload"] = { -- TODO test on linux (not available for other OSes)
        --     project = "offload",
        --     bin = "offload",
        --     extra_flags = ""
        -- },
    }

    return CONFIGS
end

function M.get_tool_config(tool_name, core_source_dir)
    return tool_configs(core_source_dir)[tool_name]
end

function M.get_available_tools(core_source_dir)
    local tools = {}
    for k in pairs(tool_configs(core_source_dir)) do
        table.insert(tools, k)
    end
    table.sort(tools)
    return tools
end

function M.validate_tool(tool_name, core_source_dir)
    if not tool_name or tool_name == "" then
        error("Tool name cannot be empty")
    end
    local config = M.get_tool_config(tool_name, core_source_dir)
    if not config then
        error(
            "Unsupported tool: "
                .. tool_name
                .. ". Available tools: "
                .. table.concat(M.get_available_tools(core_source_dir), ", ")
        )
    end
    return config
end

return M
