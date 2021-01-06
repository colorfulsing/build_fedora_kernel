# Build ACS & Agesa patched Fedora 33 kernel

This docker image is based on `stefanlehmann`'s [`stefanlehmann/acs_fedora`](https://github.com/stefanleh/fedora_acs_kernel_build "Docker Image for building custom ACS & Agesa patched Fedora kernels") docker image and `dglb99`'s [script](https://forum.level1techs.com/t/trying-to-compile-acs-override-patch-and-got-stuck-fedora-33/163658/6 "dglb99 kernel build script"). It allows you to build a custom Fedora 33 kernel with ACS and Agesa patches.

# Build the image (optional)

```bash
docker build -t colorfulsing/acs_fedora_33 -f Dockerfile .
```

# Usage

```bash
# Replace `<local_directory>` with the local directory to which the compiled kernel rpms will be copied.
# Replace `<kernel_version>` with the kernel version you want to build.
# docker run -it -v <local_directory>:/rpms colorfulsing/acs_fedora_33 <kernel_version>
docker run -it -v /mnt:/rpms colorfulsing/acs_fedora_33 5.9.16-200.fc33
```
