# This is the kickstart for Fedora IoT disk images.

text # don't use cmdline -- https://github.com/rhinstaller/anaconda/issues/931
lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC

selinux --enforcing
rootpw --lock --iscrypted locked

bootloader --timeout=1 --append="modprobe.blacklist=vc4"

network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=NetworkManager,sshd

zerombr
clearpart --all --initlabel --disklabel=msdos
autopart --nohome --noswap --type=plain

# Equivalent of %include fedora-repo.ks
# Pull from the ostree repo that was created during the compose
ostreesetup --nogpg --osname=fedora-iot --remote=fedora-iot --url=https://kojipkgs.fedoraproject.org/compose/iot/repo/ --ref=fedora/rawhide/${basearch}/iot

reboot

%post --erroronfail

# Find the architecture we are on
arch=$(uname -m)
# Setup Raspberry Pi firmware
if [[ $arch == "aarch64" ]]; then
cp -P /usr/share/uboot/rpi_arm64/u-boot.bin /boot/efi/rpi-u-boot.bin
fi

# Set the origin to the "main ref", distinct from /updates/ which is where bodhi writes.
# We want consumers of this image to track the two week releases.
ostree admin set-origin --index 0 fedora-iot https://dl.fedoraproject.org/iot/repo/ "fedora/rawhide/${arch}/iot"

# Make sure the ref we're supposedly sitting on (according
# to the updated origin) exists.
ostree refs "fedora-iot:fedora/rawhide/${arch}/iot" --create "fedora-iot:fedora/rawhide/${arch}/iot"

# Remove the old ref so that the commit eventually gets cleaned up.
ostree refs "fedora-iot:fedora/rawhide/${arch}/iot" --delete

# delete/add the remote with new options to enable gpg verification
# and to point them at the cdn url
ostree remote delete fedora-iot
ostree remote add --set=gpg-verify=true --set=gpgkeypath=/etc/pki/rpm-gpg/ --set=contenturl=mirrorlist=https://ostree.fedoraproject.org/iot/mirrorlist  fedora-iot 'https://ostree.fedoraproject.org/iot'

# We're getting a stray console= from somewhere, work around it
rpm-ostree kargs --delete=console=tty0

# older versions of livecd-tools do not follow "rootpw --lock" line above
# https://bugzilla.redhat.com/show_bug.cgi?id=964299
passwd -l root

# Work around https://bugzilla.redhat.com/show_bug.cgi?id=1193590
cp /etc/skel/.bash* /var/roothome

# Remove any persistent NIC rules generated by udev
rm -vf /etc/udev/rules.d/*persistent-net*.rules

echo "Removing random-seed so it's not the same in every image."
rm -f /var/lib/systemd/random-seed

echo "Packages within this iot image:"
echo "-----------------------------------------------------------------------"
rpm -qa --qf '%{size}\t%{name}-%{version}-%{release}.%{arch}\n' |sort -rn
echo "-----------------------------------------------------------------------"
# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
echo "(Don't worry -- that out-of-space error was expected.)"

rm -f /etc/NetworkManager/system-connections/*.nmconnection

# Anaconda is writing an /etc/resolv.conf from the install environment.
# The system should start out with an empty file, otherwise cloud-init
# will try to use this information and may error:
# https://bugs.launchpad.net/cloud-init/+bug/1670052
truncate -s 0 /etc/resolv.conf

%end
