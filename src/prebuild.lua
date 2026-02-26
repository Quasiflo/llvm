--- Pre-build checks for required tools
local M = {}

local CORE_REQUIRED_TOOLS = {
    { name = "cmake", help = "Install via: mise install cmake@latest" },
    { name = "ninja", help = "Install via: mise install ninja@latest" },
    {
        name = "c++",
        aliases = { "g++", "clang++", "icpc", "clang-c++" },
        help = "Install via: brew install gcc / apt install g++",
    },
}

local function find_executable(name, aliases)
    local cmd = require("cmd")
    local file = require("file")

    local candidates = { name }
    if aliases then
        for _, alias in ipairs(aliases) do
            table.insert(candidates, alias)
        end
    end

    for _, candidate in ipairs(candidates) do
        local success, path_result = pcall(cmd.exec, "which " .. candidate .. " 2>/dev/null")
        if success and path_result and not path_result.exit_code then
            return candidate
        end
    end

    return nil
end

function M.check_core_requirements()
    local logger = require("src.logger")

    logger.step("Checking build requirements...")

    local missing_cmake = not find_executable("cmake")
    local missing_ninja = not find_executable("ninja")
    local missing_compiler = not find_executable("c++", CORE_REQUIRED_TOOLS[3].aliases)

    if missing_cmake then
        error("Missing required build tool: cmake\nInstall via: mise install cmake@latest")
    end
    logger.step("cmake: found")

    if missing_ninja then
        error("Missing required build tool: ninja\nInstall via: mise install ninja@latest")
    end
    logger.step("ninja: found")

    if missing_compiler then
        error("Missing required build tool: c++ compiler\nInstall via: brew install gcc / apt install g++")
    end
    logger.step("c++ compiler: found")

    logger.success("All core build requirements satisfied")

    return true
end

function M.check_tool_requirements(tool_name, tool_config)
    if not tool_config.required_tools then
        return true
    end

    for _, tool in ipairs(tool_config.required_tools) do
        local found = find_executable(tool.name, tool.aliases)
        if not found then
            local help_msg = tool.help or ("Install " .. tool.name .. " to build " .. tool_name)
            error("Missing required tool for " .. tool_name .. ": " .. tool.name .. "\n" .. help_msg)
        end
    end

    return true
end

function M.check_all_requirements(tool_name, tool_config)
    M.check_core_requirements()
    M.check_tool_requirements(tool_name, tool_config)
    return true
end

return M
