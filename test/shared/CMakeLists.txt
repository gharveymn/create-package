PROJECT(test_shared
        VERSION 0.0.1
        LANGUAGES CXX)

CREATE_PACKAGE(AUTHOR       gharveymn
               TYPE         SHARED
               HEADERS_PATH source/inc
               SOURCES_PATH source/src
               HEADERS      test-shared.hpp
               SOURCES      test-shared.cpp)
