cmake_minimum_required (VERSION 3.4)
project(VPNUtil C)

add_executable(vpnutil main.m)
target_link_libraries(vpnutil vpncommon)
