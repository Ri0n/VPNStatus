cmake_minimum_required (VERSION 3.4)
project(VPNStatus C)

find_program(IBTOOL ibtool HINTS "/usr/bin" "${OSX_DEVELOPER_ROOT}/usr/bin")
if (${IBTOOL} STREQUAL "IBTOOL-NOTFOUND")
  message(FATAL_ERROR "ibtool can not be found and is needed to compile the .xib files. It should have been installed with
                    the Apple developer tools. The default system paths were searched in addition to ${OSX_DEVELOPER_ROOT}/usr/bin")
endif()

find_program(ICONUTIL iconutil HINTS "/usr/bin" "${OSX_DEVELOPER_ROOT}/usr/bin")
if (${ICONUTIL} STREQUAL "ICONUTIL-NOTFOUND")
  message(FATAL_ERROR "iconutil can not be found and is needed to compile icns file for notification area.")
endif()

set( VPNSTATUS_RESOURCES
   Assets.xcassets
)

set_source_files_properties(
    ${VPNSTATUS_RESOURCES}
       PROPERTIES
          MACOSX_PACKAGE_LOCATION
          Resources
)

add_executable( VPNStatus MACOSX_BUNDLE
    AppDelegate.m
    AppDelegate.h
    main.m
    ${VPNSTATUS_RESOURCES}
)

set_target_properties(VPNStatus
  PROPERTIES
    MACOSX_BUNDLE TRUE
    RESOURCE "Assets.xcassets"
)

target_link_libraries(VPNStatus
    ${APP_KIT_LIBRARY}
    vpncommon
)

if (APPLE)
   set_target_properties( VPNStatus PROPERTIES
   MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in"
   MACOSX_BUNDLE_ICON_FILE "icon")

    set(BUNDLE_RESOURCES_DIR ${VPNStatus_BINARY_DIR}/VPNStatus.app/Contents/Resources)
    set(MAIN_MENU_MIB ${CMAKE_CURRENT_SOURCE_DIR}/Base.lproj/MainMenu.xib)
    add_custom_command (TARGET VPNStatus PRE_BUILD
                          COMMAND mkdir -p ${BUNDLE_RESOURCES_DIR})

    add_custom_command(TARGET VPNStatus POST_BUILD
                         COMMAND ${IBTOOL} --errors --warnings --notices --output-format human-readable-text
                                 --compile ${BUNDLE_RESOURCES_DIR}/MainMenu.nib ${MAIN_MENU_MIB}
                         COMMENT "Compiling ${MAIN_MENU_MIB}")


    add_custom_command(TARGET VPNStatus POST_BUILD
                       COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../scripts/prepare_icons.sh ${BUNDLE_RESOURCES_DIR}/icon
                       COMMENT "Compiling icon.icns")
endif()
