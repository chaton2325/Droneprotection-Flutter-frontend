# Drone Protection - Application mobile (Flutter)

Application mobile du systeme anti-bandit **Drone Protection** : un bouton d'urgence qui,
une fois maintenu, declenche une alerte diffusee en temps reel a tous les repondants inscrits
sur l'[interface web](../Droneprotection-Web-Interface), avec envoi automatique de la position.

## Fonctionnement

1. Connexion / inscription (role `victim` pour declencher des alertes, ou `both` pour aussi
   pouvoir en recevoir).
2. Sur l'onglet **Urgence**, l'utilisateur **maintient** le bouton SOS (~1.6s) pour eviter tout
   declenchement accidentel.
3. La position GPS est recuperee et une alerte est creee cote backend
   ([Droneprotection-Backend](../Droneprotection-Backend)).
4. Tant que l'alerte est active (`pending` ou `accepted`), la position est renvoyee
   automatiquement toutes les 6 secondes.
5. Des qu'un repondant accepte l'alerte, l'ecran passe en "Intervention en cours" avec son nom
   et son telephone (evenement Socket.IO recu en direct).
6. L'utilisateur peut annuler l'alerte ou la marquer comme resolue ("Je suis en securite").
7. L'onglet **Historique** liste les alertes precedentes et leur statut final.

> Limitation MVP : la position n'est envoyee que lorsque l'ecran d'urgence est actif au premier
> plan (pas de service de localisation en arriere-plan). Une evolution possible serait d'ajouter
> `flutter_background_geolocation` ou un `WorkManager`/`BGTaskScheduler` pour un suivi en tache
> de fond.

## Configuration du backend

Par defaut, l'app cible le backend de production :

```
API_BASE_URL = https://antitheft.mirhosty.com/api
SOCKET_URL   = https://antitheft.mirhosty.com
```

- **Backend de production** : valeurs par defaut, rien a changer.
- **Backend local** (dev) : surcharger via `--dart-define` :
  - **Emulateur Android** : `--dart-define=API_BASE_URL=http://10.0.2.2:4000/api --dart-define=SOCKET_URL=http://10.0.2.2:4000`
  - **Simulateur iOS / Desktop / Web** : `--dart-define=API_BASE_URL=http://localhost:4000/api --dart-define=SOCKET_URL=http://localhost:4000`
  - **Appareil physique** (meme reseau Wi-Fi que votre machine) :
    ```bash
    flutter run \
      --dart-define=API_BASE_URL=http://<IP-LAN-DE-VOTRE-PC>:4000/api \
      --dart-define=SOCKET_URL=http://<IP-LAN-DE-VOTRE-PC>:4000
    ```

Voir `lib/config.dart`.

## Installation

```bash
flutter pub get
flutter run
```

Le [backend](../Droneprotection-Backend) doit tourner (`npm run dev`) avant de declencher une
alerte.

## Stack

- **Flutter** (Material 3, theme sombre coherent avec l'interface web)
- **provider** pour l'etat global (`AuthProvider`, `AlertProvider`)
- **http** pour l'API REST, **socket_io_client** pour le temps reel
- **geolocator** pour la geolocalisation, **shared_preferences** pour la session

## Structure

```
lib/
  app.dart, main.dart      Point d'entree + routage par etat d'authentification
  config.dart               URLs backend (surchargables via --dart-define)
  models/                   AppUser, EmergencyAlert
  services/                 ApiClient, AuthService, AlertService, SocketService, LocationService
  state/                    AuthProvider, AlertProvider (ChangeNotifier)
  screens/                  Login, Register, RootShell (onglets Urgence / Historique)
  widgets/                  SosButton (maintenir pour confirmer), AlertStatusCard, StatusPill
```
