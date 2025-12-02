#!/bin/bash
if [ "$(which swcursor-autoset)" != "" ] && [ "$1" == "install" ]; then
  echo "The command \"swcursor-autoset\" is already present. Can not install this."
  echo "File: \"$(which swcursor-autoset)\""
  exit 1
fi
exit 0