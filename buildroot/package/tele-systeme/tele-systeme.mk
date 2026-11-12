################################################################################
#
# tele-systeme
#
################################################################################

# Les fichiers viennent du dépôt lui-même (systeme/), pas d'une archive :
# ce qui tourne dans l'image est exactement ce que la CI teste.
TELE_SYSTEME_VERSION = local
TELE_SYSTEME_SITE = $(BR2_EXTERNAL_TELE_PATH)/../systeme
TELE_SYSTEME_SITE_METHOD = local
TELE_SYSTEME_LICENSE = PROPRIETARY

define TELE_SYSTEME_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/usr/lib/tele/commun.sh \
		$(TARGET_DIR)/usr/lib/tele/commun.sh
	$(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/sbin \
		$(@D)/usr/sbin/tele-memoire \
		$(@D)/usr/sbin/tele-role \
		$(@D)/usr/sbin/tele-entretien
	$(INSTALL) -D -m 0644 $(@D)/etc/tele/memoire.conf \
		$(TARGET_DIR)/etc/tele/memoire.conf
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/var/log/tele $(TARGET_DIR)/data
endef

# Les unités sont activées par le préréglage (« systemctl preset-all » de
# Buildroot), pas par des liens faits à la main qu'il effacerait.
define TELE_SYSTEME_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system \
		$(@D)/etc/systemd/system/tele-memoire.service \
		$(@D)/etc/systemd/system/tele-entretien.service \
		$(@D)/etc/systemd/system/tele-entretien.timer
	$(INSTALL) -D -m 0644 $(TELE_SYSTEME_PKGDIR)/50-tele.preset \
		$(TARGET_DIR)/usr/lib/systemd/system-preset/50-tele.preset
endef

$(eval $(generic-package))
