prosafe.lua
============

This is a lua script to administer Netgear Prosafe smart switches via the telnet port. It is somewhat experimental and requires you to have libUseful and libUseful-lua installed.

N.B. Recent Netgear switches have the telnet management interface turned off by default. You will have to turn it on using the http management screens.

Features:
* Displaying various information about a switch 
* set the switch's IPv4 address
* set the switch's management password 
* turn on/off remote management services
* set switches telnet banner
* set syslog server to send logs to 
* display switch log
* set sntp server to get time from
* set switch clock to localhost time
* list state of ports and mac addresses active on each port
* disable/turn-off ports
* lock ports to only allow traffic from current mac addresses


USAGE
=====
```
  lua prosafe.lua <host> [options]

-pass <password>         supply password for logging in
-proxy <host>            proxy to connect to target via
-set-pass <password>     change password
-set-ip <address>        change ip4 address
-sync-clock              sync clock to local
-sntp <host>             set sntp server to get time updates from
-syslog <host>           set server to send logging to
-banner <text>           set telnet login banner
-snmp                    set Simple Network Management Protocol to 'off', 'on' or 
-ports                   show port status
-disable-port <port>     turn off/disable a port
-enable-port <port>      turn on a previously disabled/turned off port
-lock-port <port>        lock a port to the current MAC address(es)
-unlock-port <port>      unlock port to accept any MAC address
-unused-off              turn off unusued ports
-all-on                  turn on all ports
-unlock                  unlock all ports
-showlog                 output logs
-save                    make setting changes permanent
```
