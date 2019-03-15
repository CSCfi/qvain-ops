#!/bin/bash -e
#
# -wvh- make production machine clone to build RPMs
#
#       This script tries to start a virtual machine with systemd-nspawn / machinectl based on a CentOS cloud image.
#       You need a pretty recent Linux distribution with systemd >= 225 (wild guess).
#
#       Usage:
#
#           ./make_builder.sh CentOS-7-x86_64-GenericCloud-1805.raw /home/vms/builder
#
#       One could import a CentOS cloud image with:
#
#           machinectl pull-raw https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1805.raw.tar.gz NameOfMachine
#
#       The image should end up in /var/lib/machines, but the CentOS image seems to be sparse and extracts to something
#       a whole lot bigger than the actual 800MB of actual data, and `machinectl` doesn't seem smart enough to resize the
#       BTRFS image so you could get "out of disk space" errors.
#
#       Another option is to manually unpack the image and copy it to /var/lib/machines with cp's `--sparse` argument:
#
#           cp -av --sparse=always CentOS-7-x86_64-GenericCloud-1805.raw /var/lib/machines
#
#       Yet another option is to copy the image's files to a real directory, which is the option this script uses.
#

# bootstrap account
SUDOER=machine

if [ $UID -ne 0 ]; then
	echo "run this script as root" >&2
	exit 1
fi

if [ -z "$2" ]; then
	echo "Usage: $0 <image.raw> <target> [ssh.pub]" >&2
	exit 0
fi

if [ ! -e "$1" ]; then
	echo "$0: error: image not found" >&2
	exit 1
fi

if [ -d "$2" ]; then
	echo "$0: found existing image, refusing to remove" >&2
	exit 1
fi

if [ -n "$3" -a ! -e "$3" ]; then
	echo "$0: you gave an ssh public key as argument, but the file doesn't exist" >&2
	exit 1
fi

