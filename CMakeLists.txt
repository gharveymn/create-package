CMAKE_MINIMUM_REQUIRED(VERSION 3.13)
PROJECT(create-package
        VERSION 0.0.5
        LANGUAGES NONE)

INCLUDE(cmake/create-package.cmake)

SET(CMAKE_EXPORT_COMPILE_COMMANDS ON)

ADD_SUBDIRECTORY(test)
