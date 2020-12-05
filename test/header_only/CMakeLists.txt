PROJECT(test_header_only
        VERSION 0.0.1
        LANGUAGES CXX)

CREATE_PACKAGE(AUTHOR       gharveymn
               NAME         test_header_only
               HEADERS_PATH source/inc
               HEADERS      gharveymn/test-header-only.hpp)