RAWIMG=$1
TARGET=${2%/}
SSHKEY=${3}
VMNAME=${TARGET##*/}

# calculate partition offset and mount
#mount -t xfs -o loop,offset=$((2048*512)) CentOS-7-x86_64-GenericCloud-1805.raw mnt/

# ... or better, use losetup because maths is hard
LOOPDEV=$(losetup -vrPf --show ${RAWIMG})

if [ ! -e ${LOOPDEV} ]; then
	echo "$0: can't find loopback device for image" >&2
	exit 1
fi

if [ ! -e ${LOOPDEV}p1 ]; then
	echo "$0: can't find first partition of loopback image" >&2
	exit 1
fi

if ! find mnt/ -maxdepth 0 -type d -empty 2>/dev/null; then
	echo "$0: can't mount to ./mnt: not a directory or directory not empty" >&2
	exit 1
fi

mount /dev/loop2p1 mnt/

trap "{ umount mnt/ 2>/dev/null; losetup -d ${LOOPDEV} 2>/dev/null; }" EXIT

rsync -axHAWX --numeric-ids --info=progress2 mnt/ ${TARGET}

#umount mnt/
#losetup -d ${LOOPDEV}

# remove default image configuration
rm -f ${TARGET}/etc/{machine-id,locale.conf,vconsole.conf,localtime,hostname}

# set basic configuration with systemd-firstboot (requires respective files to be missing from /etc)
if ! systemd-firstboot --root=${TARGET} --hostname=${VMNAME} --copy-locale --copy-keymap --copy-timezone --setup-machine-id; then
	echo "$0: warning: systemd-firstboot returned a non-zero exit code: $?" >&2
fi

# bootstrap with our host resolv.conf
cp /etc/resolv.conf ${TARGET}/etc/resolv.conf

if [ -z ${PASSWD} ]; then
	echo "$0: warning: PASSWD not set, using default" >&2
fi

# set a password before we boot because otherwise we can't login
# CentOS doesn't support `machinectl shell` yet :(
{
	echo passwd;
	echo -ne "${PASSWD:-secret}\n${PASSWD:-secret}\n";
} | systemd-nspawn -UD ${TARGET}

# force removal of cloud-init before booting so it doesn't hang 2 minutes on boot and doesn't have a chance to create any cloud users
#{
#	echo yum -y remove cloud-init cloud-utils-growpart;
#} | systemd-nspawn -UD ${TARGET}

# make sure systemd-networkd is running on the host
systemctl start systemd-networkd

# read public key if provided
if [ -n "${SSHKEY}" ]; then
	PUBKEY=$(<${SSHKEY})
fi

cat <<-EOF > ${TARGET}/root/bootstrap.sh
	#!/bin/sh
	PATH="/usr/sbin:/usr/bin:/bin"; export PATH
	PUBKEY='${PUBKEY}'
	
	yum remove -y cloud-init cloud-utils-growpart

	# uncomment if not using host resolv.conf
	#echo nameserver 8.8.8.8 > /etc/resolv.conf
	/sbin/dhclient
	yum install -y systemd-networkd systemd-resolved
	systemctl disable network
	systemctl disable NetworkManager
	systemctl enable systemd-networkd
	systemctl enable systemd-resolved
	# can't start these yet without a real boot
	#systemctl start systemd-resolved
	#systemctl start systemd-networkd
	rm -f /etc/resolv.conf
	ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
	mkdir -p /etc/systemd/network
	cat <<-EOF2 > /etc/systemd/network/80-container-host0.network
		# -wvh- copied from later systemd versions
		[Match]
		Virtualization=container
		Name=host0
	
		[Network]
		DHCP=yes
		LinkLocalAddressing=yes
		LLDP=yes
		EmitLLDP=customer-bridge
	
		[DHCP]
		UseTimezone=yes
	EOF2

	adduser -m ${SUDOER}
	echo -ne "${PASSWD:-secret}\n${PASSWD:-secret}\n" | passwd ${SUDOER}
	if [ -n "\${PUBKEY}" ]; then
		mkdir -p /home/${SUDOER}/.ssh
		chmod 700 /home/${SUDOER}/.ssh
		cat <<< \${PUBKEY} > /home/${SUDOER}/.ssh/authorized_keys
		chown -R ${SUDOER}:${SUDOER} /home/${SUDOER}/.ssh
	fi
	cat /home/${SUDOER}/.ssh/authorized_keys
	cat <<-EOF2 >/etc/sudoers.d/10-provisioning-users
		# -wvh- machine provisioning account
		${SUDOER} ALL=(ALL) NOPASSWD:ALL
	EOF2
EOF

# how to get VM UIDs:
# stat -c '%u' ${TARGET}/root
# find ${TARGET}/root -maxdepth 0 -printf '%u\n'


echo "$0: bootstrapping ${VMNAME}" >&2

systemd-nspawn -n -UD ${TARGET} sh /root/bootstrap.sh

if [ -e /var/lib/machines.raw ]; then
	echo "$0: checking if we need to mount machine storage file system to /var/lib/machines" >&2
	mountpoint -q /var/lib/machines || mount /var/lib/machines.raw /var/lib/machines
fi

if [ ! -e /var/lib/machines ]; then
	echo "$0: warning: machine storage doesn't exist or isn't mounted; not creating symlink to container directory" >&2
fi

if [ -e /var/lib/machines/${VMNAME} ]; then
	echo "$0: warning: symlink to container exists already in /var/lib/machines" >&2
else
	ln -s ${TARGET} /var/lib/machines/${VMNAME}
fi

echo "$0: booting ${VMNAME}" >&2

# Note: The build-in DHCPServer in systemd doesn't forward host systemd DNS servers if
#       they are not statically defined in .network files or if it doesn't manage DHCP itself.
#       You will end up with fallback resolv.conf name servers (8.8.8.8 etc).

# start virtual machine with automatic network bridge
systemd-nspawn -bUD ${TARGET} --network-zone=machines -M ${VMNAME}

cat <<-EOM >&2
	$0: done.

	You can:
	
	... restart the virtual machine:
	
	    systemd-nspawn -bUD ${TARGET} --network-zone=machines

	... bind-mount a directory inside the VM (read-only, owned by nobody):
	
	    systemd-nspawn -bUD ${TARGET} --network-zone=machines --bind-ro=/path/to/folder:/mnt

	... ssh to link-local if you provided an SSH key and have "mymachines" in /etc/nsswitch.conf:

	    ssh ${SUDOER}@${VMNAME}

	... get a shell with machinectl (not on CentOS VM clients yet):

	    machinectl shell ${VMNAME}

	... log in with machinectl:

	    machinectl login ${VMNAME}

	Note: If you want to log in as root with \`machinectl login\`, add pts/0 to /etc/securetty;
	      the default configuration for CentOS doesn't allow root login.

	Next steps:
	- update the system:
	  yum update
	- install rpmbuild:
	  yum -y install rpm-build
	- install ansible:
	  yum -y install epel-release ansible git
EOM

# That's all folks!