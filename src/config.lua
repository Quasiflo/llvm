--- Tool configuration definitions
local M = {}

local TOOL_CONFIG = {
    ["bolt"] = {
        project = "bolt",
        bin = "llvm-bolt",
        extra_flags = "",
    },
    ["clang"] = {
        project = "clang",
        bin = "clang",
        extra_flags = "",
    },
    ["compiler-rt"] = {
        project = "compiler-rt",
        bin = "",
        extra_flags = "",
    },
    ["libc"] = {
        project = "libc",
        bin = "libc",
        extra_flags = '-DLLVM_ENABLE_RUNTIMES="libc"',
        runtime = true,
    },
    ["libcxx"] = {
        project = "libcxx",
        bin = "libcxx",
        extra_flags = '-DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind"',
        runtime = true,
    },
    ["libunwind"] = {
        project = "libunwind",
        bin = "libunwind",
        extra_flags = '-DLLVM_ENABLE_RUNTIMES="libunwind"',
        runtime = true,
    },
    ["lld"] = {
        project = "lld",
        bin = "lld",
        extra_flags = "",
    },
    ["mlir"] = {
        project = "mlir",
        bin = "mlir",
        extra_flags = "",
    },
    ["openmp"] = {
        project = "openmp",
        bin = "openmp",
        extra_flags = "",
    },
    ["polly"] = {
        project = "polly",
        bin = "polly",
        extra_flags = "-DCMAKE_CXX_STANDARD=17",
    },
}

function M.get_tool_config(tool_name)
    return TOOL_CONFIG[tool_name]
end

function M.get_available_tools()
    local tools = {}
    for k in pairs(TOOL_CONFIG) do
        table.insert(tools, k)
    end
    table.sort(tools)
    return tools
end

function M.validate_tool(tool_name)
    if not tool_name or tool_name == "" then
        error("Tool name cannot be empty")
    end
    local config = M.get_tool_config(tool_name)
    if not config then
        error("Unsupported tool: " .. tool_name .. ". Available tools: " .. table.concat(M.get_available_tools(), ", "))
    end
    return config
end

return M
