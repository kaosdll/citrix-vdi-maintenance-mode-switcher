# citrix-vdi-maintenance-mode-switcher

This script enable or disable Maintenance Mode for Citrix VDI machines.

The script read a static text file with hostnames and enable or disable maintance mode for each machine.
The script will wait 60 seconds after each machine.
If a target VDI is powered off it will be started automatically, if a target VDI is powered on it will be restarted if not in use.

https://www.nova17.de/2016/04/vdi-mm-switcher/
