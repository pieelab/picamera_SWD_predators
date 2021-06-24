set -e
SD=/dev/mmcblk0

grep 'Model.*Raspberry Pi' /proc/cpuinfo -c || (
  echo "Not booted in Raspberry pi"; exit 1
  )

echo "Making partition?"
(lsblk | grep $(basename ${SD})p3  -c) ||
(
echo "Making new partition"
fdisk $SD << EOF
n
p
3


t
3
c
w
EOF

partprobe $SD
mkfs.vfat ${SD}p3
sync
fatlabel  ${SD}p3 VIDEOS
sync
echo "New partition labelled"
)

echo "Mounting partition?"


echo "LABEL=VIDEOS  /videos   vfat    defaults        0       0" > /etc/fstab &&
mkdir -p /videos  &&
mount -a &&
sync &&
echo "Partition mounted"


echo "Setting dummy time"
systemctl stop systemd-timesyncd.service
timedatectl set-time "2000-01-01 00:00:00"

echo "Disabling  first boot script"
# make the image read only if defined in env file

echo "Making read-only FS"
(mount ${SD}p1 /boot
cp /boot/cmdline.txt /boot/cmdline.txt-backup
sed s/rw/ro/g /boot/cmdline.txt-backup > /boot/cmdline.txt

cp /etc/fstab /etc/fstab-backup
cat /etc/fstab-backup > /etc/fstab
echo 'tmpfs   /var/log    tmpfs   nodev,nosuid    0   0' >> /etc/fstab
echo 'tmpfs   /var/tmp    tmpfs   nodev,nosuid    0   0' >> /etc/fstab

cp /etc/systemd/journald.conf /etc/systemd/journald.conf-backup
cat /etc/systemd/journald.conf-backup > /etc/systemd/journald.conf
echo Storage="none" >> /etc/systemd/journald.conf



history -c -w) ||
umount ${SD}p1

systemctl disable first_boot.service  &&  echo "All good." && sync && reboot
reboot