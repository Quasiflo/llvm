--- Common utility functions used across the plugin
local M = {}

function M.escape_magic(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"))
end

function M.wait(seconds)
    local start = os.time()
    repeat
    until os.time() > start + seconds
end

function M.get_builds_path(download_path)
    return (download_path:gsub("downloads", "builds"))
end

function M.get_parallel_cores()
    local prefs = require("src.prefs")
    if prefs.opts.build_cores then
        return tostring(prefs.opts.build_cores)
    end

    local cmd = require("cmd")
    local cores_cmd = RUNTIME.osType == "linux" and "nproc" or "sysctl -n hw.ncpu"
    local cores_output = cmd.exec(cores_cmd)
    return cores_output:gsub("%s+", "")
end

return M
