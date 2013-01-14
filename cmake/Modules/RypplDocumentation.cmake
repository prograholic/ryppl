# Adds documentation for the current library or tool project
#
#   ryppl_documentation(<docbook-file>)

#=============================================================================
# Copyright (C) 2008 Douglas Gregor <doug.gregor@gmail.com>
# Copyright (C) 2011-2012 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================


if(CMAKE_HOST_WIN32)
  set(dev_null NUL)
else()
  set(dev_null /dev/null)
endif()

find_package(Boostbook QUIET)
find_package(DBLATEX QUIET)
find_package(FOProcessor QUIET)
find_package(HTMLHelp QUIET)
find_package(XSLTPROC REQUIRED)

include(RypplDoxygen)

get_filename_component(Ryppl_RESOURCE_PATH
  "${CMAKE_CURRENT_LIST_DIR}/../Resources" ABSOLUTE CACHE
  )

#include(CMakeParseArguments)

function(ryppl_documentation input)
  if(RYPPL_DISABLE_DOCS)
    return()
  endif()

  set(doc_targets)
  set(html_dir "${CMAKE_CURRENT_BINARY_DIR}/html")

  file(COPY
      "${Ryppl_RESOURCE_PATH}/images"
      "${Ryppl_RESOURCE_PATH}/ryppl.css"
    DESTINATION
      "${html_dir}"
    )

  get_filename_component(ext ${input} EXT)
  get_filename_component(name ${input} NAME_WE)
  get_filename_component(input ${input} ABSOLUTE)

  if(HTML_HELP_COMPILER)
    set(hhp_output "${html_dir}/htmlhelp.hhp")
    set(chm_output "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.chm")
    xsltproc(
      INPUT      ${input}
      OUTPUT     ${hhp_output}
      CATALOG    ${BOOSTBOOK_CATALOG}
      STYLESHEET ${BOOSTBOOK_XSL_DIR}/htmlhelp.xsl
      PARAMETERS "htmlhelp.chm=../${PROJECT_NAME}.chm"
      )
    set(hhc_cmake ${CMAKE_CURRENT_BINARY_DIR}/hhc.cmake)
    file(WRITE ${hhc_cmake}
      "execute_process(COMMAND \"${HTML_HELP_COMPILER}\" htmlhelp.hhp"
      " WORKING_DIRECTORY \"${html_dir}\" OUTPUT_QUIET)"
      )
    add_custom_command(OUTPUT ${chm_output}
      COMMAND "${CMAKE_COMMAND}" -P "${hhc_cmake}"
      DEPENDS ${hhp_output}
      )
    list(APPEND doc_targets ${chm_output})
    install(FILES    "${chm_output}"
      DESTINATION    "doc"
      COMPONENT      "doc"
      CONFIGURATIONS "Release"
      )
  else() # generate HTML and manpages
    set(output_html "${html_dir}/index.html")
    xsltproc(
      INPUT      ${input}
      OUTPUT     ${output_html}
      CATALOG    ${BOOSTBOOK_CATALOG}
      STYLESHEET ${BOOSTBOOK_XSL_DIR}/xhtml.xsl
      )
    list(APPEND doc_targets ${output_html})
