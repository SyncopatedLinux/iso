# syncopated live iso

A variant of [ArchLabs](https://bitbucket.org/archlabslinux/iso)


### Building the ISO

`sudo pacman -S archiso mkinitcpio-archiso git squashfs-tools --needed`

`git clone https://gitlab.com/syncopatedlinux/iso.git ~/Workspace/iso`

`sudo pacman -Scc --noconfirm`

`sudo ./build -u`


When finished there will be a directory called `out`, the ISO will be in there.

### Testing the ISO

`./run_test_vm.rb`

### Customization

- `profiledef.sh` contains the build setup for archiso and file permissions for certain files on the ISO.
   See: https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/docs/README.profile.rst

- `packages.x86_64` This will be generated when building, to add more packages edit the build script.

- `efiboot` and `syslinux` contain boot configuration files.

- `pacman.conf` is used while building and has entries for the `archlabs` and `archlabs-testing` repos.

- `airootfs` is the live boot file system. This is where to add anything that you want included on the ISO.

Remember, **everything must be done as root**, if you add something, do it with `su`, `sudo`, or `doas`.
Once added update `profiledef.sh` if special permissions are needed *(executable, read-only, etc.)*
Also note that the files included in the iso will **not** be added to installed systems, this must be done
in the archlabs installer.

