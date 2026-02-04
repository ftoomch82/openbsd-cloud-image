#!/usr/bin/make -f

include makefile.config
-include makefile.config.local

.PHONY: clean install_debian_packages purge purge_bad_release therest

SHELL:=/bin/bash -O globstar

default: therest

signify_keys: $(signify_keys)

$(signify_keys):
	[[ -d $(@D) ]] || su -c 'mkdir --parents $(@D) && chown $(USER) $(@D) && chmod 0775 $(@D)'
	scp $(mytrustedobsdhost):/etc/signify/$(@F) $@

install_debian_packages:
	su - -c 'apt install --assume-yes --no-install-recommends qemu-system-x86 qemu-utils ovmf; apt install --assume-yes signify-openbsd'

images/$(myqcowname): export http_proxy=$(myhttpproxy)
images/$(myqcowname): export https_proxy=$(myhttpsproxy)
images/$(myqcowname):
	echo http_proxy is $$http_proxy
	echo https_proxy is $$https_proxy
	./build_openbsd_qcow2.sh \
	  --build \
	  --efiboot \
	  --disklabel "custom/disklabel-$(myflavour)" \
	  --image-file "$(myqcowname)" \
	  --reuse-proxy \
	  --sets '-g* -c* -xfont* -xserv* -xshare*' \
	  --size 10 \
	  --timezone UTC

$(mypubdir)$(myqcowname): images/$(myqcowname)
	cp -v "$<" "$@"

$(mypubdir)$(myqcowname).asc: $(mypubdir)$(myqcowname)
	gpg --detach-sign --armor $@ $<
	
therest: $(mypubdir)$(myqcowname) $(mypubdir)$(myqcowname).asc
	ssh installer@rollor "mkdir -p $(myrepodir)"
	scp "$(mypubdir)$(myqcowname)"* installer@rollor:"$(myrepodir)"
	ssh installer@rollor "gpg --verify ~/$(myrepodir)$(myqcowname).asc"

/etc/sudoers.d/build_openbsd_qcow2:
	su - -c 'echo "ben ALL = (root) NOPASSWD: /usr/bin/python3 -m http.server --directory mirror --bind 127.0.0.1 80" > $@'

clean:
	-$(RM) images/$(myqcowname) images/$(myqcowname)_compressed

purge:
	-$(RM) --recursive mirror tftp

purge_bad_release:
	-$(RM) $(mypubdir)$(myqcowname) $(mypubdir)$(myqcowname).asc
