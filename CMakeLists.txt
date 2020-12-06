CMAKE_MINIMUM_REQUIRED(VERSION 3.1)
PROJECT(create-package
        VERSION 0.0.3
        LANGUAGES NONE)

INCLUDE(cmake/create-package.cmake)

INCLUDE(CMakePackageConfigHelpers)
CONFIGURE_PACKAGE_CONFIG_FILE("${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.cmake.in"
                              "${PROJECT_BINARY_DIR}/create-package-config.cmake"
                              INSTALL_DESTINATION "lib/cmake/create-package")

WRITE_BASIC_PACKAGE_VERSION_FILE("${PROJECT_BINARY_DIR}/create-package-config-version.cmake"
                                 VERSION       "${PROJECT_VERSION}"
                                 COMPATIBILITY "ExactVersion")
EXPORT(PACKAGE create-package)

# Only include tests if we are at the top level
IF(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  OPTION(CREATE_PACKAGE_BUILD_TESTS "Set to ON to build tests" ON)
ELSE()
  OPTION(CREATE_PACKAGE_BUILD_TESTS "Set to ON to build tests" OFF)
ENDIF()

IF(CREATE_PACKAGE_BUILD_TESTS)
  ADD_SUBDIRECTORY(test)
ENDIF()
