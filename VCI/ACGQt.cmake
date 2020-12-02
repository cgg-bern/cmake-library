macro (acg_qt5)

  #try to find qt5 automatically
  #for custom installation of qt5, dont use any of these variables
  set (QT5_INSTALL_PATH "" CACHE PATH "Path to Qt5 directory which contains lib and include folder")

  if (EXISTS "${QT5_INSTALL_PATH}")
    set (CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${QT5_INSTALL_PATH}")
    set (QT5_INSTALL_PATH_EXISTS TRUE)
  endif(EXISTS "${QT5_INSTALL_PATH}")
  
  set(QT5_FINDER_FLAGS "" CACHE STRING "Flags for the Qt finder e.g.
                                                       NO_DEFAULT_PATH if no system installed Qt shall be found")
  # compute default search paths
  set(SUPPORTED_QT_VERSIONS 5.11 5.10 5.9 5.8 5.7 5.6)
  foreach (suffix gcc_64 clang_64)
     foreach(version ${SUPPORTED_QT_VERSIONS})
         list(APPEND QT_DEFAULT_PATH "~/sw/Qt/${version}/${suffix}")
     endforeach()
  endforeach()

  find_package (Qt5Core PATHS ${QT_DEFAULT_PATH} ${QT5_FINDER_FLAGS})
  if(Qt5Core_FOUND)

      if(Qt5Core_VERSION) # use the new version variable if it is set
          set(Qt5Core_VERSION_STRING ${Qt5Core_VERSION})
      endif(Qt5Core_VERSION)

      string(REGEX REPLACE "^([0-9]+)\\.[0-9]+\\.[0-9]+.*" "\\1" QT_VERSION_MAJOR "${Qt5Core_VERSION_STRING}")
      string(REGEX REPLACE "^[0-9]+\\.([0-9]+)\\.[0-9]+.*" "\\1" QT_VERSION_MINOR "${Qt5Core_VERSION_STRING}")
      string(REGEX REPLACE "^[0-9]+\\.[0-9]+\\.([0-9]+).*" "\\1" QT_VERSION_PATCH "${Qt5Core_VERSION_STRING}")

    find_package (Qt5Widgets QUIET PATHS ${QT_DEFAULT_PATH} ${QT5_FINDER_FLAGS})
    find_package (Qt5Gui QUIET PATHS ${QT_DEFAULT_PATH} ${QT5_FINDER_FLAGS})
    find_package (Qt5OpenGL QUIET PATHS ${QT_DEFAULT_PATH} ${QT5_FINDER_FLAGS})

    if (NOT WIN32 AND NOT APPLE)
       find_package (Qt5X11Extras QUIET PATHS ${QT_DEFAULT_PATH} ${QT5_FINDER_FLAGS})
    endif ()

    if (Qt5Core_FOUND AND Qt5Widgets_FOUND AND Qt5Gui_FOUND AND Qt5OpenGL_FOUND )
          set (QT5_FOUND TRUE)
    endif()

  endif(Qt5Core_FOUND)
  
  if (QT5_FOUND)   
    
    #set plugin dir
    list(GET Qt5Gui_PLUGINS 0 _plugin)
    if (_plugin)
      get_target_property(_plugin_full ${_plugin} LOCATION)
      get_filename_component(_plugin_dir ${_plugin_full} PATH)
    set (QT_PLUGINS_DIR "${_plugin_dir}/../" CACHE PATH "Path to the qt plugin directory")
    elseif(QT5_INSTALL_PATH_EXISTS)
      set (QT_PLUGINS_DIR "${QT5_INSTALL_PATH}/plugins/" CACHE PATH "Path to the qt plugin directory")
    elseif()
      set (QT_PLUGINS_DIR "QT_PLUGIN_DIR_NOT_FOUND" CACHE PATH "Path to the qt plugin directory")
    endif(_plugin)

    #set binary dir for fixupbundle
    if(QT5_INSTALL_PATH_EXISTS)
      set(_QT_BINARY_DIR "${QT5_INSTALL_PATH}/bin")
    else()
      get_target_property(_QT_BINARY_DIR ${Qt5Widgets_UIC_EXECUTABLE} LOCATION)
      get_filename_component(_QT_BINARY_DIR ${_QT_BINARY_DIR} PATH)
    endif(QT5_INSTALL_PATH_EXISTS)
    
    set (QT_BINARY_DIR "${_QT_BINARY_DIR}" CACHE PATH "Qt5 binary Directory")
    mark_as_advanced(QT_BINARY_DIR)
    
    set (CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
  
    if (Qt5X11Extras_FOUND)
            include_directories(${Qt5X11Extras_INCLUDE_DIRS})
            add_definitions(${Qt5X11Extras_DEFINITIONS})
    endif ()
    
    if ( NOT MSVC )
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    endif()

    #adding QT_NO_DEBUG to all release modes. 
    #  Note: for multi generators like msvc you cannot set this definition depending of
    #  the current build type, because it may change in the future inside the ide and not via cmake
    if (MSVC_IDE)
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /DQT_NO_DEBUG")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /DQT_NO_DEBUG")
        
        set(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_RELEASE} /DQT_NO_DEBUG")
        set(CMAKE_CXX_FLAGS_MINSITEREL "${CMAKE_C_FLAGS_RELEASE} /DQT_NO_DEBUG")
        
        set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELEASE} /DQT_NO_DEBUG")
        set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELEASE} /DQT_NO_DEBUG")
    else(MSVC_IDE)
        if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
            add_definitions(-DQT_NO_DEBUG)
        endif()
    endif(MSVC_IDE)

    # Enable automoc
    set(CMAKE_AUTOMOC ON)

  endif (QT5_FOUND)
