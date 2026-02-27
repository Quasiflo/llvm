--- Tool-specific build logic
local M = {}

function M.build(
    tool,
    version,
    install_path,
    builds_path,
    tool_source_dir,
    core_source_path,
    core_install_path,
    tool_config,
    cores
)
    local cmd = require("cmd")
    local file = require("file")
    local cmake = require("src.cmake")
    local logger = require("src.logger")

    local tool_bin_path = file.join_path(install_path, "bin", tool_config.bin)
    if file.exists(tool_bin_path) then
        logger.skip(tool .. " already installed (using cached installation)")
        return
    end

    logger.section("Building " .. tool:upper())
    logger.step("Building " .. tool .. " " .. version .. "...")

    cmd.exec("mkdir -p " .. install_path)

    local build_dir = file.join_path(builds_path, "build")
    cmd.exec("mkdir -p " .. build_dir)

    local cmake_cmd = cmake.build_tool_cmake_command(
        tool_source_dir,
        install_path,
        core_source_path,
        core_install_path,
        tool_config.extra_flags,
        tool_config.runtime
    )
    logger.debug_cmd(cmake_cmd)

    logger.step("Configuring " .. tool .. "...")
    cmd.exec("cd " .. build_dir .. " && " .. cmake_cmd)

    local build_cores = (tool == "compiler-rt") and "1" or cores
    logger.step("Compiling " .. tool .. " (using " .. build_cores .. " parallel cores)...")
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_compile_command(build_cores))

    logger.step("Installing " .. tool .. "...")
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_install_command())

    logger.success(tool .. " " .. version .. " installed successfully")
end

return M
