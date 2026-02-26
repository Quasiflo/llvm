--- Core LLVM build logic
local M = {}

function M.build_if_missing(core_install_path, core_source_dir, cores)
    local cmd = require("cmd")
    local file = require("file")
    local cmake = require("src.cmake")
    local lock = require("src.lock")

    if file.exists(file.join_path(core_install_path, "bin")) then
        return
    end

    local lockfile = file.join_path(core_install_path, ".lock")
    lock.acquire(lockfile, { timeout = 6000 })

    local build_dir = file.join_path(core_source_dir, "build")
    cmd.exec("mkdir -p " .. build_dir)

    local cmake_cmd = cmake.build_core_cmake_command(file.join_path(core_source_dir, "llvm"), core_install_path)

    cmd.exec("cd " .. build_dir .. " && " .. cmake_cmd)
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_compile_command(cores))
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_install_command())

    lock.release(lockfile)
end

return M
