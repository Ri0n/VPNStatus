cmake_minimum_required (VERSION 3.4)
project(VPN C)

# uncomment this for mulle-objc to search libraries first
# set( CMAKE_FIND_FRAMEWORK "LAST")

find_library( FOUNDATION_LIBRARY Foundation)
message( STATUS "FOUNDATION_LIBRARY is ${FOUNDATION_LIBRARY}")
find_library( SYSTEM_CONFIGURATION_LIBRARY SystemConfiguration)
message( STATUS "SYSTEM_CONFIGURATION_LIBRARY is ${SYSTEM_CONFIGURATION_LIBRARY}")
find_library( APP_KIT_LIBRARY AppKit)
message( STATUS "APP_KIT_LIBRARY is ${APP_KIT_LIBRARY}")
find_library( CORE_WLAN_LIBRARY CoreWLAN)
message( STATUS "CORE_WLAN_LIBRARY is ${CORE_WLAN_LIBRARY}")
find_library( NETWORK_EXTENSION_LIBRARY NetworkExtension)
message( STATUS "NETWORK_EXTENSION_LIBRARY is ${NETWORK_EXTENSION_LIBRARY}")


# uncomment this for mulle-objc to search libraries first
# set( CMAKE_FIND_FRAMEWORK "LAST")

add_subdirectory(Common)
add_subdirectory(VPNStatus)
add_subdirectory(vpnutil)
