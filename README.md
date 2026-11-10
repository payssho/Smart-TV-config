# Smart-TV-config

Notre propre OS de télé, 100 % modifiable, sur une box Android d'occasion (Amlogic S905X3, 2 Go visés, 4 Go en repli) : Linux mainline construit avec Buildroot, interface Flutter plein écran via flutter-pi, pilotage à la télécommande de la télé (HDMI-CEC) et à l'infrarouge. La box sert aussi de hub domotique pour l'app [Home device manager](https://github.com/payssho/Home-device-manager).

L'Android d'origine reste sur l'eMMC : on redémarre dessus pour Netflix et Canal+. Notre OS démarre depuis la carte SD. L'eMMC est sauvegardée avant toute écriture (ADR 0018).

## État actuel

**Phase 0 terminée, phase 2 en cours sans la box.** Le dépôt contient la documentation, les décisions (ADR), la CI, un script de diagnostic pour la box, l'app Flutter TV (`ui/`) avec sa prévisu web et un banc mémoire 2 Go / 4 Go. La box n'est pas encore achetée : tout s'avance sur une copie émulée en 2 Go et 4 Go, et se vérifie sur la vraie télé à la réception.

| Phase | Livrable | Box physique nécessaire |
|---|---|---|
| 0. Cadrage | Dépôt structuré, ADR, CI | Non |
| 1. Matériel | Rapport de ce qui marche sous Armbian | Oui |
| 2. Interface | Flutter plein écran pilotable à la télécommande | Non pour avancer (copie émulée), oui pour la démo |
| 3. Image maison | Image Buildroot qui démarre sur l'interface à chaque fois, puis vite | Non pour avancer (QEMU 2 Go / 4 Go), oui pour la démo |
| 4. Usages | Lecteur vidéo, premiers services, retour à Android, CEC actif | Non pour avancer, oui pour la démo |
| 5. Hub | Lumières et télécommande dans l'app du téléphone | Non pour avancer, oui pour la démo |
| 6. Solidité | Lecture seule, mises à jour A/B, garde-fous de stockage | Non pour avancer, oui pour la démo |
| 7. Extras | Chromium + Widevine L3, recopie d'écran | Oui |

Détail et critères de fin : [docs/roadmap.md](docs/roadmap.md). Suivi réel : les [milestones GitHub](https://github.com/payssho/Smart-TV-config/milestones).

## Documentation

- [Vision et périmètre](docs/vision.md)
- [Architecture](docs/architecture.md)
- [Décisions (ADR)](docs/adr/README.md)
- [Plan de réalisation](docs/plan-de-realisation.md)
- [Journal des phases](docs/journal.md)
- [Checklist de validation du matériel (phase 1)](docs/materiel/checklist-phase-1.md)

## Lancer

L'app Flutter : `cd ui && flutter test`, prévisu web avec `scripts/previsu/construire.sh`. Pour vérifier localement ce que fait la CI :

```sh
scripts/ci/verifier.sh
```