#   set(output_man  ${CMAKE_CURRENT_BINARY_DIR}/man/man.manifest)
#   xsltproc(${output_man} ${BOOSTBOOK_XSL_DIR}/manpages.xsl ${input})
#   list(APPEND doc_targets ${output_man})
    install(DIRECTORY "${html_dir}/"
      DESTINATION     "share/doc/${PROJECT_NAME}"
      COMPONENT       "doc"
      CONFIGURATIONS  "Release"
      )
  endif()

  set(target "${PROJECT_NAME}-doc")
  add_custom_target(${target} DEPENDS ${doc_targets})
  set_target_properties(${target} PROPERTIES
    FOLDER "${PROJECT_NAME}"
    PROJECT_LABEL "${PROJECT_NAME} (documentation)"
    )
  add_dependencies(documentation ${target})

  # build documentation as pdf
  if(DBLATEX_FOUND OR FOPROCESSOR_FOUND)
    set(pdf_dir ${CMAKE_BINARY_DIR}/pdf)
    set(pdf_file ${pdf_dir}/${PROJECT_NAME}.pdf)
    file(MAKE_DIRECTORY ${pdf_dir})

    if(FOPROCESSOR_FOUND)
      set(fop_file ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.fo)
      xsltproc(
        INPUT      ${input}
        OUTPUT     ${fop_file}
        CATALOG    ${BOOSTBOOK_CATALOG}
        STYLESHEET ${BOOSTBOOK_XSL_DIR}/fo.xsl
        PARAMETERS "img.src.path=${CMAKE_CURRENT_BINARY_DIR}/images/"
        )
      add_custom_command(OUTPUT ${pdf_file}
        COMMAND ${FO_PROCESSOR} ${fop_file} ${pdf_file} 2>${dev_null}
        DEPENDS ${fop_file}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        )
    elseif(DBLATEX_FOUND)
      add_custom_command(OUTPUT ${pdf_file}
        COMMAND ${DBLATEX_EXECUTABLE} -o ${pdf_file} ${input} 2>${dev_null}
        DEPENDS ${input}
        )
    endif()

    set(target "${PROJECT_NAME}-pdf")
    add_custom_target(${target} DEPENDS ${pdf_file})
    set_target_properties(${target} PROPERTIES
      FOLDER "${PROJECT_NAME}"
      PROJECT_LABEL "${PROJECT_NAME} (pdf)"
      )
  endif()
endfunction()




# This function adds file as dependency to `documentation` target
# For example you may pass `manifest` file 
# (which generated in function xslt_docbook_to_html) as input parameter
function(add_to_doc input type)
  set(target_name "${PROJECT_NAME}-${type}")
  add_custom_target(${target_name} DEPENDS ${input})

  add_dependencies(documentation ${target_name})

endfunction()



# This function performs transformation boostbook xml
# to docbook xml using docbook.xsl
#
# input parameters:
#  INPUT <input_file> - original file (boostbook XML)
#  OUTPUT <output_file> - resulting file (docbook XML)
#  DEPENDS <file_list> - list of files, which must trigger this conversion
#   can be empty. Usually this parameters is used when input xml contains
#   include directive with generated files.
#  PATH <path_list> - list of paths where search files for inclusion
#  PARAMETERS <param_list> - list of parameters which passed directly to xsltproc
#
# Example:
# xslt_boostbook_to_docbook(
#   INPUT
#     ${CMAKE_CURRENT_BINARY_DIR}/algorithm.xml
#   OUTPUT
#     ${dbk_file}
#   DEPENDS
#     ${CMAKE_CURRENT_BINARY_DIR}/autodoc.xml
#   PATH
#     ${CMAKE_CURRENT_SOURCE_DIR}
#     ${CMAKE_CURRENT_BINARY_DIR}
# )
#
function(xslt_boostbook_to_docbook)
  cmake_parse_arguments(XSL
    ""
    "OUTPUT"
    "DEPENDS;INPUT;PARAMETERS;PATH"
    ${ARGN}
  )

  xsltproc(
    INPUT
      ${XSL_INPUT}
    OUTPUT
      ${XSL_OUTPUT}
    CATALOG
      ${BOOSTBOOK_CATALOG}
    STYLESHEET
      ${BOOSTBOOK_XSL_DIR}/docbook.xsl
    DEPENDS
      ${XSL_DEPENDS}
    PATH
      ${XSL_PATH}
    PARAMETERS
      ${XSL_PARAMETERS}
  )
endfunction()


