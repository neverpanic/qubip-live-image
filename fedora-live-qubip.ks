%include fedora-live-workstation.ks

%packages
-gnome-initial-setup
-anaconda-webui

nginx
curl
openssl
oqsprovider
crypto-policies-scripts
tcpdump
sed
%end

%post
# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="gnome"/' /etc/sysconfig/livesys

# Remove live installer (this will avoid triggering https://pagure.io/livesys-scripts/blob/main/f/libexec/livesys/sessions.d/livesys-gnome#_42)
rm /usr/share/applications/liveinst.desktop
# Disable GNOME welcome tour
cat >> /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override <<- "FOE"
	welcome-dialog-last-shown-version='4294967295'
FOE

# Enable the PQ-TEST crypto-policy module
update-crypto-policies --set DEFAULT:TEST-PQ
# Enable OQSprovider in OpenSSL config
sed -i '/default = default_sect/a oqsprovider = oqs_sect' /etc/pki/tls/openssl.cnf

sed -i '/activate = 1/ {
a [oqs_sect]
a activate = 1
}' /etc/pki/tls/openssl.cnf
%end
