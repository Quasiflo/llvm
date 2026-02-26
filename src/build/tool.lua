--- Tool-specific build logic
local M = {}

function M.build(tool, version, install_path, download_path, core_source_dir, core_install_path, tool_config, cores)
    local cmd = require("cmd")
    local file = require("file")
    local cmake = require("src.cmake")
    local download = require("src.download")

    local tool_bin_path = file.join_path(install_path, "bin", tool_config.bin)
    if file.exists(tool_bin_path) then
        return
    end

    cmd.exec("mkdir -p " .. install_path)

    local build_dir = file.join_path(download_path, "build")
    cmd.exec("mkdir -p " .. build_dir)

    local cmake_cmd = cmake.build_tool_cmake_command(
        core_source_dir,
        install_path,
        core_install_path,
        tool_config.extra_flags,
        tool_config.runtime
    )

    cmd.exec("cd " .. build_dir .. " && " .. cmake_cmd)

    local build_cores = (tool == "compiler-rt") and "1" or cores
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_compile_command(build_cores))
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_install_command())
end

return M
