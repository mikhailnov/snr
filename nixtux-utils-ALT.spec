Name: nixtux-utils
Summary: NixTux utils
Version: 0.1
Release: alt1
License: GPL
Group: System/Configuration/Packaging
Url: https://gitlab.com/mikhailnov/nixtux-utils
BuildArch: noarch
Source0: %name-%version.tar
Requires: apt-reposync

%description
Different scripts, e.g. for working with packages.

%description -l ru_RU.UTF-8
Различные скрипты, например, для работы с пакетами.

%prep
%setup
%install
install -m0755 ./apt-reposync.sh %{buildroot}/%{_bindir}/apt-reposync
#----------------------------------------------------------------------------

%description -n apt-reposync
Script apt-reposync to sync versions of local packages with the ones available in the repository.
Useful e.g. after uncessfull attempt to upgrade to a new branch.

%description -n apt-reposync -l ru_RU.UTF-8
Скрипт apt-reposync для принудительной синхронизации версий пакетов с доступными в репозитории.
Полезно, например, после неудачного частичного обновления до нового бранча.

%files -n apt-reposync
%_bindir/apt-reposync
#----------------------------------------------------------------------------

%changelog
* Sat Sep 29 2018 Mikhail Novosyolov <mikhailnov@altlinux.org> 0.1-alt1
- Initial build for ALT Linux (apt-reposync script)
