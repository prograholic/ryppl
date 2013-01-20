# Distributed under the Boost Software License, Version 1.0.
# See http://www.boost.org/LICENSE_1_0.txt

include(Ryppl)
include(CMakeParseArguments)


ryppl_find_and_use_package(Quickbook)


# convert qbk to xml via quickbook
function(quickbook_to_boostbook qbkFile xmlFile)
  cmake_parse_arguments(ryppl_qbk
    "" # no options
    "INDENT;LINEWIDTH;XINCLUDE_BASE" # one value params
    "INCLUDES;DEFINES" # multi value params
    ${ARGN}
  )

  if (ryppl_qbk_XINCLUDE_BASE)
    set(RYPPL_QBK_XINCLUDE_BASE_ARG --xinclude-base ${ryppl_qbk_XINCLUDE_BASE})
  endif()

  if(ryppl_qbk_INDENT)
    set(RYPPL_QBK_INDENT_ARG "--indent ${ryppl_qbk_INDENT}")
  endif()

  if(ryppl_qbk_LINEWIDTH)
    set(RYPPL_QBK_LINEWIDTH_ARG "--linewidth ${ryppl_qbk_LINEWIDTH}")
  endif()

  foreach(inc_entry ${ryppl_qbk_INCLUDES})
    set(RYPPL_QBK_INCLUDES_ARG  ${RYPPL_QBK_INCLUDES_ARG} "-I${inc_entry}")
  endforeach()

  foreach(def_entry ${ryppl_qbk_DEFINES})
    set(RYPPL_QBK_DEFINES_ARG  ${RYPPL_QBK_DEFINES_ARG} "-D${def_entry}")
  endforeach()

  add_custom_command(
    COMMAND quickbook --debug --input-file ${qbkFile} --output-file ${xmlFile} ${RYPPL_QBK_XINCLUDE_BASE_ARG} ${RYPPL_QBK_INCLUDES_ARG} ${RYPPL_QBK_DEFINES_ARG} ${RYPPL_QBK_INDENT_ARG} ${RYPPL_QBK_LINEWIDTH_ARG}
    OUTPUT ${xmlFile}
    COMMENT "converting quickbook file (${qbkFile}) to boostbook xml ..."
  )
endfunction(quickbook_to_boostbook)
