#!/bin/sh

set -e

echo "Got base path at '$1'"
echo "Got curent version of '$2'"
echo "Got previsous version of '$3'"

if [ ! -f /usr/lib/contractor/util/blueprintLoader ]
then
  echo "WARNING: contractor not found, assuming you are installing for the PXE resources only, skiping blueprint loading."
  exit 0
fi

echo "Loading Blueprints..."
/usr/lib/contractor/util/blueprintLoader ${1}usr/lib/contractor/resources/utility.toml
