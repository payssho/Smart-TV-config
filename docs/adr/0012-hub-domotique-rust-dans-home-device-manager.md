# 0012. Faire tourner un hub domotique Rust sur la box, développé dans Home-device-manager

- Statut : acceptée
- Date : 2026-11-03

## Contexte

La box pilotera les lampes (iStrip+ en BLE, ampoules WiZ en UDP) et plus tard un ESP32 en MQTT. L'app Flutter du S25 et l'interface télé doivent lui parler. Les drivers existent déjà en Dart dans `payssho/Home-device-manager`. Rust confirmé par Marius le 2026-11-03.

## Options envisagées

1. **Service Rust** (tokio, `bluer` pour BlueZ, UDP WiZ, CEC, MQTT), **gRPC** (tonic / grpc-dart) avec découverte **mDNS** et streaming d'états, contrat Protobuf dans `Home-device-manager/proto/`.
2. Service Dart AOT qui reprend directement les drivers : un seul langage, écosystème BLE serveur plus pauvre.
3. Home Assistant : très complet mais lourd pour la box.

## Décision

Option 1. Le hub vit dans le monorepo `Home-device-manager` ; ce dépôt ne contient qu'un paquet Buildroot qui le compile et l'installe.

## Conséquences

- Ce dépôt ne définit pas le contrat Protobuf.
- Partage de code Dart (modèles, client gRPC, thème) par dépendance git vers des paquets de `Home-device-manager` quand ils existeront.
- L'app du S25 garde un mode BLE direct de secours quand le hub est éteint.
