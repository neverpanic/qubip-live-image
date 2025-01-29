# QUBIP Live Image

This project is used to build a Fedora Live Image in ISO format as a test
environment for project QUBIP.

The repository is a fork of the Fedora kickstart files from
https://pagure.io/fedora-kickstarts/. The QUBIP image is in
`fedora-qubip-live.ks`.

## Prerequisites
You need the following Fedora packages installed:

 - patch
 - livecd-tools

Additionally, there's a bug somewhere between `livecd-tools` and the Python
`urllib` package that breaks `livecd-creator`. To fix that, you can apply a
patch for now:

```sh
(cd /usr/lib64/python3.13/urllib && patch -p5) <urllib.patch
```

To speed up subsequent builds, create a directory to use as cache for
downloaded RPMs:

```sh
sudo mkdir /var/cache/live
```

## Building the Image
To build the image, use `livecd-creator`:

```sh
sudo livecd-creator \
    -c fedora-live-qubip.ks \
    -f Fedora-QUBIP \
    --cache=/var/cache/live
```

The output will be in `Fedora-QUBIP.iso`. Alternatively, you can use the
included Makefile to achieve run the command.
