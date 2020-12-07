PROJECT(test_library
        VERSION 0.0.1
        LANGUAGES CXX)

CREATE_PACKAGE(AUTHOR       gharveymn
               NAME         test_library
               HEADERS_PATH source/inc
               SOURCES_PATH source/src
               HEADERS      test-library.hpp
               SOURCES      test-library.cpp
               NO_HEADERS_PREFIX)
