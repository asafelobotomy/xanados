#!/bin/bash
set -e

SYSROOT="$1"

echo "[XanadOS] Writing hostname, locale, timezone..."

if [ -n "$CALAMARES_HOSTNAME" ]; then
	echo "$CALAMARES_HOSTNAME" >"$SYSROOT/etc/hostname"
else
	echo "xanados" >"$SYSROOT/etc/hostname"
fi

if [ -n "$CALAMARES_LOCALE" ]; then
	echo "LANG=$CALAMARES_LOCALE" >"$SYSROOT/etc/locale.conf"
else
	echo "LANG=en_IE.UTF-8" >"$SYSROOT/etc/locale.conf"
fi

if [ -n "$CALAMARES_TIMEZONE" ] && [ -f "/usr/share/zoneinfo/$CALAMARES_TIMEZONE" ]; then
	ln -sf "/usr/share/zoneinfo/$CALAMARES_TIMEZONE" "$SYSROOT/etc/localtime"
else
	ln -sf "/usr/share/zoneinfo/Europe/Dublin" "$SYSROOT/etc/localtime"
fi

echo "[XanadOS] Hostname, locale, timezone set."
