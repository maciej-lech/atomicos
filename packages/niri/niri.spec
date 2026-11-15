%bcond check 1

Name:           niri
Version:        26.04
# atomicos: Fedora's release plus a local suffix, so it sorts above Fedora's build of the same version
Release:        2.1.atomicos%{?dist}
Summary:        Scrollable-tiling Wayland compositor

SourceLicense:  GPL-3.0-or-later
# (MIT OR Apache-2.0) AND BSD-3-Clause
# (MIT OR Apache-2.0) AND Unicode-3.0
# 0BSD OR MIT OR Apache-2.0
# Apache-2.0
# Apache-2.0 AND MIT
# Apache-2.0 OR MIT
# Apache-2.0 OR MIT OR Unlicense
# Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT
# BSD-2-Clause
# BSD-2-Clause OR Apache-2.0 OR MIT
# BSD-3-Clause OR MIT OR Apache-2.0
# GPL-3.0-or-later
# ISC
# MIT
# MIT OR Apache-2.0
# MIT OR Apache-2.0 OR LGPL-2.1-or-later
# MIT OR Apache-2.0 OR Zlib
# MIT OR Zlib OR Apache-2.0
# MPL-2.0
# Unlicense OR MIT
# Zlib
# Zlib OR Apache-2.0 OR MIT
License:        %{shrink:
    GPL-3.0-or-later AND
    Apache-2.0 AND
    BSD-2-Clause AND
    BSD-3-Clause AND
    ISC AND
    MIT AND
    MPL-2.0 AND
    Unicode-3.0 AND
    Zlib AND
    (0BSD OR MIT OR Apache-2.0) AND
    (Apache-2.0 OR MIT) AND
    (Apache-2.0 OR MIT OR Unlicense) AND
    (Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT) AND
    (BSD-2-Clause OR Apache-2.0 OR MIT) AND
    (BSD-3-Clause OR MIT OR Apache-2.0) AND
    (MIT OR Apache-2.0 OR LGPL-2.1-or-later) AND
    (MIT OR Apache-2.0 OR Zlib) AND
    (Unlicense OR MIT)
}
# LICENSE.dependencies contains a full license breakdown

URL:            https://github.com/niri-wm/niri
Source0:        %{url}/archive/v%{version}/niri-%{version}.tar.gz

# generated using vendor.sh
Source1:        niri-%{version}-vendor.tar.xz
Source2:        vendor.toml
Source3:        vendor.sh

# atomicos: pause DRM devices before exit so outputs stay lit for the next compositor
# (greeter to session handoff); niri-wm/niri discussion 4763
Patch:          0001-Pause-DRM-devices-before-exiting-to-keep-outputs-lit.patch

ExcludeArch:    %{ix86}

BuildRequires:  cargo-rpm-macros
BuildRequires:  clang
BuildRequires:  gcc
BuildRequires:  glibc-devel
BuildRequires:  systemd-rpm-macros

BuildRequires:  pkgconfig(cairo)
BuildRequires:  pkgconfig(dbus-1)
BuildRequires:  pkgconfig(gbm)
BuildRequires:  pkgconfig(gdk-pixbuf-2.0)
BuildRequires:  pkgconfig(gio-2.0)
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gobject-2.0)
BuildRequires:  pkgconfig(gtk4)
BuildRequires:  pkgconfig(libadwaita-1)
BuildRequires:  pkgconfig(libdisplay-info)
BuildRequires:  pkgconfig(libinput)
BuildRequires:  pkgconfig(libpipewire-0.3)
BuildRequires:  pkgconfig(libseat)
BuildRequires:  pkgconfig(libspa-0.2)
BuildRequires:  pkgconfig(libudev)
BuildRequires:  pkgconfig(pango)
BuildRequires:  pkgconfig(pangocairo)
BuildRequires:  pkgconfig(systemd)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(wayland-cursor)
BuildRequires:  pkgconfig(wayland-server)
BuildRequires:  pkgconfig(xkbcommon)

# required for xwayland support
Requires:       xwayland-satellite >= 0.7

# shared libraries opened with dlopen
Requires:       libwayland-server

# required for portal support 
Recommends:     gnome-keyring
Recommends:     xdg-desktop-portal-gnome
Recommends:     xdg-desktop-portal-gtk

# applications bound by keyboard shortcuts in default configuration 
Recommends:     alacritty
Recommends:     fuzzel
Recommends:     swaylock
Recommends:     wireplumber

# applications spawned at startup in default configuration
Recommends:     waybar

%description
A scrollable-tiling Wayland compositor.

%prep
%autosetup -n niri-%{version} -a1 -p1
%cargo_prep -N
# include full configuration for vendored dependencies
cat %{SOURCE2} >> .cargo/config.toml

%build
# set version string without commit information
export NIRI_BUILD_VERSION_STRING="%{version}"
%cargo_build

# generate shell completions
target/rpm/niri completions bash > niri.bash
target/rpm/niri completions fish > niri.fish
target/rpm/niri completions zsh > _niri

# write license summary and breakdown
%{cargo_license_summary}
%{cargo_license} > LICENSE.dependencies
%{cargo_vendor_manifest}

%install
install -Dpm0755 target/rpm/niri -t %{buildroot}%{_bindir}

install -Dpm0755 resources/niri-session -t %{buildroot}%{_bindir}
install -Dpm0644 resources/niri.desktop -t %{buildroot}%{_datadir}/wayland-sessions
install -Dpm0644 resources/niri-portals.conf -t %{buildroot}%{_datadir}/xdg-desktop-portal
install -Dpm0644 resources/niri.service -t %{buildroot}%{_userunitdir}
install -Dpm0644 resources/niri-shutdown.target -t %{buildroot}%{_userunitdir}

install -Dpm0644 niri.bash -t %{buildroot}%{bash_completions_dir}
install -Dpm0644 niri.fish -t %{buildroot}%{fish_completions_dir}
install -Dpm0644 _niri -t %{buildroot}%{zsh_completions_dir}

%if %{with check}
%check
# * skip tests that require a running session
# * limit test parallelism to avoid "too many open files" errors
export RAYON_NUM_THREADS=2
%cargo_test -- --workspace --exclude niri-visual-tests -- --test-threads 2
%endif

%post
%systemd_user_post niri.service

%preun
%systemd_user_preun niri.service

%postun
%systemd_user_postun_with_reload niri.service

%files
%license LICENSE
%license LICENSE.dependencies
%license cargo-vendor.txt

%doc README.md
%doc resources/default-config.kdl
%doc docs/wiki

%{_bindir}/niri
%{_bindir}/niri-session

%dir %{_datadir}/wayland-sessions/
%{_datadir}/wayland-sessions/niri.desktop
%dir %{_datadir}/xdg-desktop-portal/
%{_datadir}/xdg-desktop-portal/niri-portals.conf

%{_userunitdir}/niri.service
%{_userunitdir}/niri-shutdown.target

%{bash_completions_dir}/niri.bash
%{fish_completions_dir}/niri.fish
%{zsh_completions_dir}/_niri

%changelog
* Sun Nov 15 2026 Maciej Lech - 26.04-2.1.atomicos
- Pause DRM devices before exit to keep outputs lit across the greeter to session handoff
- Based on Fedora dist-git rpms/niri f45 79c992c
