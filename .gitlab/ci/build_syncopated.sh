#!/bin/bash

#shellcheck disable=2016

begin=$(date +%s)

if ! hash mkarchiso curl > /dev/null 2>&1; then
	echo "${0##*/}: error: one or more missing packages: archiso curl"
	exit 1
fi

# placeholder for packages.x86_64 modifcations

while getopts ":huLtl:" OPT; do
	case "$OPT" in
		h)
			echo
			echo "Usage: ${0##*/} [-hutL]"
			echo
			echo "    -h           Print this message and exit"
			echo "    -t           Enable testing repos"
			echo "    -L           Use the LTS kernel instead of vanilla"
			echo "    -u           Remotely update the installer"
			echo "    -l <PATH>    Locally update the installer"
			echo
			exit 0
			;;
		l)
			echo "Updating installer locally"
			sleep 0.5
			[[ -f "$OPTARG" ]] || { echo "${0##*/}: error: path does not exist or is not a file: $OPTARG"; exit 1; }
			cp -vf "$OPTARG" airootfs/usr/local/bin/installer || exit 1
			;;
		u)
			echo "Updating installer remotely"
			sleep 0.5
			if ! curl -#fSL https://gitlab.com/syncopatedlinux/iso/-/raw/main/airootfs/usr/local/bin/installer -o airootfs/usr/local/bin/installer; then
				echo "${0##*/}: error: failed to update installer"
				exit 1
			fi
			;;
		L)
			echo "Enabling LTS"
			sleep 0.5
			sed -i 's/^broadcom-wl$/broadcom-wl-dkms/g' packages.x86_64
			sed -i '/^linux$/ a linux-lts-headers' packages.x86_64
			sed -i 's/^linux$/linux-lts/g' packages.x86_64
			sed -i 's/-linux/-linux-lts/g' efiboot/loader/entries/*
			sed -i 's/-linux/-linux-lts/g' syslinux/*.cfg
			sed -i 's/-linux/-linux-lts/g' grub/grub.cfg
			sed -i 's/"archlabs"/"archlabs-lts"/g' profiledef.sh
			lts=true
			;;
		t)
			testing=true
			echo "Enabling testing repos"
			sleep 0.5
			sed -i 's/^# \(\[archlabs-testing]\)$/\1/g' pacman.conf
			sed -i 's/^# \(SigLevel =  Optional TrustAll\)$/\1/g' pacman.conf
			sed -i 's~^# \(Server =  https://pub-7d84e047b852442a86fd6d7feb1ff2cd.r2.dev/\$repo/\$arch\)$~\1~g' pacman.conf
			sed -i 's~^# \(Server =  https://github.com/ArchLabs/\$repo/raw/master/\$arch\)$~\1~g' pacman.conf
			sed -i 's~^# \(Server =  https://bitbucket.org/archlabslinux/\$repo/raw/master/\$arch\)$~\1~g' pacman.conf
			sed -i 's/^# \(\[archlabs-testing]\)$/\1/g' airootfs/etc/pacman.conf
			sed -i 's~^# \(Server =  https://pub-7d84e047b852442a86fd6d7feb1ff2cd.r2.dev/\$repo/\$arch\)$~\1~g' airootfs/etc/pacman.conf
			sed -i 's~^# \(Server =  https://github.com/ArchLabs/\$repo/raw/master/\$arch\)$~\1~g' airootfs/etc/pacman.conf
			sed -i 's~^# \(Server =  https://bitbucket.org/archlabslinux/\$repo/raw/master/\$arch\)$~\1~g' airootfs/etc/pacman.conf
			;;
		:)
			echo "${0##*/}: error: -$OPTARG requires an argument: <PATH_TO_INSTALLER>"
			exit 1
			;;
		*)
			echo "${0##*/}: error: invalid flag '$OPT' -- use -h for options"
			exit 1
			;;
	esac
done
shift $((OPTIND - 1))

# update os-release and lsb-release
[[ -e airootfs/etc/os-release ]] && sed -i "s/\(VERSION_ID\)=.*/\1=$(date +%Y.%m.%d)/g" airootfs/etc/os-release
[[ -e airootfs/etc/lsb-release ]] && sed -i "s/\(DISTRIB_RELEASE\)=.*/\1=$(date +%Y.%m.%d)/g" airootfs/etc/lsb-release

fetch_cachyos_mirrorlist() {

    local _mirrorlist_url="https://github.com/CachyOS/CachyOS-PKGBUILDS/raw/master/cachyos-mirrorlist/cachyos-mirrorlist"

    curl -sSL "${_mirrorlist_url}" > archiso/airootfs/etc/pacman.d/cachyos-mirrorlist
}

fetch_cachyos_mirrorlist

# build it
mkarchiso -v .

# clean up
rm -rf work

if [[ $testing == 'true' ]]; then
	sed -i 's/^\(\[archlabs-testing]\)$/# \1/g' pacman.conf
	sed -i 's/^\(SigLevel =  Optional TrustAll\)$/# \1/g' pacman.conf
	sed -i 's~^\(Server =  https://pub-7d84e047b852442a86fd6d7feb1ff2cd.r2.dev/\$repo/\$arch\)$~# \1~g' pacman.conf
	sed -i 's~^\(Server =  https://github.com/ArchLabs/\$repo/raw/master/\$arch\)$~# \1~g' pacman.conf
	sed -i 's~^\(Server =  https://bitbucket.org/archlabslinux/\$repo/raw/master/\$arch\)$~# \1~g' pacman.conf
	sed -i 's/^\(\[archlabs-testing]\)$/# \1/g' airootfs/etc/pacman.conf
	sed -i 's~^\(Server =  https://pub-7d84e047b852442a86fd6d7feb1ff2cd.r2.dev/\$repo/\$arch\)$~# \1~g' airootfs/etc/pacman.conf
	sed -i 's~^\(Server =  https://github.com/ArchLabs/\$repo/raw/master/\$arch\)$~# \1~g' airootfs/etc/pacman.conf
	sed -i 's~^\(Server =  https://bitbucket.org/archlabslinux/\$repo/raw/master/\$arch\)$~# \1~g' airootfs/etc/pacman.conf
fi

if [[ $lts == 'true' ]]; then
	sed -i 's/^broadcom-wl-dkms$/broadcom-wl/g' packages.x86_64
	sed -i '/linux-lts-headers/d' packages.x86_64
	sed -i 's/^linux-lts$/linux/g' packages.x86_64
	sed -i 's/-linux-lts/-linux/g' efiboot/loader/entries/*
	sed -i 's/-linux-lts/-linux/g' syslinux/*.cfg
	sed -i 's/-linux-lts/-linux/g' grub/grub.cfg
	sed -i 's/archlabs-lts/archlabs/g' profiledef.sh
fi

end=$(date +%s)
echo "build took $(( (end - begin) / 60 ))m $(( (end - begin) % 60 ))s"

