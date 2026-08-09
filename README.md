# EjectionSeat 💺

Éjecteur de volumes montés pour macOS.

EjectionSeat vit discrètement dans la barre de menu et permet d'éjecter en un clic vos clés USB, disques externes, `.dmg` montés et autres volumes — sans passer par le Finder.

## Fonctionnalités

- **Éjection en un clic** : la liste des volumes montés apparaît directement dans le menu principal (plus de sous-menu), cliquez pour éjecter.
- **"Eject All"** (`⌘E`) pour tout éjecter d'un coup, avec une nouvelle tentative automatique et silencieuse en cas d'échec transitoire.
- **Notifications** de succès ou d'échec — le message d'erreur détaillé de macOS est affiché en cas de problème — avec un bouton pour retenter l'éjection directement depuis la notification.
- **Préférences** : possibilité de couper le son joué à l'éjection.
- **Lancement au démarrage** : activable directement depuis le menu (macOS 13 ou plus récent).
- **Icône native** (symbole système "eject"), fidèle au design de macOS et lisible en clair comme en sombre.
- Application légère, sans Dock icon (`LSUIElement`), qui ne fait qu'une chose.

## Prérequis

macOS 11 (Big Sur) ou plus récent. L'option "Lancement au démarrage" nécessite macOS 13 (Ventura) ou plus récent.

## Installation

Téléchargez la dernière version packagée depuis la page [Releases](https://github.com/illuminaten1/EjectionSeat/releases/latest) de ce dépôt, dézippez `EjectionSeat.app` et lancez-le. L'app n'étant pas notariée, il faudra faire un clic droit > Ouvrir la première fois (Gatekeeper).

Vous pouvez aussi compiler depuis les sources avec Xcode :

```bash
git clone https://github.com/illuminaten1/EjectionSeat.git
cd EjectionSeat
open EjectionSeat.xcodeproj
```
Puis `Product > Run` dans Xcode.

## Crédits

Ce dépôt est un fork du projet original [EjectionSeat](https://github.com/pilotchute/EjectionSeat) créé par **Alea Kootz**, avec quelques mises à jour (icône, notifications modernisées, menu simplifié, préférences, lancement au démarrage, cible macOS relevée).

Distribué sous licence [GPLv3](LICENSE).
