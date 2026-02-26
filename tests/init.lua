--- Test infrastructure for LLVM backend plugin
--- This module provides testing utilities. Tests can be run using:
--- busted tests/ or lua tests/init.lua

local M = {}

function M.run_all()
    print("Running LLVM backend plugin tests...")
    print("Note: Test infrastructure is in place but no tests implemented yet.")
    return true
end

return M
