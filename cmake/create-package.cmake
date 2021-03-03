CMAKE_MINIMUM_REQUIRED(VERSION 3.1)

SET(HAS_CREATE_PACKAGE TRUE)
SET(CREATE_PACKAGE_VERSION 0.0.5)

SET(CREATE_PACKAGE_FILE "${CMAKE_CURRENT_LIST_FILE}")

FUNCTION(INITIALIZE_DEPENDENCY name)
  FIND_PACKAGE(${name} QUIET)
  IF(${name}_FOUND)
    MESSAGE(STATUS "Found system package for ${name}")
  ELSE()
    IF(TARGET ${name})
      MESSAGE(STATUS "Found inherited target ${name}")
    ELSE()
      MESSAGE(STATUS "Initializing ${name} in git submodule")
      EXECUTE_PROCESS(COMMAND git submodule --quiet update --init -- "external/${name}"
                      WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
      ADD_SUBDIRECTORY("${PROJECT_SOURCE_DIR}/external/${name}" "external/${name}" EXCLUDE_FROM_ALL)

      # ensure our macros didnt get overwritten by the subscope
      INCLUDE("${CREATE_PACKAGE_FILE}")
    ENDIF()
  ENDIF()
ENDFUNCTION()

MACRO(MAKE_VARNAME in_str out_var)
  STRING(TOUPPER           "${in_str}"    AS_UPPER    )
  STRING(MAKE_C_IDENTIFIER "${AS_UPPER}"  "${out_var}")
ENDMACRO()

FUNCTION(PRINT_PACKAGE_VARIABLE var)
  MESSAGE(STATUS "${var}: ${PACKAGE_${var}}")
ENDFUNCTION()

MACRO(CREATE_PACKAGE_PRINT_HEADER)
  SET(PACKAGE_TITLE_STRING "==  ${PACKAGE_NAME}   -by-   ${PACKAGE_AUTHOR}  ==")
  STRING(LENGTH "${PACKAGE_TITLE_STRING}" PACKAGE_TITLE_STRING_LEN)
  STRING(REPEAT "=" ${PACKAGE_TITLE_STRING_LEN} PACKAGE_TITLE_STRING_SURROUND)

  IF (NOT PACKAGE_NO_PRINT)
    MESSAGE(STATUS "${PACKAGE_TITLE_STRING_SURROUND}")
    MESSAGE(STATUS "${PACKAGE_TITLE_STRING}")
    MESSAGE(STATUS "${PACKAGE_TITLE_STRING_SURROUND}")
  ENDIF ()
ENDMACRO()

FUNCTION(CREATE_PACKAGE_PRINT_VARIABLES)
  IF (NOT PACKAGE_NO_PRINT)
    FOREACH(VAR ${PACKAGE_VARIABLES})
      PRINT_PACKAGE_VARIABLE(${VAR})
    ENDFOREACH()
  ENDIF ()
ENDFUNCTION()

MACRO(CREATE_PACKAGE_PRINT_FOOTER)
  STRING(REPEAT "=" ${PACKAGE_TITLE_STRING_LEN} PACKAGE_FOOTER_STRING)

  IF (NOT PACKAGE_NO_PRINT)
    MESSAGE(STATUS "${PACKAGE_FOOTER_STRING}")
  ENDIF ()
ENDMACRO()

MACRO(TARGET_LINK_LIBRARIES_SYSTEM TARGET TYPE)
  FOREACH(LIB ${ARGN})
    GET_TARGET_PROPERTY(LIB_INCLUDE_DIRS ${LIB} INTERFACE_INCLUDE_DIRECTORIES)
    TARGET_INCLUDE_DIRECTORIES(${TARGET} SYSTEM ${TYPE} "${LIB_INCLUDE_DIRS}")
    TARGET_LINK_LIBRARIES(${TARGET} ${TYPE} ${LIB})
  ENDFOREACH()
ENDMACRO()

MACRO(CREATE_PACKAGE_CREATE_HEADER_ONLY)
  ADD_LIBRARY(${PACKAGE_NAME} INTERFACE)
  ADD_LIBRARY("${PACKAGE_CMAKE_NAMESPACE}${PACKAGE_NAME}" ALIAS "${PACKAGE_NAME}")

  TARGET_SOURCES(${PACKAGE_NAME}
                 INTERFACE "$<BUILD_INTERFACE:${PACKAGE_ABSOLUTE_HEADERS}>")

  TARGET_INCLUDE_DIRECTORIES(${PACKAGE_NAME}
                             INTERFACE "$<BUILD_INTERFACE:${PACKAGE_ABSOLUTE_HEADERS_PATH}>")

  TARGET_INCLUDE_DIRECTORIES(${PACKAGE_NAME} SYSTEM INTERFACE
                             "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${PACKAGE_HEADERS_INSTALL_PATH}>")

  # Link dependencies
  IF(DEFINED PACKAGE_DEPENDENCIES)
    TARGET_LINK_LIBRARIES_SYSTEM(${PACKAGE_NAME} INTERFACE ${PACKAGE_DEPENDENCIES})
  ENDIF()
ENDMACRO()

MACRO(CREATE_PACKAGE_CREATE_LIBRARY)
  ADD_LIBRARY(${PACKAGE_NAME} ${PACKAGE_TYPE})
  ADD_LIBRARY("${PACKAGE_CMAKE_NAMESPACE}${PACKAGE_NAME}" ALIAS "${PACKAGE_NAME}")

  TARGET_SOURCES(${PACKAGE_NAME}
                 PUBLIC "$<BUILD_INTERFACE:${PACKAGE_ABSOLUTE_HEADERS}>"
                 PRIVATE "${PACKAGE_ABSOLUTE_SOURCES}")

  TARGET_INCLUDE_DIRECTORIES(${PACKAGE_NAME}
                             PUBLIC "$<BUILD_INTERFACE:${PACKAGE_ABSOLUTE_HEADERS_PATH}>")

  TARGET_INCLUDE_DIRECTORIES(${PACKAGE_NAME} SYSTEM INTERFACE
                             "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${PACKAGE_HEADERS_INSTALL_PATH}>")

  # Link dependencies
  IF(DEFINED PACKAGE_DEPENDENCIES)
    TARGET_LINK_LIBRARIES_SYSTEM(${PACKAGE_NAME} PUBLIC ${PACKAGE_DEPENDENCIES})
  ENDIF()
ENDMACRO()

MACRO(CREATE_PACKAGE_CREATE_CONFIGURATION)
  # Build package configuration
  INCLUDE(CMakePackageConfigHelpers)

  SET( PACKAGE_CONFIG_EXPORT_NAME ${PACKAGE_NAME}-config               )
  SET(PACKAGE_VERSION_EXPORT_NAME ${PACKAGE_CONFIG_EXPORT_NAME}-version)
  SET(PACKAGE_TARGETS_EXPORT_NAME ${PACKAGE_NAME}-targets              )

  SET( PACKAGE_CONFIG_FILE_NAME   ${PACKAGE_CONFIG_EXPORT_NAME}.cmake )
  SET(PACKAGE_VERSION_FILE_NAME   ${PACKAGE_VERSION_EXPORT_NAME}.cmake)
  SET(PACKAGE_TARGETS_FILE_NAME   ${PACKAGE_TARGETS_EXPORT_NAME}.cmake)

  SET( PACKAGE_CONFIG_BUILD_FILE  "${PROJECT_BINARY_DIR}/${PACKAGE_CONFIG_FILE_NAME}" )
  SET(PACKAGE_VERSION_BUILD_FILE  "${PROJECT_BINARY_DIR}/${PACKAGE_VERSION_FILE_NAME}")
  SET(PACKAGE_TARGETS_BUILD_FILE  "${PROJECT_BINARY_DIR}/${PACKAGE_TARGETS_FILE_NAME}")

  ## we need to find or generate config.cmake.in
  IF(EXISTS "${PACKAGE_CMAKE_DIR}/config.cmake.in")
    SET(PACKAGE_CONFIG_CMAKE_IN_FILE "${PACKAGE_CMAKE_DIR}/config.cmake.in")
  ELSE()
    SET(PACKAGE_CONFIG_CMAKE_IN_FILE "${PACKAGE_CONFIG_BUILD_FILE}.in")
    FILE(WRITE "${PACKAGE_CONFIG_CMAKE_IN_FILE}" "@PACKAGE_INIT@

INCLUDE(\"\${CMAKE_CURRENT_LIST_DIR}/@PACKAGE_TARGETS_FILE_NAME@\")
CHECK_REQUIRED_COMPONENTS(@PACKAGE_NAME@)
")
    MESSAGE(STATUS "File config.cmake.in not found in the cmake directory. Generating a generic version instead.")
  ENDIF()

  CONFIGURE_PACKAGE_CONFIG_FILE("${PACKAGE_CONFIG_CMAKE_IN_FILE}"
                                "${PACKAGE_CONFIG_BUILD_FILE}"
                                INSTALL_DESTINATION "${PACKAGE_CONFIG_INSTALL_PATH}")

  WRITE_BASIC_PACKAGE_VERSION_FILE("${PACKAGE_VERSION_BUILD_FILE}"
                                   VERSION       "${PACKAGE_VERSION}"
                                   COMPATIBILITY "${PACKAGE_COMPATIBILITY}")

  EXPORT(TARGETS      "${PACKAGE_NAME}"
         NAMESPACE    "${PACKAGE_CMAKE_NAMESPACE}"
         FILE         "${PACKAGE_TARGETS_BUILD_FILE}")

  # Install package configuration
  INSTALL(FILES "${PACKAGE_CONFIG_BUILD_FILE}" "${PACKAGE_VERSION_BUILD_FILE}"
          DESTINATION "${PACKAGE_CONFIG_INSTALL_PATH}")

  INSTALL(EXPORT      "${PACKAGE_TARGETS_EXPORT_NAME}"
          DESTINATION "${PACKAGE_CONFIG_INSTALL_PATH}"
          NAMESPACE   "${PACKAGE_CMAKE_NAMESPACE}")
ENDMACRO()

MACRO(CREATE_PACKAGE_EXPORT_VARIABLES)
  FOREACH(VAR ${PACKAGE_VARIABLES})
    SET("${PACKAGE_VARNAME}_${VAR}" "${PACKAGE_${VAR}}")
  ENDFOREACH()
ENDMACRO()

MACRO(CREATE_PACKAGE)

  SET(PACKAGE_VARIABLES
      NAME
      AUTHOR
      TYPE
      VERSION
      DEPENDENCIES
      NAMESPACE
      CMAKE_NAMESPACE
      HEADERS_PATH
      HEADERS
      SOURCES_PATH
      SOURCES
      ROOT_DIR
      CMAKE_DIR
      CONFIG_INSTALL_PATH
      HEADERS_INSTALL_PATH
      LIBRARY_INSTALL_PATH
      HEADERS_PREFIX
      ABSOLUTE_HEADERS_PATH
      ABSOLUTE_HEADERS
      ABSOLUTE_SOURCES_PATH
      ABSOLUTE_SOURCES)

  # Unset everything
  FOREACH(VAR ${PACKAGE_VARIABLES})
    UNSET(PACKAGE_${VAR})
  ENDFOREACH()

  # Set parsing meta-arguments

  ## Options
  SET(MACRO_OPTIONS
      NO_HEADERS_PREFIX
      NO_PRINT)

  ## Keywords with a single value
  SET(MACRO_SINGLE_VALUE_KEYWORDS
      AUTHOR
      TYPE
      NAMESPACE
      CMAKE_NAMESPACE
      CMAKE_DIR
      CONFIG_INSTALL_PATH
      HEADERS_INSTALL_PATH
      LIBRARY_INSTALL_PATH
      HEADERS_PREFIX
      NAME
      VERSION
      ROOT_DIR
      COMPATIBILITY
      LIBRARY_TYPE)

  ## Keywords with multiple values
  SET(MACRO_MULTI_VALUE_KEYWORDS
      HEADERS_PATH
      HEADERS
      SOURCES_PATH
      SOURCES
      DEPENDENCIES
      TARGET_PROPERTIES)

  # Parse arguments
  CMAKE_PARSE_ARGUMENTS(PACKAGE
                        "${MACRO_OPTIONS}"
                        "${MACRO_SINGLE_VALUE_KEYWORDS}"
                        "${MACRO_MULTI_VALUE_KEYWORDS}"
                        ${ARGN})

  # Required arguments

  ## AUTHOR
  IF(NOT DEFINED PACKAGE_AUTHOR)
    MESSAGE(FATAL_ERROR "Missing required value for required keyword AUTHOR.")
  ENDIF()

  # Optional arguments (non-dependent)
  ## NAME
  IF(NOT DEFINED PACKAGE_NAME)
    SET(PACKAGE_NAME "${PROJECT_NAME}")
  ENDIF()

  ## VERSION
  IF(NOT DEFINED PACKAGE_VERSION)
    SET(PACKAGE_VERSION "${PROJECT_VERSION}")
  ENDIF()

  ## TYPE
  IF((NOT DEFINED PACKAGE_TYPE) AND (NOT PACKAGE_SOURCES))
    SET(PACKAGE_TYPE HEADER)
  ENDIF()

  ## ROOT_DIR
  IF(NOT DEFINED PACKAGE_ROOT_DIR)
    SET(PACKAGE_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  ENDIF()

  ## COMPATIBILITY
  IF(NOT DEFINED PACKAGE_COMPATIBILITY)
    SET(PACKAGE_COMPATIBILITY "ExactVersion")
  ENDIF()

  # Optional arguments (dependent)
  MAKE_VARNAME(${PACKAGE_NAME}   PACKAGE_VARNAME)
  MAKE_VARNAME(${PACKAGE_AUTHOR} PACKAGE_AUTHOR_VARNAME)

  ## CMAKE_NAMESPACE
  IF(NOT DEFINED PACKAGE_CMAKE_NAMESPACE)
    IF(NOT DEFINED PACKAGE_NAMESPACE)
      STRING(MAKE_C_IDENTIFIER "${PACKAGE_AUTHOR}"  PACKAGE_CMAKE_NAMESPACE)
      SET(PACKAGE_CMAKE_NAMESPACE "${PACKAGE_CMAKE_NAMESPACE}::")
    ELSE()
      SET(PACKAGE_CMAKE_NAMESPACE "${PACKAGE_NAMESPACE}::")
    ENDIF()
  ELSEIF(NOT PACKAGE_CMAKE_NAMESPACE MATCHES ".*\\:\\:")
    SET(PACKAGE_CMAKE_NAMESPACE "${PACKAGE_CMAKE_NAMESPACE}::")
  ENDIF()

  ## NAMESPACE
  IF(NOT DEFINED PACKAGE_NAMESPACE)
    SET(PACKAGE_NAMESPACE "")
  ENDIF()

  ## CMAKE_DIR
  IF(NOT DEFINED PACKAGE_CMAKE_DIR)
    SET(PACKAGE_CMAKE_DIR "${PACKAGE_ROOT_DIR}/cmake")
  ENDIF()

  ## CONFIG_INSTALL_PATH
  IF(NOT DEFINED PACKAGE_CONFIG_INSTALL_PATH)
    # FIXME: this will make a mess of everything if we have conflicting package names
    SET(PACKAGE_CONFIG_INSTALL_PATH "lib/cmake/${PACKAGE_NAME}")
  ENDIF()

  ## HEADERS_INSTALL_PATH
  IF(NOT DEFINED PACKAGE_HEADERS_INSTALL_PATH)
    SET(PACKAGE_HEADERS_INSTALL_PATH "include")
  ENDIF()

  ## LIBRARY_INSTALL_PATH
  IF(NOT DEFINED PACKAGE_LIBRARY_INSTALL_PATH)
    SET(PACKAGE_LIBRARY_INSTALL_PATH "lib")
  ENDIF()

  ## HEADERS_PREFIX
  IF(PACKAGE_NO_HEADERS_PREFIX)
    SET(PACKAGE_HEADERS_PREFIX ".")
  ELSEIF(NOT DEFINED PACKAGE_HEADERS_PREFIX)
    LIST(LENGTH PACKAGE_HEADERS PACKAGE_NUM_HEADERS)
    IF(${PACKAGE_NUM_HEADERS} EQUAL 1)
      SET(PACKAGE_HEADERS_PREFIX "${PACKAGE_NAMESPACE}")
    ELSE()
      SET(PACKAGE_HEADERS_PREFIX "${PACKAGE_NAMESPACE}/${PACKAGE_NAME}")
    ENDIF()
  ENDIF()

  ## HEADERS_PATH
  IF(NOT DEFINED PACKAGE_HEADERS_PATH)
    SET(PACKAGE_HEADERS_PATH include)
  ENDIF()

  ## SOURCES_PATH
  IF(NOT DEFINED PACKAGE_SOURCES_PATH)
    SET(PACKAGE_SOURCES_PATH lib)
  ENDIF()

  # Fully qualify headers paths
  FOREACH(DIR ${PACKAGE_HEADERS_PATH})
    GET_FILENAME_COMPONENT(ABS_DIR "${DIR}" ABSOLUTE BASE_DIR "${PACKAGE_ROOT_DIR}")
    LIST(APPEND PACKAGE_ABSOLUTE_HEADERS_PATH "${ABS_DIR}")
  ENDFOREACH()

  # Fully qualify headers
  FOREACH(HEADER ${PACKAGE_HEADERS})
    FOREACH(ABS_DIR ${PACKAGE_ABSOLUTE_HEADERS_PATH})
      GET_FILENAME_COMPONENT(ABS_HEADER "${PACKAGE_HEADERS_PREFIX}/${HEADER}"
                             ABSOLUTE BASE_DIR "${ABS_DIR}")
      IF(ABS_HEADER)
        BREAK()
      ENDIF()
    ENDFOREACH()
    LIST(APPEND PACKAGE_ABSOLUTE_HEADERS "${ABS_HEADER}")
  ENDFOREACH()

  # Fully qualify sources paths
  FOREACH(DIR ${PACKAGE_SOURCES_PATH})
    GET_FILENAME_COMPONENT(ABS_DIR "${DIR}" ABSOLUTE BASE_DIR "${PACKAGE_ROOT_DIR}")
    LIST(APPEND PACKAGE_ABSOLUTE_SOURCES_PATH "${ABS_DIR}")
  ENDFOREACH()

  # Fully qualify sources
  FOREACH(SOURCE ${PACKAGE_SOURCES})
    FOREACH(ABS_DIR ${PACKAGE_ABSOLUTE_SOURCES_PATH})
      GET_FILENAME_COMPONENT(ABS_SOURCE "${SOURCE}" ABSOLUTE BASE_DIR "${ABS_DIR}")
      IF(ABS_SOURCE)
        BREAK()
      ENDIF()
    ENDFOREACH()
    LIST(APPEND PACKAGE_ABSOLUTE_SOURCES "${ABS_SOURCE}")
  ENDFOREACH()

  CREATE_PACKAGE_PRINT_HEADER()
  CREATE_PACKAGE_PRINT_VARIABLES()

  # Initialize dependencies
  IF(DEFINED PACKAGE_DEPENDENCIES)
    MESSAGE(STATUS "Initializing dependencies")
    FOREACH(DEP ${PACKAGE_DEPENDENCIES})
      INITIALIZE_DEPENDENCY(${DEP})
    ENDFOREACH()
  ENDIF()

  IF(PACKAGE_TYPE STREQUAL "HEADER")
    CREATE_PACKAGE_CREATE_HEADER_ONLY()
  ELSE()
    CREATE_PACKAGE_CREATE_LIBRARY()
  ENDIF()

  IF(DEFINED PACKAGE_DEPENDENCIES)
    ADD_DEPENDENCIES("${PACKAGE_NAME}" ${PACKAGE_DEPENDENCIES})
  ENDIF()

  CREATE_PACKAGE_CREATE_CONFIGURATION()

  # Install targets
  INSTALL(TARGETS     "${PACKAGE_NAME}"
          EXPORT      "${PACKAGE_TARGETS_EXPORT_NAME}"
          DESTINATION "${PACKAGE_LIBRARY_INSTALL_PATH}")

  # Install headers
  INSTALL(DIRECTORY   "${PACKAGE_ABSOLUTE_HEADERS_PATH}"
          DESTINATION "${PACKAGE_HEADERS_INSTALL_PATH}")

  CREATE_PACKAGE_EXPORT_VARIABLES()

  CREATE_PACKAGE_PRINT_FOOTER()

ENDMACRO()
