file(GLOB tests 
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*")

foreach(test ${tests})
    if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${test}")
        message(STATUS "add_subdirectory(${test})")
        add_subdirectory("${test}")
    endif()
endforeach()
