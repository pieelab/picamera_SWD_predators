set -e

rm /etc/localtime -f
ln -s /usr/share/zoneinfo/UTC /etc/localtime

pacman-key --init
pacman-key --populate
pacman -Syy
pacman -Syu --noconfirm
pacman -S python-pip rng-tools dosfstools devtools libjpeg uboot-tools base-devel parted --needed --noconfirm
pacman -Scc --noconfirm

pip install --upgrade pip --no-cache-dir
export READTHEDOCS=True; pip install picamera  --no-cache-dir # hack to circumvent virtual pi issue

netctl enable spi-net || echo "" # ignore error here
systemctl enable netctl-auto@wlan0.service
systemctl enable sshd.service
systemctl enable first_boot.service

#todo
systemctl enable take_video.service

date
history -c -w
