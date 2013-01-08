# Distributed under the Boost Software License, Version 1.0.
# See http://www.boost.org/LICENSE_1_0.txt

include(Ryppl)
include(CMakeParseArguments)


ryppl_find_and_use_package(Quickbook)


# convert qbk to xml via quickbook
function(ryppl_quickbook qbkFile xmlFile)

  cmake_parse_arguments(ryppl_qbk
    "" # no options
    "INDENT;LINEWIDTH" # one value params
    "INCLUDES;DEFINES" # multi value params
    ${ARGN}
    )

    if(${ryppl_qbk_INDENT})
      set(RYPPL_QBK_INDENT_ARG "--indent ${ryppl_qbk_INDENT}")
    endif()

    if(${ryppl_qbk_LINEWIDTH})
      set(RYPPL_QBK_LINEWIDTH_ARG "--linewidth ${ryppl_qbk_LINEWIDTH}")
    endif()

    if(${ryppl_qbk_INCLUDES})
      set(RYPPL_QBK_INCLUDES_ARG "-I${ryppl_qbk_INCLUDES}")
    endif()

    if(${ryppl_qbk_DEFINES})
      set(RYPPL_QBK_DEFINES_ARG "-D${ryppl_qbk_DEFINES}")
    endif()

  add_custom_command(
    COMMAND quickbook --input-file ${qbkFile} --output-file ${xmlFile} ${RYPPL_QBK_INCLUDES_ARG} ${RYPPL_QBK_DEFINES_ARG} ${RYPPL_QBK_INDENT_ARG} ${RYPPL_QBK_LINEWIDTH_ARG}
    OUTPUT ${xmlFile}
    )
endfunction(ryppl_quickbook)