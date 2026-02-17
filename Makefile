VERSION := 0.8.1

all:

version:
	echo $(VERSION)

build/ipxe/srv/tftp/ipxe:
	$(MAKE) -C ipxe
	mkdir -p build/ipxe/srv/tftp
	cp ipxe/bin/* build/ipxe/srv/tftp

ubuntu-pxe:
	mkdir -p os-bases/ubuntu/var/www/static/pxe/ubuntu-installer
	[ -f os-bases/ubuntu/var/www/static/pxe/ubuntu-installer/initrd ] || wget http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/initrd.gz -O os-bases/ubuntu/var/www/static/pxe/ubuntu-installer/initrd
	[ -f os-bases/ubuntu/var/www/static/pxe/ubuntu-installer/vmlinuz ] || wget http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/linux -O os-bases/ubuntu/var/www/static/pxe/ubuntu-installer/vmlinuz
	touch ubuntu-pxe

centos-pxe:
	mkdir -p os-bases/centos/var/www/static/pxe/centos-installer
	[ -f os-bases/centos/var/www/static/pxe/centos-installer/6.initrd ] || wget https://vault.centos.org/6.10/os/x86_64/images/pxeboot/initrd.img -O os-bases/centos/var/www/static/pxe/centos-installer/6.initrd
	[ -f os-bases/centos/var/www/static/pxe/centos-installer/6.vmlinuz ] || wget https://vault.centos.org/6.10/os/x86_64/images/pxeboot/vmlinuz -O os-bases/centos/var/www/static/pxe/centos-installer/6.vmlinuz
	[ -f os-bases/centos/var/www/static/pxe/centos-installer/7.initrd ] || wget http://mirror.centos.org/centos/7/os/x86_64/images/pxeboot/initrd.img -O os-bases/centos/var/www/static/pxe/centos-installer/7.initrd
	[ -f os-bases/centos/var/www/static/pxe/centos-installer/7.vmlinuz ] || wget http://mirror.centos.org/centos/7/os/x86_64/images/pxeboot/vmlinuz -O os-bases/centos/var/www/static/pxe/centos-installer/7.vmlinuz
	touch centos-pxe

esx-pxe:
	mkdir -p vmware/vmware/var/www/static/pxe/vmware/esx-installer
	if [ -f VMware-VMvisor-Installer-*.iso ]; then ./esxExtractISO VMware-VMvisor-Installer-*.iso vmware/vmware/var/www/static/pxe/vmware/esx-installer; fi
	touch esx-pxe

vcenter-ova:
	mkdir -p vmware/vmware/var/www/static/pxe/vmware
	if [ -f VMware-VCSA-*.iso ]; then \
	FILE_NAME=$$( xorriso -osirrox on -indev VMware-VCSA-*.iso -lsl vcsa | grep ova | awk '{print $$9}' | tr -d \' ); \
	xorriso -osirrox on -indev VMware-VCSA-*.iso -extract_single vcsa/$$FILE_NAME vmware/vmware/var/www/static/pxe/vmware/vcenter.ova 2> /dev/null; \
	fi
	touch vcenter-ova

clean:
	$(MAKE) -C ipxe clean
	$(RM) build/ipxe/srv/tftp
	$(RM) -r build
	$(RM) *.respkg
	$(RM) ubuntu-pxe
	$(RM) centos-pxe
	$(RM) esx-pxe
	$(RM) vcenter-ova
	$(RM) respkg

dist-clean: clean
	$(MAKE) -C ipxe dist-clean
	$(RM) -r os-bases/ubuntu/var
	$(RM) -r os-bases/centos/var
	$(RM) -r vmware/vmware/var

.PHONY:: all version clean dist-clean

oldvcenter:
	patch -p0 < vcenter-pre67.patch

newvcenter:
	patch -p0 -R < vcenter-pre67.patch

.PHONY:: oldvcenter newvcenter

respkg-blueprints:
	echo ubuntu-focal-base

respkg-requires:
	echo respkg fakeroot build-essential liblzma-dev xorriso

# Old stuff, disabled: centos-pxe esx-pxe vcenter-ova
respkg: ubuntu-pxe  build/ipxe/srv/tftp/ipxe
	cd os-bases && fakeroot respkg -b ../contractor-os-base_$(VERSION).respkg       -n contractor-os-base      -e $(VERSION) -c "Contractor - OS Base"               -t load_os_base.sh -d os_base
	cd os-bases && fakeroot respkg -b ../contractor-ubuntu-base_$(VERSION).respkg   -n contractor-ubuntu-base  -e $(VERSION) -c "Contractor - Ubuntu Base"           -t load_ubuntu.sh  -d ubuntu  -s contractor-os-base
#	cd os-bases && fakeroot respkg -b ../contractor-centos-base_$(VERSION).respkg   -n contractor-centos-base  -e $(VERSION) -c "Contractor - CentOS Base"           -t load_centos.sh  -d centos  -s contractor-os-base
	cd utility  && fakeroot respkg -b ../contractor-utility_$(VERSION).respkg       -n contractor-utility      -e $(VERSION) -c "Contractor - Utility"               -t load_utility.sh -d utility -s ubuntu
#	cd vmware   && fakeroot respkg -b ../contractor-vmware-base_$(VERSION).respkg   -n contractor-vmware-base  -e $(VERSION) -c "Contractor - VMware Base"           -t load_vmware.sh  -d vmware  -s contractor-os-base -s contractor-plugins-vcenter
	cd build    && fakeroot respkg -b ../contractor-ipxe_$(VERSION).respkg          -n contractor-ipxe         -e $(VERSION) -c "Contractor - iPXE - Netboot loader" -y -d ipxe

respkg-file:
	echo $(shell ls *.respkg)

.PHONY:: respkg-blueprints respkg-requires respkg respkg-file
