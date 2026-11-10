# 0003. Garder Android sur l'eMMC en double démarrage, sans jamais contourner les DRM

- Statut : acceptée
- Date : 2026-11-03

> Le 2026-11-10, l'ADR 0018 remplace la règle sur l'eMMC : écriture permise quand elle sert le projet, après une sauvegarde complète. Le double démarrage et l'interdiction de contourner les DRM tiennent.

## Contexte

Netflix, Canal+ et Disney+ exigent Widevine. Un OS maison n'a que le niveau **L3** (logiciel), soit ~720p au mieux, et certains services le refusent. Google Cast exige un récepteur certifié. L'Android d'origine de la box fait tourner ces services (souvent en SD/720p, la box n'étant pas certifiée).

## Options envisagées

1. **Double démarrage** : Android d'origine intact sur l'eMMC, notre OS sur la carte SD, bascule par redémarrage.
2. Remplacer Android par notre OS sur l'eMMC : on perd les services officiels. Rejetée.
3. Contourner les DRM (patch, clé extraite, faux certificat) : illégal et hors de question. Rejetée définitivement.

## Décision

Double démarrage : **notre OS sur la SD (ou USB), Android intact sur l'eMMC**. On n'écrit jamais sur l'eMMC sans l'accord explicite de Marius. Aucun contournement de DRM. Plus tard, Chromium avec Widevine L3 récupéré légalement (comme LibreELEC ou Raspberry Pi OS).

## Conséquences

- Le bouton « redémarrer sous Android » (phase 6) doit trouver un mécanisme qui n'écrit pas sur l'eMMC, ou obtenir l'accord de Marius.
- Pas de Google Cast. Une recopie d'écran (Miracast) ou un protocole maison depuis le S25 reste possible pour YouTube, photos et vidéos perso ; Netflix et Canal+ y afficheront un écran noir, c'est normal.
