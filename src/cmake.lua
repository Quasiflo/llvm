--- CMake command builders
local M = {}

local DISABLE_TESTS_FLAGS =
    "-DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_BUILD_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_BUILD_TESTS=OFF"

function M.build_core_cmake_command(source_dir, install_path)
    return "cmake -S "
        .. source_dir
        .. " -B . "
        .. "-DCMAKE_BUILD_TYPE=Release "
        .. "-DCMAKE_INSTALL_PREFIX="
        .. install_path
        .. " "
        .. "-DLLVM_INSTALL_UTILS=ON "
        .. "-DLLVM_ENABLE_PROJECTS='' "
        .. "-DLLVM_INCLUDE_TOOLS=OFF "
        .. "-DLLVM_BUILD_TOOLS=OFF "
        .. DISABLE_TESTS_FLAGS
end

function M.build_tool_cmake_command(source_dir, install_path, core_install_path, extra_flags, is_runtime)
    local project_dir = is_runtime and "runtimes" or source_dir
    return "cmake -S "
        .. project_dir
        .. " -B . "
        .. "-DCMAKE_BUILD_TYPE=Release "
        .. DISABLE_TESTS_FLAGS
        .. " "
        .. "-DCMAKE_INSTALL_PREFIX="
        .. install_path
        .. " "
        .. "-DLLVM_ROOT="
        .. core_install_path
        .. " "
        .. extra_flags
end

function M.build_compile_command(cores)
    return "cmake --build . --parallel " .. cores
end

function M.build_install_command()
    return "cmake --install ."
end

return M
