# 0014. Regarder YouTube et Twitch dans notre OS, Netflix et Canal+ sous Android

- Statut : proposée
- Date : 2026-11-03

## Contexte

Le 2026-11-03, Marius a classé les usages : **YouTube, Twitch, Netflix et Canal+ d'abord**, puis Cast et IPTV. Netflix et Canal+ exigent Widevine ; notre OS n'aura que le niveau L3 et ne contournera jamais les DRM (ADR 0003). YouTube et Twitch n'exigent pas de DRM pour leurs contenus gratuits. Le décodage est logiciel et vise le 1080p (ADR 0002).

## Options envisagées

1. **YouTube** :
   - a. Interface TV officielle `youtube.com/tv` dans un Chromium en mode kiosque : interface « 10 pieds » faite pour la croix, compte Google, et **« Regarder sur la TV » depuis l'app YouTube du S25** par code d'association. Inconvénients : Chromium est lourd, et il faut forcer le H.264 (le VP9/AV1 1080p en logiciel est limite sur 4 × A55).
   - b. Client natif Flutter sur une API non officielle (Invidious, yt-dlp) : léger, mais casse souvent et sans compte ni envoi depuis le téléphone.
2. **Twitch** :
   - a. Écran natif Flutter : liste des chaînes suivies par l'API officielle Helix, lecture du flux HLS dans notre lecteur (ADR 0010).
   - b. Site twitch.tv dans Chromium : pas pensé pour une télécommande.
3. **Netflix et Canal+** :
   - a. Applications de l'**Android d'origine**, atteintes par un bouton « redémarrer sous Android » (ADR 0003). La box n'étant pas certifiée, la qualité sera souvent SD/720p et l'installation de Netflix peut être refusée : à vérifier dès la réception.
   - b. Chromium + Widevine L3 dans notre OS : 720p au mieux, Canal+ refuse souvent le L3. Reste en extra (phase 7).

## Décision

YouTube par `youtube.com/tv` dans Chromium kiosque (1a), Twitch en écran natif (2a), Netflix et Canal+ sous Android (3a). Le bouton « redémarrer sous Android » et le Chromium kiosque (sans Widevine) avancent en phase 4.

## Conséquences

- Dès la réception de la box, avant tout travail sur Linux, on vérifie sous Android que Netflix, Canal+, YouTube et Twitch s'installent et à quelle qualité ils jouent. C'est la solution du premier jour.
- L'association YouTube depuis le téléphone couvre l'essentiel du « Cast » demandé pour YouTube. Le vrai Google Cast reste impossible (ADR 0003).
- Revenir au retour vers Android peut demander d'écrire une variable d'environnement u-boot sur l'eMMC : accord explicite de Marius requis (issue dédiée).
- On reviendra sur 1a si Chromium est trop lent sur la box (spike en phase 4) : repli 1b.
