# This CMakeLists only does find_package to test our finders.
# We might want to enable some calls based on what is actually installed on the CI runner.


cmake_minimum_required(VERSION 3.13 FATAL_ERROR)
project(CMakeLibraryCITest)


list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../finders")

# find every package *twice* - this way we can see if it handles this robustly, e.g.
# not creating targets that already exist.

# First, find *without* REQUIRED - this way, we can get output from all finders, even if one fails.

find_package(GMM )
find_package(Gurobi )


# Then, repeat *with* REQUIRED:

find_package(GMM REQUIRED)
find_package(Gurobi REQUIRED)

add_subdirectory(tests)

