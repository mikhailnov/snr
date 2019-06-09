Summary: Simple wrapper to quickly run systemd-nspawn containers
Name: snr
License: MIT
Group: System/Base
Url: https://github.com/mikhailnov/snr
Version: 1.1
Release: alt1
Source0: %name-%version.tar
Requires: systemd-container

%description
Simple wrapper to quickly run systemd-nspawn containers with support to:
- run graphical applications inside container
- have full access to videocard
- have working sound input and output.

%prep
%setup -q

%build
:

%install
%makeinstall_std

%files
%_bindir/snr
%config(noreplace) %_sysconfdir/snr.conf


%changelog

* Sun Jun 09 2019 Mikhail Novosyolov <mikhailnov@altlinux.org> 1.1-alt1
- Initial build for ALT Linux

