#!/bin/bash
systemctl stop swcursor-autoset.service >/dev/null 2>&1
systemctl disable swcursor-autoset.service >/dev/null 2>&1
if [ -f "/usr/local/bin/swcursor-autoset" ]; then
  echo "Remove swcursor-autoset config ..."
  /usr/local/bin/swcursor-autoset --remove >/dev/null 2>&1
fi
exit 0