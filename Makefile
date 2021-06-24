include ./.env
export


OS_IMG_NAME=$(shell date "+%Y-%m-%d")_video_maker.img
BASE_OS_IMG_NAME:= base-${OS_IMG_NAME}
NET_CONF :=./os_stub/etc/netctl/spi-net

.PHONY: base_os custom_os device_tree all
all: custom_os

base_os: ${BASE_OS_IMG_NAME}
custom_os: ${OS_IMG_NAME}.gz
net_conf: ${NET_CONF}



${BASE_OS_IMG_NAME}: utils/make_base_os.sh
	@set +a
	@bash $< || (rm -f tmp-${OS_IMG_NAME}; echo "Failed to make base image!"; exit 1)
	@echo "Made base image $@ !"
	@set -a

${OS_IMG_NAME}.gz: utils/emulate_arm.sh  base-${OS_IMG_NAME} ${NET_CONF}
	@set +a

	@bash $<  || (rm -f tmp-${OS_IMG_NAME};  echo "Failed to make final image!"; exit 1)
	@echo "Made final image ${OS_IMG_NAME}! Compressing to $@"
	@gzip ${OS_IMG_NAME} -f
	@set -a

clean:
	rm tmp-*.img -f ${NET_CONF}
	losetup --detach-all

cleanall: clean
	rm base-*.img spi-*.img  -f


# export $(grep -v '^#' /etc/environment | xargs -d '\r\n');
# pip install  --no-dependencies--force-reinstall --upgrade /opt/sticky_pi/sticky_pi_device.tar.gz
