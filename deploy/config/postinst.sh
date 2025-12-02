#!/bin/bash
if [ -f "/usr/local/bin/swcursor-autoset" ]; then
  echo "Install swcursor-autoset service ..."
  systemctl daemon-reload >/dev/null 2>&1
  systemctl enable swcursor-autoset.service >/dev/null 2>&1
  systemctl start swcursor-autoset.service >/dev/null 2>&1
fi
exit 0