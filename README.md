# EjectionSeat 💺

Éjecteur de volumes montés pour macOS.

EjectionSeat vit discrètement dans la barre de menu et permet d'éjecter en un clic vos clés USB, disques externes, `.dmg` montés et autres volumes — sans passer par le Finder.

## Fonctionnalités

- **Éjection en un clic** : la liste des volumes montés apparaît dans le menu, cliquez pour éjecter.
- **"Eject All"** (`⌘E`) pour tout éjecter d'un coup.
- **Notifications** de succès ou d'échec, avec un bouton pour retenter l'éjection directement depuis la notification.
- **Icône native** (symbole système "eject"), fidèle au design de macOS et lisible en clair comme en sombre.
- Application légère, sans Dock icon (`LSUIElement`), qui ne fait qu'une chose.

## Prérequis

macOS 11 (Big Sur) ou plus récent.

## Installation

Ce fork n'a pas encore de release packagée ; pour l'instant, il faut compiler depuis les sources avec Xcode :

```bash
git clone https://github.com/illuminaten1/EjectionSeat.git
cd EjectionSeat
open EjectionSeat.xcodeproj
```
Puis `Product > Run` dans Xcode.

Des builds prêts à l'emploi du projet original sont disponibles [ici](https://github.com/pilotchute/EjectionSeat/releases/latest).

## Crédits

Ce dépôt est un fork du projet original [EjectionSeat](https://github.com/pilotchute/EjectionSeat) créé par **Alea Kootz**, avec quelques mises à jour (icône, notifications modernisées, cible macOS relevée).

Distribué sous licence [GPLv3](LICENSE).
