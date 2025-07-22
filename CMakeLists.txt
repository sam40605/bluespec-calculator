cmake_minimum_required(VERSION 3.22)

project(fauna
  VERSION 0.0
  DESCRIPTION "Collection of FORMOSA GPGPU cores"
  LANGUAGES C CXX)

find_package(bluespec-cmake REQUIRED)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

set(DATA_WIDTH 64)
set(STACK_SIZE 64)

add_subdirectory(src)
add_subdirectory(tests)

bsc_bdir_path(BSC_BDIR)
list(JOIN BSC_BDIR ":" BSC_BDIR)
message(STATUS "export BSC_BDIR=${BSC_BDIR}")
