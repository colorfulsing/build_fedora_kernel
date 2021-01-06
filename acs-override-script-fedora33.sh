#!/bin/bash

# Created by dglb99
# https://forum.level1techs.com/t/trying-to-compile-acs-override-patch-and-got-stuck-fedora-33/163658/6
# According to dglb99's post, he/she (sorry, I don't know if a he or a she just by the username) based on this guide https://passthroughpo.st/agesa_fix_fedora/

# Modified by colorfulsing to provide the following:
# - Added error checks
# - Modified to allow docker build
# - Dynamic kernel version by using variables
# - Added AGESA patch

#check if docker build
IS_DOCKER_BUILD="0"
if [ "$2" == "1" ]; then
  IS_DOCKER_BUILD="1"
fi

#Check for updates
sudo dnf check-update -y; test $? -ne 1 || exit 1
sudo dnf upgrade -y || exit 1

#get kernel version
MY_KERNEL_VERSION="$1"
if [ "$MY_KERNEL_VERSION" == "" ]; then
  if [ "$IS_DOCKER_BUILD" == "1" ]; then
    echo "Kernel version can't be null when on docker build mode"
    exit 1
  fi
  MY_KERNEL_VERSION="$(dnf list installed "kernel.x86_64" | grep -Eo '  [0-9][^ ]+' | grep -Eo '[^ ]+' | head -n 1)" || exit 1
fi
echo "Kernel version to be build is ${MY_KERNEL_VERSION}"

#install ‘mockbuild’ user
sudo yum install mock -y || exit 1
sudo useradd -s /sbin/nologin mockbuild || exit 1

#1 Add RPM Fusion
sudo dnf install "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" -y || exit 1

#2 Add dependencies to build your own kernel
sudo dnf install fedpkg fedora-packager rpmdevtools ncurses-devel pesign -y || exit 1

#3 Set home build directory
rpmdev-setuptree || exit 1

#4 Install the kernel source and finish installing dependencies
cd ~/rpmbuild/SOURCES || exit 1
koji download-build --arch=src "kernel-${MY_KERNEL_VERSION}" || exit 1
rpm -Uvh "kernel-${MY_KERNEL_VERSION}.src.rpm" || exit 1
cd ~/rpmbuild/SPECS || exit 1
sudo dnf builddep kernel.spec -y || exit 1

#5 Add the ACS patch (link) as ~/rpmbuild/SOURCES/add-acs-override.patch
mkdir ~/acs-patch-files || exit 1
cd ~/acs-patch-files || exit 1
git clone https://aur.archlinux.org/linux-vfio.git || exit 1
cp ~/acs-patch-files/linux-vfio/add-acs-overrides.patch ~/rpmbuild/SOURCES/ || exit 1

#5.1 Add AGESA patch
cp ~/agesa.patch ~/rpmbuild/SOURCES/ || exit 1

#6 Edit ~/rpmbuild/SPECS/kernel.spec to set the build ID and add the patch. Since each release of the spec file could change, it’s not much help giving line numbers, but both of these should be near the top of the file.
cd ~/rpmbuild/SPECS || exit 1
sed -i '31 i # Set buildid' ./kernel.spec || exit 1
sed -i '32 i %define buildid .acs' ./kernel.spec || exit 1
sed -i '33 i # ACS overrides patch' ./kernel.spec || exit 1
sed -i '34 i Patch1000: add-acs-overrides.patch' ./kernel.spec  || exit 1
sed -i '35 i # AGESA patch' ./kernel.spec || exit 1
sed -i '36 i Patch1001: agesa.patch' ./kernel.spec || exit 1

#This is the part of my script that inserts the build ID into the kernel.spec file

#7 Compile the kernel! This can take a while.
cd ~/rpmbuild/SPECS || exit 1
rpmbuild -bb --without debug --target=x86_64 kernel.spec || exit 1

#8 install the kernel
if [ "$IS_DOCKER_BUILD" != "1" ]; then
  cd ~/rpmbuild/RPMS/x86_64 || exit 1
  sudo dnf update *.rpm || exit 1

  #9 Update Grub Config
  sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg || exit 1

  #10 update and reboot
  sudo dnf clean all || exit 1
  sudo dnf update -y || exit 1
  #sudo reboot || exit 1
fi
