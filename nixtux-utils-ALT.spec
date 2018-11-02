Name: nixtux-utils
Summary: NixTux utils
Group: System/Configuration/Packaging
Version: 0.2
Release: alt1
License: GPL
Url: https://gitlab.com/mikhailnov/nixtux-utils
BuildArch: noarch
Source0: %name-%version.tar
Packager: Mikhail Novosyolov <mikhailnov@altlinux.org>

%description
Different scripts, e.g. for working with packages.

%description -l ru_RU.UTF-8
Различные скрипты, например, для работы с пакетами.

%prep
%setup
%install
mkdir -p %{buildroot}/%{_bindir}
install -m0755 ./apt-reposync.sh %{buildroot}/%{_bindir}/apt-reposync
install -m0755 ./wr.sh %{buildroot}/%{_bindir}/wr
#----------------------------------------------------------------------------
%package -n apt-reposync
Summary: apt-reposync
Group: System/Configuration/Packaging
Requires: lynx

%description -n apt-reposync
Script apt-reposync to sync versions of local packages with the ones available in the repository.
Useful e.g. after uncessfull attempt to upgrade to a new branch.

%description -n apt-reposync -l ru_RU.UTF-8
Скрипт apt-reposync для принудительной синхронизации версий пакетов с доступными в репозитории.
Полезно, например, после неудачного частичного обновления до нового бранча.

%files -n apt-reposync
%_bindir/apt-reposync
#----------------------------------------------------------------------------
%package -n wr
Summary: which repo package is available in
Group: System/Configuration/Packaging

%description -n wr
'which repo' utility. Which branches have which version of package.
Example:
$ ./wr.sh alt opam
Sisyphus: 2.0.1-alt1
Sisyphus: 2.0.0-alt1.S1.rc
p8:       1.3.1-alt1.M80P.1

%files -n wr
%_bindir/wr
#----------------------------------------------------------------------------

%changelog
* Fri Nov 02 2018 Mikhail Novosyolov <mikhailnov@altlinux.org> 0.2-alt1
- wr utility
* Sat Sep 29 2018 Mikhail Novosyolov <mikhailnov@altlinux.org> 0.1-alt1
- Initial build for ALT Linux (apt-reposync script)
