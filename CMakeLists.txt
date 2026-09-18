cmake_minimum_required(VERSION 3.19)

project(AxverseV1
    VERSION 0.1.0
    DESCRIPTION "AxioGlobe Axverse Archicad V1"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(AXIOGLOBE_BUILD_TESTS "Build Axverse core tests" ON)

add_library(axverse_core STATIC
    src/core/V1ToolRegistry.cpp
)

target_include_directories(axverse_core
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

if (MSVC)
    target_compile_options(axverse_core PRIVATE /W4 /permissive-)
else()
    target_compile_options(axverse_core PRIVATE -Wall -Wextra -Wpedantic)
endif()

if (AXIOGLOBE_BUILD_TESTS)
    enable_testing()

    add_executable(axverse_core_tests
        tests/core/V1ToolRegistryTests.cpp
    )

    target_link_libraries(axverse_core_tests
        PRIVATE
            axverse_core
    )

    add_test(
        NAME axverse_core_tests
        COMMAND axverse_core_tests
    )
endif()
