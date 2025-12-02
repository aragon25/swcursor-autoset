#!/bin/bash
function undo_changes(){
  systemctl stop swcursor-autoset.service >/dev/null 2>&1
  systemctl disable swcursor-autoset.service >/dev/null 2>&1
  rm -f "/lib/systemd/system/swcursor-autoset.service" >/dev/null 2>&1
  systemctl daemon-reload >/dev/null 2>&1
  exit 1
}
if [ -f "/usr/local/bin/swcursor-autoset" ]; then
  echo "Install swcursor-autoset service ..."
  systemctl daemon-reload >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  systemctl enable swcursor-autoset.service >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  systemctl start swcursor-autoset.service >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
else
  undo_changes
fi
exit 0