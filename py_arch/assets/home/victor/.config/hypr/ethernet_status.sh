#!/bin/bash

CONNECTED="<b style='font-size:16px; color:rgb(76, 175, 80);'>Connected ✔</b>"
DISCONNECTED="<b style='font-size:16px; color:rgb(255, 99, 71);'>Disconnected ❌</b>"

if ip link show eno1 | grep -q 'state UP'; then
    echo "Ethernet: $CONNECTED"
else
    echo "Ethernet: $DISCONNECTED"
fi