# Function performs conversion from docbook xml to html
#
# See `xslt_boostbook_to_docbook` description 
#   for parameters INPUT, OUTPUT, DEPENDS, PARAMETERS, PATH 
# MANIFEST <manifest_file> - file which contains list of files after generation
#  this file can be passed as parameter to function `add_to_doc`
function(xslt_docbook_to_html)
  cmake_parse_arguments(XSL
    ""
    "OUTPUT;MANIFEST"
    "DEPENDS;INPUT;PARAMETERS;PATH"
    ${ARGN}
  )

  if(NOT XSL_MANIFEST)
    message(FATAL_ERROR "xslt_docbook_to_html command requires MANIFEST parameter!")
  endif()

  xsltproc(
    INPUT
      ${XSL_INPUT}
    OUTPUT
      ${XSL_MANIFEST}
    CATALOG
      ${BOOSTBOOK_CATALOG}
    STYLESHEET
      ${BOOSTBOOK_XSL_DIR}/html.xsl
    DEPENDS
      ${XSL_DEPENDS}
    PATH
      ${XSL_PATH}
    PARAMETERS
      ${XSL_PARAMETERS}
      manifest="${XSL_MANIFEST}"
  )
endfunction()


# Function performs conversion from docbook xml to html
#
# See `xslt_boostbook_to_docbook` description 
#   for parameters INPUT, OUTPUT, DEPENDS, PARAMETERS, PATH 
function(xslt_doxy_to_boostbook)
  cmake_parse_arguments(XSL
    ""
    "OUTPUT"
    "DEPENDS;INPUT;PARAMETERS;PATH"
    ${ARGN}
  )

  xsltproc(
    INPUT
      ${XSL_INPUT}
    OUTPUT
      ${XSL_OUTPUT}
    CATALOG
      ${BOOSTBOOK_CATALOG}
    STYLESHEET
      ${BOOSTBOOK_XSL_DIR}/doxygen/doxygen2boostbook.xsl
    DEPENDS
      ${XSL_DEPENDS}
    PATH
      ${XSL_PATH}
    PARAMETERS
      ${XSL_PARAMETERS}
  )
endfunction()


# Function converts sources to boostbook XML in the following way:
#  src -> doxygen XML -> boostbook XML
#
# This function acts as simple composition of two commands
#  ryppl_doxygen and xslt_doxy_to_boostbook
# Parameters:
#  INPUT <input_file_list_or_path> - list of files and/or directories
#   which contain source code with doxygen comments
#  OUTPUT <file> - filename for generated boostbook XML
#  DOXYFILE <file> - file with doxygen parameters (optional)
#  DOXYGEN_PARAMETERS <param_list> - list of doxygen parameters
#   which pass directly to doxygen (params seta as <key>=<value>)
#  XSLT_PATH <list> - passed directly to xsltproc,
#   see also documentation for `xslt_boostbook_to_docbook`
#  XSLT_PARAMETERS <param_list> - passed directly to xsltproc
#   see also documentation for `xslt_boostbook_to_docbook`
#
# Usage example
function (ryppl_src_to_boostbook)
  cmake_parse_arguments(DOXY_BBK
    ""
    "OUTPUT;DOXYFILE"
    "DEPENDS;INPUT;DOXYGEN_PARAMETERS;XSLT_PATH;XSLT_PARAMETERS"
    ${ARGN}
  )

  get_filename_component(doxy_name ${DOXY_BBK_OUTPUT} NAME_WE)

  set(doxy_output ${DOXY_BBK_OUTPUT}.doxyxml)
  ryppl_doxygen(
    ${PROJECT_NAME}_${doxy_name}_doxy
    XML
    INPUT
      ${DOXY_BBK_INPUT}
    OUTPUT
      ${doxy_output}
    DOXYFILE
      ${DOXY_BBK_DOXYFILE}
    PARAMETERS
      ${DOXY_BBK_DOXYGEN_PARAMETERS}
  )

  xslt_doxy_to_boostbook(
    INPUT
      ${doxy_output}
    OUTPUT
      ${DOXY_BBK_OUTPUT}
    PATH
      ${DOXY_BBK_XSLT_PATH}
    PARAMETERS
      ${DOXY_BBK_XSLT_PARAMETERS}
  )
