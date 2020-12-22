cmake_minimum_required (VERSION 3.4)
project(VPNCommon C)

set(COMMON_SOURCES
    ACCWManager.m
    ACCWManager.h
    ACNEService.m
    ACNEService.h
    ACNEServicesManager.m
    ACNEServicesManager.h
    ACPreferences.m
    ACPreferences.h
    ACDefines.h
)

set(COMMON_DEPENDENCIES
    ${FOUNDATION_LIBRARY}
    ${SYSTEM_CONFIGURATION_LIBRARY}
    ${CORE_WLAN_LIBRARY}
    ${NETWORK_EXTENSION_LIBRARY}
    )

add_library(vpncommon STATIC ${COMMON_SOURCES})
target_link_libraries(vpncommon PUBLIC ${COMMON_DEPENDENCIES})
target_include_directories(vpncommon PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
