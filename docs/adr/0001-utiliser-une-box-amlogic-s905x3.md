# 0001. Utiliser une box Amlogic S905X3 4/32 Go, en Ethernet d'abord

- Statut : acceptée
- Date : 2026-11-03

## Contexte

Il faut une box bon marché capable de faire tourner un noyau Linux **mainline** (sans blobs du fabricant), un GPU avec pilote libre, et du 1080p. Marius refuse les Google TV et les clés Fire TV. Budget autour de 30 €.

## Options envisagées

1. **Amlogic S905X3** (X96 Max+, HK1 Box, H96 Max X3), 4 × A55 1,9 GHz, Mali-G31 (Panfrost), ~30 € : puce de box la plus récente en mainline, prise en charge par [ophub/amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian) (noyaux 6.12 et 6.18) et [LibreELEC](https://wiki.libreelec.tv/hardware/amlogic) (AMLGX).
2. Amlogic S905X4 (Tanix X4), 45 € : pas de mainline. Rejetée.
3. Clé Fire TV ou clé certifiée : fermée, refusée par Marius. Rejetée.
4. Raspberry Pi 5 : très bien supporté mais trop cher une fois équipé. Rejeté.
5. Rockchip RK3528, Allwinner H313 : support mainline trop faible. Rejetées.
6. Amlogic S905X (X96 Mini, MXQ Pro) : mieux supportée mais 1–2 Go de RAM. **Plan B.**

## Décision

Box S905X3 en **4 Go / 32 Go**, un des trois modèles cités. Réseau en **Ethernet** d'abord : la puce Wi‑Fi change d'un lot à l'autre et n'a pas toujours de pilote Linux.

## Conséquences

- Il faut identifier le modèle exact reçu, sa puce Wi‑Fi et le DTB qui marche (phase 1, checklist).
- Le Wi‑Fi est repoussé en phase 6, conditionné à la puce.
- Les options rejetées ne sont pas reproposées sans fait nouveau. On passe au plan B S905X si la box S905X3 reçue ne démarre pas correctement en mainline.
