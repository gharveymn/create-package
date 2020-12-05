PROJECT(test_executable
        VERSION 0.0.1
        LANGUAGES CXX)

SET(DEP GHARVEYMN::test_header_only)

INITIALIZE_DEPENDENCY(${DEP})

ADD_EXECUTABLE(test_executable source/src/main.cpp)

TARGET_LINK_LIBRARIES(test_executable PUBLIC ${DEP})

INSTALL(TARGETS test_executable DESTINATION lib)
