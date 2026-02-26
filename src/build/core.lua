--- Core LLVM build logic
local M = {}

function M.build_if_missing(core_install_path, core_source_dir, cores)
    local cmd = require("cmd")
    local file = require("file")
    local cmake = require("src.cmake")
    local download = require("src.download")

    if file.exists(file.join_path(core_install_path, "bin")) then
        return
    end

    local lockfile = file.join_path(core_install_path, ".lockbuild")
    download.acquire_build_lock(lockfile)

    local build_dir = file.join_path(core_source_dir, "build")
    cmd.exec("mkdir -p " .. build_dir)

    local cmake_cmd = cmake.build_core_cmake_command(file.join_path(core_source_dir, "llvm"), core_install_path)

    cmd.exec("cd " .. build_dir .. " && " .. cmake_cmd)
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_compile_command(cores))
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_install_command())

    download.release_build_lock(lockfile)
end

return M
