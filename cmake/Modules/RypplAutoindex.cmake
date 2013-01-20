# Distributed under the Boost Software License, Version 1.0.
# See http://www.boost.org/LICENSE_1_0.txt

include(Ryppl)
include(CMakeParseArguments)


ryppl_find_and_use_package(BoostAutoIndex)


# Generate index and merge it with given docbook(boostbook) XML

#  generate_index(
#    <INPUT input_file>
#    <OUTPUT output_file>
#    [NO_DUPLICATES]
#    [INTERNAL_INDEX]
#    [NO_SECTION_NAMES]
#    [SCRIPT <script file>]
#    [INDEX_TYPE <type>]
#    [PREFIX <prefix path>]
#    [DEPENDS <dependencies>]
#  )
#
# This function adds a custom command that perform generating
# index and adds it to given XML file
#
# Parameters:
#   INPUT input_file     - neccessary parameter, sets input file for generating index
#   OUTPUT output_file   - necessary parameter, sets output file which contains generated index
#   NO_DUPLICATES        - Prevents duplicate index entries within the same section
#   INTERNAL_INDEX       - Causes AutoIndex to generate the index itself, rather
#                           than relying on the XSL stylesheets
#   NO_SECTION_NAMES     - Suppresses use of section names as index entries
#   SCRIPT script_file   - Specifies the script file to use
#   INDEX_TYPE type      - Sets the XML container type to use the index
#   PREFIX path          - Sets the prefix to be prepended to all file names and
#                           paths in the script file
#   DEPENDS dependencies - Adds dependencies for target
#
# More information about parameters one may take from auto_index documentation
function(generate_index)
  cmake_parse_arguments(ryppl_autoindex
    "NO_DUPLICATES;INTERNAL_INDEX;NO_SECTION_NAMES"
    "INPUT;OUTPUT;SCRIPT;INDEX_TYPE;PREFIX" # one value params
    "DEPENDS" # multi value params
    ${ARGN}
  )

  if(NOT ryppl_autoindex_INPUT OR NOT ryppl_autoindex_OUTPUT)
    message(ERROR "INPUT and OUTPUT must be set")
  endif()

  if (ryppl_autoindex_NO_DUPLICATES)
    set(AUTOINDEX_NO_DUPLICATES_ARG "--no-duplicates")
  endif()
  if(ryppl_autoindex_INTERNAL_INDEX)
    set(AUTOINDEX_INTERNAL_INDEX_ARG "--internal-index")
  endif()
  if(ryppl_autoindex_NO_SECTION_NAMES)
    set(AUTOINDEX_NO_SECTION_NAMES_ARG "--no-section-names")
  endif()
  if(ryppl_autoindex_SCRIPT)
    set(AUTOINDEX_SCRIPT_ARG "--script=${ryppl_autoindex_SCRIPT}")
  endif()
  if(ryppl_autoindex_INDEX_TYPE)
    set(AUTOINDEX_INDEX_TYPE_ARG "--index-type=${ryppl_autoindex_INDEX_TYPE}")
  endif()
  if(ryppl_autoindex_PREFIX)
    set(AUTOINDEX_PREFIX_ARG "--prefix=${ryppl_autoindex_PREFIX}")
  endif()


  add_custom_command(
    COMMAND auto_index
      --verbose
      ${AUTOINDEX_NO_DUPLICATES_ARG}
      ${AUTOINDEX_INTERNAL_INDEX_ARG}
      ${AUTOINDEX_NO_SECTION_NAMES_ARG}
      ${AUTOINDEX_SCRIPT_ARG}
      ${AUTOINDEX_INDEX_TYPE_ARG}
      ${AUTOINDEX_PREFIX_ARG}
      "--in=${ryppl_autoindex_INPUT}"
      "--out=${ryppl_autoindex_OUTPUT}"
    OUTPUT
      ${ryppl_autoindex_OUTPUT}
    COMMENT "generating auto index for file (${ryppl_autoindex_INPUT}) ..."
    DEPENDS
      ${ryppl_autoindex_INPUT}
      ${ryppl_autoindex_DEPENDS}
  )


endfunction(generate_index)
