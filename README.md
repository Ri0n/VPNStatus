# VPNStatus
VPNStatus, a replacement for macOS builtin VPN Status

# Original author blog post
[https://blog.timac.org/2018/0719-vpnstatus/](https://blog.timac.org/2018/0719-vpnstatus/)

# Description
VPNStatus, an application that replicates some functionalities of macOS built-in VPN status menu:

- list the VPN services and their status
- connect to a VPN service
- disconnect from a VPN service
- auto connect to a VPN service if the application is running

# This forked version vs original version

- better icon in menubar, it is important
- yellow icon now means connecting
- instant auto reconnect when disconnected
- auto reconnect loop is still kept, just in case
- removed pause function for clarity (both visually and code style)
- disconnect will disable auto connect, auto connect will try to connect immediately
- code refactor for better readability
