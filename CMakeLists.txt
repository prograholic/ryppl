#=============================================================================
# Copyright (C) 2012 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

cmake_minimum_required(VERSION 2.8.10 FATAL_ERROR)
project(Ryppl NONE)

set(CMAKE_MODULE_PATH "${Ryppl_SOURCE_DIR}/cmake/Modules")


if (${RYPPL_DISABLE_DOCS})
  # documentation disabled, does nothing
  return()
endif()

include(RypplDocumentation)

file(GLOB modules "cmake/Modules/*.cmake")


# TODO write documentation according to
#  http://www.cmake.org/Wiki/CMake_builtin_documentation_handling
set(cmake_docbook "${CMAKE_CURRENT_BINARY_DIR}/cmake.docbook")
add_custom_command(OUTPUT ${cmake_docbook}
  COMMAND ${CMAKE_COMMAND}
    -DCMAKE_MODULE_PATH="${CMAKE_MODULE_PATH}"
    --help-custom-modules ${cmake_docbook}
  DEPENDS ${modules}
)

export_documentation(
  # actually this is NOT boostbook but docbook
  BOOSTBOOK
    ${cmake_docbook}
)
