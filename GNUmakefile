# Makefile for building, signing, publishing, and scp'ing OpenBSD cloud-init images.

include GNUmakefile.config
-include GNUmakefile.config.local

SHELL:=/bin/bash

.DELETE_ON_ERROR:

# ----------------------------------------------------------------------
# Derived image path lists
# ----------------------------------------------------------------------

# Relative image paths, without myimagedir/mypubdir/mysoftwarerepo.
#
# Example:
#
#   OpenBSD/7.8/amd64/openbsd-efi-2026-06-15.qcow2

relimages := $(foreach version,$(myversions), \
              $(foreach arch,$(myarchs), \
              $(foreach flavour,$(myflavours), \
              OpenBSD/$(version)/$(arch)/openbsd-$(flavour)-$(mydate).qcow2)))

# Relative signature paths.
#
# Example:
#
#   OpenBSD/7.8/amd64/openbsd-efi-2026-06-15.qcow2.asc

relascs := $(addsuffix .asc,$(relimages))

# Local build outputs:
#
#   images/OpenBSD/7.8/amd64/openbsd-efi-2026-06-15.qcow2

myimages := $(addprefix $(myimagedir),$(relimages))

# Local signature outputs:
#
#   images/OpenBSD/7.8/amd64/openbsd-efi-2026-06-15.qcow2.asc

myascs := $(addprefix $(myimagedir),$(relascs))

# Local published image outputs:
#
#   /export/software/OpenBSD/7.8/amd64/openbsd-efi-2026-06-15.qcow2

mypubimages := $(addprefix $(mypubdir),$(relimages))

# Local published signature outputs:
#
#   /export/software/OpenBSD/7.8/amd64/openbsd-efi-2026-06-15.qcow2.asc

mypubascs := $(addprefix $(mypubdir),$(relascs))

# Remote repository image paths, relative to the remote user's home unless
# mysoftwarerepo is absolute.
#
#   software_repository/OpenBSD/7.8/amd64/openbsd-efi-2026-06-15.qcow2

myrepoimages := $(addprefix $(mysoftwarerepo),$(relimages))

# Remote repository signature paths.
#
#   software_repository/OpenBSD/7.8/amd64/openbsd-efi-2026-06-15.qcow2.asc

myrepoascs := $(addprefix $(mysoftwarerepo),$(relascs))

# Local stamp files used to track successful scp operations.
#
# Make cannot reliably use the remote destination file as a normal target,
# so these stamp files represent "this image and its signature were copied remotely".

myscpstamps := $(addprefix .sent/,$(relimages))

# ----------------------------------------------------------------------
# Public targets
# ----------------------------------------------------------------------

.PHONY: all images install_debian_packages signatures signed publish scp print clean

all: images

signify_keys: $(signify_keys)

$(signify_keys):
	[[ -d $(@D) ]] || su -c 'mkdir --parents $(@D) && chown $(USER) $(@D) && chmod 0775 $(@D)'
	scp $(mytrustedobsdhost):/etc/signify/$(@F) $@

install_debian_packages:
	su - -c 'apt install --assume-yes --no-install-recommends qemu-system-x86 qemu-utils ovmf; apt install --assume-yes signify-openbsd'

/etc/sudoers.d/build_openbsd_qcow2:
	su - -c 'echo "$(USER) ALL = (root) NOPASSWD: /usr/bin/python3 -m http.server --directory mirror --bind 127.0.0.1 80" > $@'

images: $(myimages)

signatures: $(myascs)

signed: images signatures

publish: $(mypubimages) $(mypubascs)

scp: $(myscpstamps)

print:
	@echo "mydate:"
	@printf '  %s\n' "$(mydate)"
	@echo
	@echo "myversions:"
	@printf '  %s\n' $(myversions)
	@echo
	@echo "myarchs:"
	@printf '  %s\n' $(myarchs)
	@echo
	@echo "myflavours:"
	@printf '  %s\n' $(myflavours)
	@echo
	@echo "relimages:"
	@printf '  %s\n' $(relimages)
	@echo
	@echo "relascs:"
	@printf '  %s\n' $(relascs)
	@echo
	@echo "myimages:"
	@printf '  %s\n' $(myimages)
	@echo
	@echo "myascs:"
	@printf '  %s\n' $(myascs)
	@echo
	@echo "mypubimages:"
	@printf '  %s\n' $(mypubimages)
	@echo
	@echo "mypubascs:"
	@printf '  %s\n' $(mypubascs)
	@echo
	@echo "myrepoimages:"
	@printf '  %s\n' $(myrepoimages)
	@echo
	@echo "myrepoascs:"
	@printf '  %s\n' $(myrepoascs)
	@echo
	@echo "myscpstamps:"
	@printf '  %s\n' $(myscpstamps)
	@echo
	@echo "signify_keys:"
	@printf '  %s\n' $(signify_keys)
	@echo

# ----------------------------------------------------------------------
# Rule templates
# ----------------------------------------------------------------------

define IMAGE_RULE
# Requiring Internet access
ifdef HTTP_PROXY
$(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2:
	mkdir -p $$(@D)
	@echo "Building OpenBSD $(1) $(2) $(3) image: $$@"
	@set -o noglob
	./build_openbsd_qcow2.sh \
	  --build \
	  --disklabel custom/disklabel-$(3) \
	  --image-file $$(@:$(myimagedir)%=%) \
	  --reuse-proxy \
	  $$(image_args_$(3)) \
	  --size 10 \
	  --timezone UTC
else
$(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2:
	@echo 'Did you forget to enable your proxy to make "$$@?" Exiting.'
	exit 1
endif
endef

define SIGN_RULE
$(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2.asc: $(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2
	@echo "Signing $$< -> $$@"
	$(gpg) --armor --detach-sign --output $$@ $$<
endef

define PUB_IMAGE_RULE
$(mypubdir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2: $(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2
	mkdir -p $$(@D)
	cp -f $$< $$@
endef

define PUB_ASC_RULE
$(mypubdir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2.asc: $(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2.asc
	mkdir -p $$(@D)
	cp -f $$< $$@
endef

define SCP_RULE
.sent/OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2: \
  $(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2 \
  $(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2.asc
	ssh $(myremotehost) 'mkdir -p $(mysoftwarerepo)OpenBSD/$(1)/$(2)'
	scp \
	  $(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2 \
	  $(myimagedir)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2.asc \
	  $(myremotehost):$(mysoftwarerepo)OpenBSD/$(1)/$(2)/
	ssh $(myremotehost) 'gpg --verify $(mysoftwarerepo)OpenBSD/$(1)/$(2)/openbsd-$(3)-$(mydate).qcow2.asc'
	mkdir -p $$(@D)
	touch $$@
endef

# ----------------------------------------------------------------------
# Instantiate rules for every version/arch/flavour combination
# ----------------------------------------------------------------------

$(foreach version,$(myversions), \
  $(foreach arch,$(myarchs), \
    $(foreach flavour,$(myflavours), \
      $(eval $(call IMAGE_RULE,$(version),$(arch),$(flavour))) \
      $(eval $(call SIGN_RULE,$(version),$(arch),$(flavour))) \
      $(eval $(call PUB_IMAGE_RULE,$(version),$(arch),$(flavour))) \
      $(eval $(call PUB_ASC_RULE,$(version),$(arch),$(flavour))) \
      $(eval $(call SCP_RULE,$(version),$(arch),$(flavour))) \
    ) \
  ) \
)

# ----------------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------------

# Remove locally built images, local signatures, and scp stamp files.
clean:
	-$(RM) --recursive $(myimagedir)OpenBSD .sent

