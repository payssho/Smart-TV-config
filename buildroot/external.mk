# Paquets propres à la télé maison (arbre BR2_EXTERNAL, ADR 0004).
include $(sort $(wildcard $(BR2_EXTERNAL_TELE_PATH)/package/*/*.mk))