endmacro ()

#generates qt translations
function (acg_add_translations _target _languages _sources)

  string (TOUPPER ${_target} _TARGET)
  # generate/use translation files
  # run with UPDATE_TRANSLATIONS set to on to build qm files
  option (UPDATE_TRANSLATIONS_${_TARGET} "Update source translation *.ts files (WARNING: make clean will delete the source .ts files! Danger!)")

  set (_new_ts_files)
  set (_ts_files)

  foreach (lang ${_languages})
    if (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/translations/${_target}_${lang}.ts" OR UPDATE_TRANSLATIONS_${_TARGET})
      list (APPEND _new_ts_files "translations/${_target}_${lang}.ts")
    else ()
      list (APPEND _ts_files "translations/${_target}_${lang}.ts")
    endif ()
  endforeach ()


  set (_qm_files)
  if ( _new_ts_files )
    if (QT5_FOUND)
      #qt5_create_translation(_qm_files ${_sources} ${_new_ts_files})
    endif ()
  endif ()

  if ( _ts_files )
    if (QT5_FOUND)
      #qt5_add_translation(_qm_files2 ${_ts_files})
    endif()
    list (APPEND _qm_files ${_qm_files2})
  endif ()

  # create a target for the translation files ( and object files )
  # Use this target, to update only the translations
  add_custom_target (tr_${_target} DEPENDS ${_qm_files})
  GROUP_PROJECT( tr_${_target} "Translations")

  # Build translations with the application
  add_dependencies(${_target} tr_${_target} )

  if (NOT EXISTS ${CMAKE_BINARY_DIR}/Build/${ACG_PROJECT_DATADIR}/Translations)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/Build/${ACG_PROJECT_DATADIR}/Translations )
  endif ()

  foreach (_qm ${_qm_files})
    get_filename_component (_qm_name "${_qm}" NAME)
    add_custom_command (TARGET tr_${_target} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E
      copy_if_different
      ${_qm}
      ${CMAKE_BINARY_DIR}/Build/${ACG_PROJECT_DATADIR}/Translations/${_qm_name})
  endforeach ()

  if (NOT ACG_PROJECT_MACOS_BUNDLE OR NOT APPLE)
    install (FILES ${_qm_files} DESTINATION "${ACG_PROJECT_DATADIR}/Translations")
  endif ()
endfunction ()
