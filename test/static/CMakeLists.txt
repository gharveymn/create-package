PROJECT(test_static
        VERSION 0.0.1
        LANGUAGES CXX)

CREATE_PACKAGE(AUTHOR       gharveymn
               TYPE         STATIC
               HEADERS_PATH source/inc
               SOURCES_PATH source/src
               HEADERS      test-static.hpp
               SOURCES      test-static.cpp)
