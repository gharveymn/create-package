PROJECT(test_library
        VERSION 0.0.1
        LANGUAGES CXX)

CREATE_PACKAGE(AUTHOR       gharveymn
               NAME         test_library
               INCLUDE_PATH source/inc
               SOURCE_PATH  source/src
               HEADERS      test-library.hpp
               SOURCES      test-library.cpp)
