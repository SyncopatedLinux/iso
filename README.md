# syncopated: the iso

> If I could do it all over again, this is how I would design an operating system. -Bill Gates

> If Bon Jovi were alive today, he'd for sure be confused by this -Rolling Stone

> What the fuck is a linux? -Randall Cunningham


### installing the iso

Download the file and write to a usb drive.
`wget http://gitlab.com/syncopatedlinux/iso/syncopatedlinux_june2023.iso`

Use dd to write the iso to the flash drive
`sudo dd if=$ISO of=$USB bs=512K oflag=direct status=progress && sync`

### Building the ISO

`sudo pacman -S archiso mkinitcpio-archiso git squashfs-tools --needed`

`git clone https://gitlab.com/syncopatedlinux/iso.git ~/Workspace/iso`

`sudo pacman -Scc --noconfirm`

`sudo ./build -u`

### Testing the ISO

`./run_test_vm.rb`

#TODO: fake the evidence
