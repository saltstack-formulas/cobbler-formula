To do a PXE boot of the gparted network image...

    echo "/srv/www/cobbler/ks_mirror *(ro,sync,no_subtree_check)" >> /etc/exports
    exportfs -a
    wget http://downloads.sourceforge.net/gparted/gparted-live-0.21.0-1-i586.iso
    mount -o loop gparted-live-0.21.0-1-i586.iso /mnt
    cobbler import --path=/mnt --name gparted --breed=generic # puts files into /srv/www/cobbler/ks_mirror/gparted - this step will give a failure message, ignore it
    cobbler distro add --breed=generic --arch=i386 --name=gparted --kernel=/srv/www/cobbler/ks_mirror/gparted/live/vmlinuz --initrd=/srv/www/cobbler/ks_mirror/gparted/live/initrd.img --kopts="boot=live config noswap noprompt nosplash netboot=nfs nfsroot=@@http_server@@:/srv/www/cobbler/ks_mirror/gparted"
    cobbler profile add --name=gparted --enable-menu=true --distro=gparted

Once the profile is generated, systems can be modified to use this profile to run gparted

Care should be taken not to accidentally network an install onto a machine when reverting from the gparted profile.
