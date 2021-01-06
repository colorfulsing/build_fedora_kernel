#!/bin/bash

if /root/acs-override-script-fedora33.sh "$1" 1; then
  cp -R ~/rpmbuild/RPMS/x86_64/*.rpm /rpms/ || exit 1
else
  echo "FAILED!"
fi
