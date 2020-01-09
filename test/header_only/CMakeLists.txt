PROJECT(test_header_only
        VERSION 0.0.1
        LANGUAGES CXX)

CREATE_PACKAGE(AUTHOR       gharveymn
               NAME         test_header_only
               INCLUDE_PATH source/inc
               HEADERS      test-header-only.hpp)
