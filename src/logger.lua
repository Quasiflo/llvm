--- Centralized logging module for LLVM backend plugin
--- Provides structured logging with milestone, progress, and debug levels
local M = {}

local log = require("log")

function M.milestone(msg, ...)
    log.info("==> " .. msg, ...)
end

function M.step(msg, ...)
    log.info("    " .. msg, ...)
end

function M.debug(msg, ...)
    log.debug(msg, ...)
end

function M.debug_cmd(cmd)
    log.debug("Running: " .. cmd)
end

function M.warn(msg, ...)
    log.warn(msg, ...)
end

function M.error(msg, ...)
    log.error(msg, ...)
end

function M.section(title)
    log.info("")
    log.info("=== " .. title .. " ===")
end

function M.spinner(msg, ...)
    log.info("    " .. msg .. " ...", ...)
end

function M.success(msg, ...)
    log.info("    [OK] " .. msg, ...)
end

function M.skip(msg, ...)
    log.debug("    [SKIP] " .. msg, ...)
end

return M
