#!/bin/bash

echo "[INFO] Applying Secure Boot toggle..."

# This writes secureboot state for the system to use
if [ "$CALAMARES_SECUREBOOT" == "yes" ]; then
	echo "enabled" >/etc/xanados/secureboot_enabled
else
	echo "disabled" >/etc/xanados/secureboot_enabled
fi
