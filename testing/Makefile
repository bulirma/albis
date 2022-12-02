IMG_SIZE = 32G
SHARED_DIR = /usr/share/nginx/html/
ISO_FILE = artix.iso

albis:
	ln -s "$$( dirname $$PWD )" albis

artix_box.cow:
	qemu-img create -f qcow2 testing/artix_box.cow $(IMG_SIZE)

install: artix_box.cow artix.iso
	qemu-system-x86_64 -enable-kvm -m 4G -boot order=d -cdrom $(ISO_FILE) -drive file=artix_box.cow,format=qcow2

run: artix_box.cow
	qemu-system-x86_64 -enable-kvm -m 4G -boot order=d testing/artix_box.cow

update: albis
	rsync -urv albis/albis.sh $(SHARED_DIR)
	rsync -urv albis/albis_modules $(SHARED_DIR)
	rsync -urv albis/download.sh $(SHARED_DIR)
	rsync -urv albis/launch.sh $(SHARED_DIR)

.PHONY: install run update