endfunction()


function(export_documentation)
  cmake_parse_arguments(doc_export
    ""
    "BOOSTBOOK"
    "BOOSTBOOK_PATH;DEPENDS"
    ${ARGN}
  )

  set(DOC_TARGET ${PROJECT_NAME}Doc)

  add_custom_target(
    ${DOC_TARGET}
    DEPENDS
      ${doc_export_BOOSTBOOK}
      ${doc_export_DEPENDS}
  )

  add_dependencies(documentation ${DOC_TARGET})

  set(doc_export_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${DOC_TARGET}Config.cmake")

  file(WRITE ${doc_export_OUTPUT} "# This file is generated with boost build\n# Do not edit !!!\n\n")

  if(doc_export_BOOSTBOOK)
    get_filename_component(boostbook_full_name ${doc_export_BOOSTBOOK} ABSOLUTE)
    get_filename_component(boostbook_entry_path ${boostbook_full_name} PATH)
    file(APPEND ${doc_export_OUTPUT} "set(${DOC_TARGET}_BOOSTBOOK ${boostbook_full_name})\n")
    file(APPEND ${doc_export_OUTPUT} "set(${DOC_TARGET}_BOOSTBOOK_PATH ${boostbook_entry_path})\n\n")

    file(APPEND ${doc_export_OUTPUT} "list(APPEND BOOSTBOOK_GENERATED_PATH \${${DOC_TARGET}_BOOSTBOOK_PATH})\n")
    file(APPEND ${doc_export_OUTPUT} "list(APPEND DOCUMENTATION_DEPENDENCIES ${doc_export_BOOSTBOOK})\n")
  endif()

  file(APPEND ${doc_export_OUTPUT} "list(APPEND DOCUMENTATION_DEPENDENCIES ${doc_export_DEPENDS})")

  foreach(path_entry ${doc_export_BOOSTBOOK_PATH})
    file(APPEND ${doc_export_OUTPUT} "list(APPEND BOOSTBOOK_GENERATED_PATH ${path_entry})\n")
  endforeach()

  file(APPEND ${doc_export_OUTPUT} "\n")

  # html processing section
  file(APPEND ${doc_export_OUTPUT} "set(${DOC_TARGET}_HTML")
  foreach(html_entry ${doc_export_HTML})
    file(APPEND ${doc_export_OUTPUT} " ${html_entry}")
  endforeach()
  file(APPEND ${doc_export_OUTPUT} ")\n\n")

  # image processing section
  file(APPEND ${doc_export_OUTPUT} "set(${DOC_TARGET}_IMAGES")
  foreach(img ${doc_export_IMAGES})
    file(APPEND ${doc_export_OUTPUT} " ${img}")
  endforeach()
  file(APPEND ${doc_export_OUTPUT} ")\n\n")

  file(APPEND ${doc_export_OUTPUT} "set(${DOC_TARGET}_IMG_DIR ${doc_export_IMG_DIR})\n\n\n")

  export(PACKAGE ${DOC_TARGET})

endfunction()

# This functions performs merging of several boostbooks into one
function(merge_boostbook)
  cmake_parse_arguments(merge_dbk
    ""
    "INPUT;OUTPUT"
    "PATH;DEPENDS"
    ${ARGN}
  )
  xsltproc(
    INPUT
      ${merge_dbk_INPUT}
    OUTPUT
      ${merge_dbk_OUTPUT}
    STYLESHEET
      ${BOOSTBOOK_XSL_DIR}/boostbook_merge.xsl
    PATH
      ${merge_dbk_PATH}
    CATALOG
      ${BOOSTBOOK_CATALOG}
    DEPENDS
      ${merge_dbk_DEPENDS}
  )
endfunction()
