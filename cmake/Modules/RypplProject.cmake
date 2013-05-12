# Function for declaring project with dependencies
#
# Function declares new project,
#  searches and uses every depended and recommended project
#
# If all requirements are met, this function declares variable
#  RYPPL_${PROJECT_NAME}_VALID
#
# Signature:
#   ryppl_project(<proj_name> [DEPENDS <project list>] [RECOMMENDS <project list>])
#
# Parameters:
#  proj_name - required parameter, sets the name of project
# TODO add others param description
#=============================================================================
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

include(Ryppl)
include(CMakeParseArguments)


if(__RYPPL_PROJECT_INCLUDED)
  return()
endif()
set(__RYPPL_PROJECT_INCLUDED TRUE)

macro(ryppl_project proj_name)
  project(${proj_name})

  cmake_parse_arguments(var
    "" # options
    "" # one value params
    "DEPENDS;RECOMMENDS" # multi value params
    ${ARGN}
  )

  set(RYPPL_${proj_name}_VALID 1)

  foreach(proj ${var_DEPENDS})
    ryppl_find_and_use_package(${proj})
    if (NOT ${RYPPL_INITIAL_PASS})
      if (NOT ${proj}_FOUND)

        # fix compatibility issues,
        # for example PythonLibs package script set PYTHONLIBS_FOUND
        # instead of PythonLibs_FOUND
        # so check uppercase value if normal value is not set
        string(TOUPPER "${proj}_FOUND" proj_compat_found)

        if (NOT ${proj_compat_found})
          set(RYPPL_${proj_name}_VALID 0)
          list(APPEND missing_dependend_projects ${proj})
        endif()
      endif()
    endif()
  endforeach()


    foreach(proj ${var_RECOMMENDS})
    ryppl_find_and_use_package(${proj})
    if (NOT ${RYPPL_INITIAL_PASS})
      if (NOT ${proj}_FOUND)

        # fix compatibility issues,
        # for example PythonLibs package script set PYTHONLIBS_FOUND
        # instead of PythonLibs_FOUND
        # so check uppercase value if normal value is not set
        string(TOUPPER "${proj}_FOUND" proj_compat_found)

        if (NOT ${proj_compat_found})
          list(APPEND missing_recommended_projects ${proj})
        endif()
      endif()
    endif()
  endforeach()

endmacro()
