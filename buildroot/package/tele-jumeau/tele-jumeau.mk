################################################################################
#
# tele-jumeau
#
################################################################################

TELE_JUMEAU_VERSION = local
TELE_JUMEAU_SITE = $(BR2_EXTERNAL_TELE_PATH)/../scripts/jumeau/invite
TELE_JUMEAU_SITE_METHOD = local
TELE_JUMEAU_LICENSE = PROPRIETARY

define TELE_JUMEAU_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/tele-jumeau \
		$(TARGET_DIR)/usr/lib/tele/jumeau/tele-jumeau
	$(INSTALL) -D -m 0644 $(@D)/scenario.py \
		$(TARGET_DIR)/usr/lib/tele/jumeau/scenario.py
endef

define TELE_JUMEAU_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(@D)/tele-jumeau.service \
		$(TARGET_DIR)/usr/lib/systemd/system/tele-jumeau.service
	$(INSTALL) -D -m 0644 $(TELE_JUMEAU_PKGDIR)/60-tele-jumeau.preset \
		$(TARGET_DIR)/usr/lib/systemd/system-preset/60-tele-jumeau.preset
endef

$(eval $(generic-package))
