# MisiCopy Remote (iOS)

Application iPhone compagnon qui se connecte à MisiCopy sur Mac via Wi-Fi local pour suivre la copie en temps réel.

## Mise en place du target Xcode

L'app vit dans le **même projet Xcode** que MisiCopy (Mac) pour réutiliser les modèles `SessionSnapshot.swift`, `PairingPayload.swift`, etc. Les étapes ci-dessous sont à faire **une seule fois** :

### 1. Créer le target iOS

1. Ouvre `MisiCopy.xcodeproj` dans Xcode.
2. **File → New → Target…**
3. Choisis **iOS → App**, clique **Next**.
4. Renseigne :
   - **Product Name** : `MisiCopyRemote`
   - **Team** : `Matthieu Misiraca (SM6L2XLUBA)`
   - **Organization Identifier** : `fr.misilab`
   - **Bundle Identifier** : `fr.misilab.MisiCopyRemote` (auto-généré)
   - **Interface** : `SwiftUI`
   - **Language** : `Swift`
   - **Storage** : `None`
5. Clique **Finish**. Quand Xcode demande s'il faut activer le scheme, dis **Activate**.

### 2. Supprimer les fichiers auto-générés

Xcode crée par défaut un `MisiCopyRemoteApp.swift` et un `ContentView.swift`. Supprime-les (sélectionne → Delete → **Move to Trash**) pour qu'ils ne rentrent pas en conflit avec ceux du dossier `MisiCopyRemote/`.

### 3. Ajouter mes fichiers au target

Glisse le dossier `MisiCopyRemote/` (depuis le Finder) dans l'arborescence Xcode, sous le groupe du target `MisiCopyRemote`. Dans la boîte de dialogue :
- **Coche** "Copy items if needed" : NON (les fichiers sont déjà à leur place)
- **Coche** "Create groups"
- **Add to targets** : `MisiCopyRemote` uniquement

### 4. Partager les modèles avec le Mac

Sélectionne ces 2 fichiers du target Mac et coche aussi `MisiCopyRemote` dans **Target Membership** (panneau de droite, File Inspector) :

- `MisiCopy/MisiCopy/Models/SessionSnapshot.swift`
- `MisiCopy/MisiCopy/Models/PairingPayload.swift`

Comme ça les types sont compilés dans les deux apps sans duplication.

### 5. Remplacer le Info.plist

Le target iOS doit utiliser le `Info.plist` que j'ai créé (pour les permissions Réseau local + Caméra + Bonjour). Dans les Build Settings du target `MisiCopyRemote`, change `INFOPLIST_FILE` vers `MisiCopyRemote/Info.plist`.

### 6. Capabilities

Dans **Signing & Capabilities** du target `MisiCopyRemote` : rien à ajouter pour le MVP local-only. (CloudKit viendra plus tard.)

### 7. Build & Run

Sélectionne le scheme `MisiCopyRemote`, choisis ton iPhone (ou un simulateur iOS 17+), et lance ⌘R.

## Test du flux complet

1. Sur le **Mac** : lance MisiCopy → Réglages → iPhone → active le toggle. Le QR apparaît.
2. Sur **l'iPhone** : lance MisiCopy Remote → autorise la caméra → scanne le QR du Mac.
3. Le Mac doit apparaître dans la liste, l'iPhone se connecte automatiquement en Wi-Fi.
4. Lance une copie sur le Mac → tu vois la progression LIVE sur ton iPhone.
5. Le bouton **Pause** / **Reprendre** / **Annuler** envoie l'ordre au Mac.

## Architecture

- `Services/LocalDiscovery.swift` : `NWBrowser` qui découvre les Mac MisiCopy en Bonjour `_misicopy._tcp`
- `Services/LocalChannelClient.swift` : client WebSocket + auth HMAC-SHA256
- `Services/RemoteSession.swift` : orchestre la connexion + notifs locales fin de copie
- `Services/PairedMacStore.swift` : persiste les Mac appairés (UserDefaults) + secret Keychain
- `Views/PairingView.swift` : scanner QR (AVFoundation)
- `Views/DashboardView.swift` : écran live avec progress ring + stats + contrôles
- `Views/MacListView.swift` : bascule entre Mac appairés
