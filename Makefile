fedora-qubip.iso: fedora-live-qubip.ks
	livecd-creator -c fedora-live-qubip.ks -f Fedora-QUBIP --cache=/var/live/cache
	mv Fedora-QUBIP.iso $@
