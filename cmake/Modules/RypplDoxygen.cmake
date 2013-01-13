# Create a custom command to generate doxygen XML.
#
#   ryppl_doxygen(<name> [XML] [TAG]
#     [DOXYFILE <doxyfile>]
#     [INPUT <input files>]
#     [TAGFILES <tagfiles>]
#     [PARAMETERS <parameters>]
#     )

#=============================================================================
# Copyright (C) 2008 Douglas Gregor <doug.gregor@gmail.com>
# Copyright (C) 2011 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

find_package(XSLTPROC REQUIRED)
include(CMakeParseArguments)

function(ryppl_doxygen name)
  cmake_parse_arguments(DOXY
    "XML;TAG;HTML" "DOXYFILE;OUTPUT" "INPUT;TAGFILES;PARAMETERS;XSLT_PARAMETERS" ${ARGN})

  set(doxyfile ${CMAKE_CURRENT_BINARY_DIR}/${name}.doxyfile)

  if(DOXY_DOXYFILE)
    configure_file(${DOXY_DOXYFILE} ${doxyfile} COPYONLY)
  else()
    file(REMOVE ${doxyfile})
  endif()

  set(default_parameters
    "QUIET = YES"
    "WARN_IF_UNDOCUMENTED = NO"
    "GENERATE_LATEX = NO"
    "GENERATE_HTML = NO"
    "GENERATE_XML = NO"
    )

  foreach(param ${default_parameters} ${DOXY_PARAMETERS})
    file(APPEND ${doxyfile} "${param}\n")
  endforeach()

  set(output)
  if(DOXY_XML)
    set(xml_dir ${CMAKE_CURRENT_BINARY_DIR}/${name}-xml)
    list(APPEND output ${xml_dir}/index.xml ${xml_dir}/combine.xslt)
    file(APPEND ${doxyfile}
      "GENERATE_XML = YES\n"
      "XML_OUTPUT = ${xml_dir}\n"
      )
  endif()

  if(DOXY_TAG)
    list(APPEND output ${DOXY_OUTPUT})
    file(APPEND ${doxyfile} "GENERATE_TAGFILE = ${DOXY_OUTPUT}\n")
  endif()

  if (DOXY_HTML)
    get_filename_component(html_dir ${DOXY_OUTPUT} PATH)
    list(APPEND output ${DOXY_OUTPUT})
    file(APPEND ${doxyfile} "GENERATE_HTML = YES\n")
    file(APPEND ${doxyfile} "HTML_OUTPUT = ${html_dir}\n")
  endif()

  set(tagfiles)
  foreach(file ${DOXY_TAGFILES})
    get_filename_component(file ${file} ABSOLUTE)
    set(tagfiles "${tagfiles} \\\n \"${file}\"")
  endforeach()
  file(APPEND ${doxyfile} "TAGFILES = ${tagfiles}\n")

  set(input)
  foreach(file ${DOXY_INPUT})
    get_filename_component(file ${file} ABSOLUTE)
    set(input "${input} \\\n \"${file}\"")
  endforeach()
  file(APPEND ${doxyfile} "INPUT = ${input}\n")

  find_package(Doxygen REQUIRED)
  add_custom_command(OUTPUT ${output}
    COMMAND ${DOXYGEN_EXECUTABLE} ${doxyfile}
    DEPENDS ${DOXY_INPUT} ${DOXY_TAGFILES}
    )

  if(DOXY_XML)
    # Collect Doxygen XML into a single XML file
    xsltproc(
      INPUT      "${xml_dir}/index.xml"
      OUTPUT     "${DOXY_OUTPUT}"
      STYLESHEET "${xml_dir}/combine.xslt"
      PARAMETERS ${DOXY_XSLT_PARAMETERS}
    )
  endif()
endfunction()
