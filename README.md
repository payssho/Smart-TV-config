# Smart-TV-config

Notre propre OS de télé, 100 % modifiable, sur une box Android à 30 € (Amlogic S905X3, 4/32 Go) : Linux mainline construit avec Buildroot, interface Flutter plein écran via flutter-pi, pilotage à la télécommande de la télé (HDMI-CEC) et à l'infrarouge. La box sert aussi de hub domotique pour l'app [Home device manager](https://github.com/payssho/Home-device-manager).

L'Android d'origine reste intact sur l'eMMC : on redémarre dessus pour Netflix et Canal+. Notre OS démarre depuis la carte SD.

## État actuel

**Phase 0, cadrage.** Le dépôt contient la documentation, les décisions (ADR), la CI et un script de diagnostic pour valider la box à sa réception. Pas encore d'image ni d'interface.

| Phase | Livrable | Box nécessaire |
|---|---|---|
| 0. Cadrage | Dépôt structuré, ADR, CI | Non |
| 1. Matériel | Rapport de ce qui marche sous Armbian | Oui |
| 2. Interface | Flutter plein écran pilotable à la télécommande | Oui |
| 3. Image maison | Image Buildroot qui démarre sur l'interface en < 15 s | Oui (QEMU avant) |
| 4. Usages | Lecteur vidéo, premiers services, CEC actif | Oui |
| 5. Hub | Domotique depuis la télé et le téléphone | Oui |
| 6. Solidité | Lecture seule, mises à jour A/B, retour à Android | Oui |
| 7. Extras | Chromium + Widevine L3, recopie d'écran | Oui |

Détail et critères de fin : [docs/roadmap.md](docs/roadmap.md). Suivi réel : les [milestones GitHub](https://github.com/payssho/Smart-TV-config/milestones).

## Documentation

- [Vision et périmètre](docs/vision.md)
- [Architecture](docs/architecture.md)
- [Décisions (ADR)](docs/adr/README.md)
- [Checklist de validation du matériel (phase 1)](docs/materiel/checklist-phase-1.md)

## Lancer

Rien à lancer pour l'instant. Pour vérifier localement ce que fait la CI :

```sh
scripts/ci/verifier.sh
```
