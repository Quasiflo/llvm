--- Atomic lock module with command-line based waiting and inter-process health checking
local M = {}

local DEFAULT_TIMEOUT = 300
local DEFAULT_CHECK_INTERVAL = 2

local function sleep(seconds)
    local cmd = require("cmd")
    local RUNTIME = require("RUNTIME")
    if RUNTIME.osType == "windows" then
        cmd.exec("timeout /t " .. seconds .. " /nobreak >nul")
    else
        cmd.exec("sleep " .. seconds)
    end
end

local function escape_path(path)
    return path:gsub("'", "'\\''")
end

local function read_lock_info(lock_dir)
    local cmd = require("cmd")
    local file = require("file")
    local info_path = file.join_path(lock_dir, "info")
    if not file.exists(info_path) then
        return nil
    end
    local handle = io.open(info_path, "r")
    if not handle then
        return nil
    end
    local content = handle:read("*a")
    handle:close()
    local json = require("json")
    local success, data = pcall(json.decode, content)
    if success and data then
        return data
    end
    return nil
end

local function write_lock_info(lock_dir, info)
    local file = require("file")
    local json = require("json")
    local info_path = file.join_path(lock_dir, "info")
    local handle = io.open(info_path, "w")
    if handle then
        handle:write(json.encode(info))
        handle:close()
        return true
    end
    return false
end

local function is_process_alive(pid)
    local cmd = require("cmd")
    if not pid then
        return false
    end
    local result = cmd.exec("kill -0 " .. pid .. " 2>/dev/null")
    return result.exit_code == 0
end

local function cleanup_stale_lock(lock_dir)
    local cmd = require("cmd")
    cmd.exec("rm -rf '" .. escape_path(lock_dir) .. "'")
end

function M.acquire(lock_path, opts)
    opts = opts or {}
    local timeout = opts.timeout or DEFAULT_TIMEOUT
    local check_interval = opts.check_interval or DEFAULT_CHECK_INTERVAL

    local file = require("file")
    local cmd = require("cmd")
    local lock_dir = lock_path
    local start_time = os.time()

    while os.time() - start_time < timeout do
        local mkdir_result = cmd.exec("mkdir '" .. escape_path(lock_dir) .. "' 2>/dev/null")
        if mkdir_result.exit_code == 0 then
            local info = {
                pid = tonumber(cmd.exec("echo $PPID").output:match("%d+")),
                timestamp = os.time(),
                hostname = cmd.exec("hostname").output:gsub("%s+", ""),
            }
            if write_lock_info(lock_dir, info) then
                return true
            else
                cmd.exec("rmdir '" .. escape_path(lock_dir) .. "'")
            end
        end

        local info = read_lock_info(lock_dir)
        if info then
            local owner_alive = is_process_alive(info.pid)

            if not owner_alive then
                cleanup_stale_lock(lock_dir)
                local mkdir_result = cmd.exec("mkdir '" .. escape_path(lock_dir) .. "' 2>/dev/null")
                if mkdir_result.exit_code == 0 then
                    local new_info = {
                        pid = tonumber(cmd.exec("echo $PPID").output:match("%d+")),
                        timestamp = os.time(),
                        hostname = cmd.exec("hostname").output:gsub("%s+", ""),
                    }
                    if write_lock_info(lock_dir, new_info) then
                        return true
                    else
                        cmd.exec("rmdir '" .. escape_path(lock_dir) .. "'")
                    end
                end
            end
        end

        sleep(check_interval)
    end

    error("Failed to acquire lock after " .. timeout .. " seconds: " .. lock_path)
end

function M.release(lock_path)
    local cmd = require("cmd")
    local file = require("file")
    local lock_dir = lock_path

    if not file.exists(lock_dir) then
        return true
    end

    local info = read_lock_info(lock_dir)
    local current_pid = tonumber(cmd.exec("echo $PPID").output:match("%d+"))

    if info and info.pid ~= current_pid then
        return false
    end

    cmd.exec("rm -rf '" .. escape_path(lock_dir) .. "'")
    return true
end

function M.is_locked(lock_path)
    local file = require("file")
    return file.exists(lock_path)
end

function M.get_lock_info(lock_path)
    return read_lock_info(lock_path)
end

return M
