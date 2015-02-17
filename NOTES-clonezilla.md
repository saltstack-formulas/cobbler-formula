To do a PXE boot of the clonezilla network image...

    echo "/srv/www/cobbler/ks_mirror *(ro,sync,no_subtree_check)" >> /etc/exports
    exportfs -a
    wget http://downloads.sourceforge.net/project/clonezilla/clonezilla_live_stable/2.3.1-18/clonezilla-live-2.3.1-18-amd64.iso
    mount -o loop clonezilla-live-2.3.1-18-amd64.iso /mnt
    cobbler import --path=/mnt --name clonezilla --breed=generic # puts files into /srv/www/cobbler/ks_mirror/clonezilla - this step will give a failure message, ignore it
    cobbler distro add --breed=generic --arch=x86_64 --name=clonezilla --kernel=/srv/www/cobbler/ks_mirror/clonezilla/live/vmlinuz --initrd=/srv/www/cobbler/ks_mirror/clonezilla/live/initrd.img --kopts="boot=live config noswap nolocales edd=on nomodeset ocs_live_run='ocs-live-general' ocs_live_extra_param='' keyboard-layouts='' ocs_live_batch='no' locales='' vga=788 nosplash noprompt fetch=http://@@http_server@@/cblr/ks_mirror/clonezilla/live/filesystem.squashfs"
    cobbler profile add --name=clonezilla --enable-menu=true --distro=clonezilla

Once the profile is generated, systems can be modified to use this profile to run gparted

Care should be taken not to accidentally network an install onto a machine when reverting from the gparted profile.
