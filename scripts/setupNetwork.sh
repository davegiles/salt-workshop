#!/bin/bash

export SALT_NETWORK=1
vagrant up
vagrant ssh rtr1 -- -lroot "cli -c 'configure; set system host-name rtr1; delete interfaces em1; set interfaces em1.0 family inet address 192.168.17.31/24; set system login user vagrant authentication encrypted-password \"\$1\$810kIUBW\$MOXi4lDzP1uUFVquni7sn0\"; commit and-quit'"
vagrant ssh rtr2 -- -lroot "cli -c 'configure; set system host-name rtr2; delete interfaces em1; set interfaces em1.0 family inet address 192.168.17.32/24; set system login user vagrant authentication encrypted-password \"\$1\$810kIUBW\$MOXi4lDzP1uUFVquni7sn0\"; commit and-quit'"
