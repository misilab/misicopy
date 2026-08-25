# MisiCopy

Manuel utilisateur · User manual · Manual de usuario · Version 1.12.0

---

# 🇫🇷 Français

## Présentation

MisiCopy est une application macOS qui copie vos rushs depuis vos cartes mémoire (SD, CFexpress, microSD) ou vos disques (SSD, HDD) vers une ou plusieurs destinations, en vérifiant qu'aucun bit n'est altéré pendant le transfert. C'est ce qu'on appelle une **copie checksumée**, le standard de l'industrie depuis 15 ans.

**Pourquoi en avoir besoin ?** Quand on copie un fichier avec le Finder, macOS ne vérifie pas que les octets écrits à destination correspondent à ceux lus depuis la source. Sur de la donnée critique comme vos rushs de tournage, une carte SD défectueuse, un câble USB en bout de course ou un cosmic ray peut corrompre silencieusement quelques octets. Vous ne le découvrirez qu'au montage, quand un plan plante. MisiCopy calcule une signature numérique (checksum) avant et après chaque copie : si elles ne matchent pas, vous le savez immédiatement.

**Pour qui ?** DIT (Digital Imaging Technician) sur plateau, vidéastes solo, photographes mariage, équipes documentaire — toute personne qui ne peut pas se permettre de perdre un fichier.

## Installation

1. Téléchargez **MisiCopy-1.0.dmg** depuis le lien envoyé par Payhip après votre achat
2. Double-cliquez sur le DMG pour le monter
3. Glissez l'icône **MisiCopy** dans le dossier **Applications** qui apparaît dans la même fenêtre
4. Éjectez le DMG (clic-droit → Éjecter)
5. Lancez MisiCopy depuis **Applications** ou en cherchant son nom dans Spotlight (⌘ Espace)

Au premier lancement, macOS peut afficher un dialogue de sécurité demandant si vous voulez vraiment ouvrir une app téléchargée depuis Internet. Cliquez **Ouvrir**. L'app étant signée et notarisée par Apple, c'est sans risque.

## Activer votre licence

À l'ouverture, MisiCopy démarre en **mode essai** : **7 jours** d'utilisation OU **25 transferts complets** (le premier des deux atteints arrête l'essai). Pendant cette période, vous avez accès à toutes les fonctionnalités sans aucune restriction.

Pour activer votre licence définitive :

1. Menu **MisiCopy → Réglages** (raccourci **⌘ ,**)
2. Cliquez sur l'onglet **Licence** à gauche
3. Dans le champ **Clé de licence**, collez la clé reçue par Payhip
4. Le champ **Email** est optionnel — il sert juste à afficher votre adresse comme étiquette
5. Cliquez **Activer**

La pastille verte **LICENCE** apparaît dans le coin haut-droit de la fenêtre principale. Votre clé est sauvegardée dans le **Keychain macOS**, ce qui signifie qu'elle survit à la désinstallation/réinstallation de l'app.

**Une licence couvre 2 ordinateurs.** Activez-la sur votre fixe ET votre MacBook plateau avec la même clé. Pour libérer un poste : Réglages → Licence → **Désactiver sur ce poste**.

## L'interface principale en détail

La fenêtre se divise en trois zones.

**Le bandeau du haut**
- Logo et nom de l'app
- Statut licence (essai avec compteur jours/transferts restants, ou LICENCE active, ou EXPIRÉ)
- Indicateur de langue avec bascule rapide

**La colonne de gauche (configuration)**
- Les quatre cartes de **mode de copie** (vérification simple, double vérification, copie rapide, vérification seule)
- Une rangée de 4 boutons rapides : **Surveillance**, **Auto-start**, **Auto eject**, **Doublons**
- La section **Sources** où vous ajoutez vos cartes et disques
- La section **Destinations** où vous ajoutez les dossiers cibles

**La colonne de droite (suivi en temps réel)**
- Quatre stats colorées : **Trouvés** (bleu), **Copiés** (indigo), **Vérifiés** (vert), **Erreurs** (orange)
- Le gros bouton **Lancer la copie sécurisée** avec sa barre de progression
- La **File d'attente** (visible uniquement si vous avez plusieurs jobs)
- Le **Journal d'activité** en bas, avec scrollbar pour relire l'historique de la session

## Les quatre modes de copie

### Copie + vérification (recommandé)

C'est le mode que vous utiliserez 90 % du temps. MisiCopy calcule le checksum du fichier source, le copie vers la destination, recalcule le checksum du fichier destination, et compare. Si les deux signatures sont identiques, le fichier est marqué **Vérifié**. C'est suffisant pour 99 % des cas d'usage professionnels.

### Copie + double vérification

Identique au mode précédent, **plus une seconde lecture du fichier source après la copie**. Cette deuxième lecture permet de détecter les cartes SD défectueuses qui renvoient des données différentes à chaque relecture (rare mais ça existe sur les vieilles cartes). À utiliser pour vos **archives long terme** ou quand vous avez un doute sur l'état d'une carte.

Coût : doublement du temps de lecture source (la copie reste à la même vitesse, c'est la phase vérification qui est plus longue).

### Copie rapide

**Aucune vérification.** MisiCopy copie les fichiers mais ne vérifie rien. Plus rapide, mais vous n'avez aucune garantie sur l'intégrité des fichiers à destination. À réserver à des copies de travail temporaires non critiques (par exemple : prévisualisation rapide d'une carte pour vérifier qu'elle contient bien les bons clips).

### Vérification seule (nouveau · 1.9.0)

**Ne copie rien.** MisiCopy calcule le checksum de chaque fichier source, puis celui de la copie **déjà présente** à destination, et compare. Il n'écrit **strictement rien** sur les disques — pas même de rapport. Si vous voulez une trace, exportez le rapport (MHL, CSV, journal) via le menu **Fichier** après la vérification.

Cas d'usage typiques :
- Vous avez copié une carte en **Copie rapide** sur un plateau pressé, et vous voulez vérifier l'intégrité le soir venu, tranquillement
- Un doute sur un disque de backup : re-vérifiez toute une journée de rushs sans re-copier
- Contrôle qualité avant d'effacer les cartes : la preuve que chaque octet à destination correspond à la source

Sélectionnez la carte source et le disque de destination : MisiCopy **retrouve la copie tout seul**, même si elle a été faite un autre jour, dans un autre dossier REEL ou avec des réglages différents (il explore toutes les dispositions plausibles — dates, caméras, REEL, avec ou sans dossier carte). Le bouton principal affiche alors **Lancer la vérification**. Un fichier manquant ou altéré à destination apparaît en erreur, avec le chemin complet recherché dans le journal.

## Les algorithmes de checksum

Au menu **Options → Algorithme** (ou dans **Réglages → Général**), six choix sont proposés.

- **xxHash3 (64-bit)** — défaut. L'algorithme le plus rapide sur Apple Silicon, devenu le standard de l'industrie depuis 2024. Signature 64 bits, suffisante pour détecter toute corruption accidentelle.
- **xxHash3 (128-bit)** — même algorithme mais signature 128 bits, deux fois plus longue. Légèrement plus lent. À utiliser si vous échangez vos rushs avec des outils tiers qui exigent ce format précis.
- **xxHash64** — la version précédente de xxHash. À utiliser uniquement pour compatibilité avec d'anciens MHL générés par ShotPut Pro version 2022 et avant.
- **MD5** — universellement compatible. Beaucoup plus lent (8 à 10 fois plus lent que xxHash3). À utiliser si votre studio impose MD5 dans la livraison.
- **SHA-1** — héritage, à éviter sauf demande explicite.
- **SHA-256** — algorithme cryptographique, le plus lent de la liste. Utile si vous avez des exigences réglementaires de signature (rarement le cas en production vidéo).

**Recommandation** : restez sur xxHash3 (64-bit) sauf demande explicite du client final.

## Ajouter une source

Une "source" est l'endroit d'où vous copiez : une carte SD, un disque externe, un dossier sur votre disque interne. Trois méthodes pour l'ajouter.

**Méthode 1 — Drag & drop** : ouvrez le Finder, naviguez vers votre carte ou votre dossier, glissez-le vers la zone **Source** de MisiCopy. La carte apparaît immédiatement dans la liste.

**Méthode 2 — Bouton + (Choisir)** : cliquez sur le bouton **+** à côté du titre SOURCE. Le sélecteur de fichier macOS s'ouvre. Naviguez vers votre carte (généralement dans `/Volumes/NOM_DE_LA_CARTE`) et cliquez **Sélectionner**.

**Méthode 3 — Bandeau d'auto-détection** : quand vous branchez une carte ou un disque externe, un bandeau orange « Carte détectée — NOM » apparaît automatiquement en haut de la section Source. Cliquez **Ajouter comme source** pour la prendre en compte, ou **Ignorer** si ce n'est pas la carte que vous voulez copier.

**Sources multiples** : vous pouvez ajouter autant de sources que vous voulez. MisiCopy les traitera l'une après l'autre, en regroupant les fichiers dans des sous-dossiers nommés d'après chaque source. Cas typique : multi-caméras où vous avez A-cam, B-cam et un enregistreur audio. Vous ajoutez les trois sources, MisiCopy copiera tout en organisant `bay1/A-cam/`, `bay1/B-cam/`, `bay1/sound/`.

## Ajouter des destinations

Une "destination" est un dossier cible où les fichiers seront copiés. Plusieurs destinations sont possibles — MisiCopy copie en parallèle vers chacune et vérifie chacune indépendamment.

Les méthodes sont identiques aux sources : drag & drop d'un dossier ou bouton +. Vous pouvez par exemple configurer :
- **Bay1** : votre disque de travail principal
- **Bay2** : votre backup sur un second disque
- **NAS** : un dossier réseau partagé avec le monteur

À la fin de la copie, le fichier source aura été copié vers les trois destinations ET vérifié sur les trois.

**Bon à savoir** : les volumes Time Machine sont automatiquement exclus de la détection. MisiCopy reconnaît leur structure interne (`.com.apple.timemachine.donotpresent`, `Backups.backupdb`) et ne les propose jamais comme source ou destination.

## Les destinations en cascade (nouveau · 1.10.0)

Le problème classique : vous copiez vers un SSD rapide ET un gros disque dur d'archive. Sans cascade, toute la copie avance à la vitesse du disque le plus lent, et la carte reste occupée pendant des heures.

**La solution** : cliquez le bouton **↳** sur la destination lente — elle passe en mode **CASCADE**. Elle ne sera plus copiée depuis la carte, mais **depuis la première destination directe**, une fois la copie principale vérifiée.

1. **Phase 1** — carte → destinations directes uniquement, à pleine vitesse
2. **La carte est libérée** dès la phase 1 vérifiée (et éjectée automatiquement si Auto eject est actif) — vous pouvez enchaîner la carte suivante
3. **Phase 2** — la première destination directe alimente les cascades, avec vérification checksum complète contre l'empreinte d'origine de la carte (la relecture re-contrôle même la copie principale au passage)

**Repères de vitesse** : à l'ajout d'une destination, MisiCopy mesure sa vitesse d'écriture (sonde d'environ 1 seconde, mémorisée par disque). Les badges vous guident : **⚡ cyan** = le disque le plus rapide (gardez-le en direct), **🐢 gris** = nettement plus lent (le candidat idéal à la cascade). Un clic sur le badge relance la mesure.

À savoir : il faut conserver au moins une destination directe (une alerte vous préviendra sinon) ; une cascade interrompue se relance sans tout recopier ; les checksums des copies cascade figurent dans les rapports PDF et MHL comme les autres.

## Les garde-fous intelligents (nouveau · 1.11.0)

**Contrôle pré-vol de l'espace disque** — Au lancement, après l'indexation, MisiCopy vérifie que chaque destination (directes ET cascades) peut recevoir le volume complet. Si ça ne rentre pas, la copie est refusée AVANT le premier octet, avec un message précis : « La copie nécessite 128 Go mais "JUDGEMENT" n'a que 90 Go de libre (il manque 38 Go) ». Fini le disque plein découvert à 80 % de la copie.

**Mémoire des cartes** — MisiCopy reconnaît une carte déjà déchargée avec succès (via l'historique des sessions). Quand vous la rebranchez, pas d'auto-start : une bannière dédiée s'affiche — « "A001_0719" déjà déchargée le 19/07 à 21:32 — 48 fichiers, 61 Go » — avec trois choix : **Re-vérifier** (le geste sûr, passe en mode Vérification seule), **Recopier**, ou **Ignorer**. Fini le double déchargement… et surtout, fini le formatage d'une carte qu'on croyait déchargée.

**Compteur de journée** — Dans l'en-tête, une pastille récapitule votre journée : « Aujourd'hui : 8 cartes · 1,2 To · 0 erreur ». Idéal pour le point de fin de journée avec la prod.

## Le mode plateau : copie 100 % automatique

C'est LA fonctionnalité qui change tout sur un tournage. Quatre boutons sous la section mode de copie :

**Surveillance** (bouton orange à gauche)
Quand activé, chaque carte ou disque que vous branchez est automatiquement ajouté comme source — sans bandeau, sans clic. Vous branchez, c'est dans la liste. La détection fonctionne aussi pour les médias pro qui ne signalent pas le volume comme amovible — **ARRI Codex / Codex Capture Drive**, Sony XDCAM, RED Mag, Panasonic AVCHD : MisiCopy reconnaît leur structure de dossiers caractéristique (`Codex/`, `Clips/`, `OCN/`, `XDROOT/`, `PRIVATE/`, `Footage/`…).

**Auto-start** (bouton indigo au centre)
Quand activé en plus de Surveillance, dès qu'une source est ajoutée et que vous avez au moins une destination configurée, la copie démarre toute seule. Vous n'avez même plus à cliquer sur **Lancer**.

**Auto eject** (bouton bleu)
À la fin de chaque copie réussie, MisiCopy éjecte automatiquement la carte source. Le voyant vert dans le journal signifie : **vous pouvez retirer la carte en toute sécurité**.

**Doublons** (bouton turquoise à droite · nouveau · 1.9.0)
Avant chaque copie, MisiCopy vérifie si le fichier existe déjà à destination **avec le même checksum**. Si oui, il le saute — pratique pour relancer un job sans tout recopier, ou quand une carte contient des fichiers déjà sécurisés la veille. (C'est la même option que **Options → Détection des doublons**, désormais accessible en un clic.)

**Workflow plateau typique** : début de journée, vous configurez Bay1 et Bay2 comme destinations. Vous activez les 3 boutons. Vous posez l'ordinateur sur votre table. Le DIT vous tend une carte, vous la branchez, vous la posez. Pendant que MisiCopy travaille, vous discutez avec le réal. Quand la carte est éjectée (voyant vert), vous la rangez et passez à la suivante. Aucune interaction avec l'app de toute la journée.

## La structure DIT (arborescence automatique)

Pour les workflows pro (DIT plateau, archive long-métrage), MisiCopy peut créer **automatiquement** sur chaque destination l'arborescence standard du métier au lieu de copier les fichiers à plat.

**Activation** : section **Structure DIT** en haut de la colonne de droite → bascule **Activer l'arborescence DIT** + champ **Nom du projet** (ex: `FILM_X_2026`).

**Arborescence générée** (noms par défaut, tous personnalisables dans **Réglages → Structure DIT**) :

```
FILM_X_2026/
├── 00_INFOS/                    ← rapport DIT auto-généré ici
│   └── rapport_DIT_070626.pdf
├── 01_RUSHES/                   ← les fichiers source vont ici
│   └── 070626/                  ← date du jour (JJMMAA)
│       ├── A_CAM/
│       │   └── A001_xxxx/       ← nom de la carte
│       ├── B_CAM/
│       └── SON/
├── 02_MHL/                      ← MHL auto-exporté ici
│   └── 070626_A001_xxxx.mhl
├── 03_PROXY/
│   └── 070626/
└── 04_LUT/
```

**Détection automatique de la caméra** : MisiCopy lit le nom du premier clip de chaque source. Si le nom commence par `A001_`, `B001_`, etc. (convention ARRI/RED/Sony), la carte est rangée dans le bon dossier `*_CAM/`. Sinon tu peux choisir manuellement via le menu déroulant à côté de chaque source : **A**, **B**, **C**, **D**, **SON** ou **AUTRE**.

**Sous-dossier REEL par dump (nouveau · 1.6.0)** : bascule optionnelle qui remplace le nom de la carte par un compteur `REEL_001`, `REEL_002`… numéroté **par caméra** sur l'ensemble du projet. Pratique pour le DIT plateau qui veut tracker les magazines/rolls indépendamment du nom natif des cartes.

```
FILM_X_2026/
└── 01_RUSHES/070626/
    ├── A_CAM/
    │   ├── REEL_001/             ← 1er déchargement A_CAM
    │   └── REEL_002/             ← 2ème déchargement A_CAM
    ├── B_CAM/
    │   └── REEL_001/             ← 1er déchargement B_CAM (compteur indépendant)
    └── SON/
        └── REEL_001/
```

Le compteur est persisté dans un fichier caché `.misicopy-project.json` à la racine du projet et augmente jusqu'à la fin du projet (résiste aux redémarrages de l'app). Si tu **annules** une copie en cours, le numéro REEL n'est PAS gravé : tu peux relancer le même dump et il réutilisera le même `REEL_NNN`.

**REEL depuis le nom de fichier (nouveau · 1.8.0)** : quand les fichiers de la carte suivent la convention caméra classique — RED (`A006_C001_xxxx.R3D`), ARRI (`A001C001_xxxx.mxf`), Sony (`B017C015_xxxx.mxf`) — MisiCopy lit le numéro à 3 chiffres directement dans le nom et l'utilise comme numéro de REEL. Une carte qui contient `A006_xxxx.R3D` va donc créer `REEL_006/` au lieu de `REEL_001/`. Plus aucune divergence entre le numéro sur le clap et le numéro dans l'arborescence. Le compteur séquentiel reste le fallback quand la carte n'expose pas un nom parsable (sound recorder, dump custom…).

**Personnaliser l'arborescence** : ouvre **Réglages → Structure DIT**. Tu peux :
- Renommer chaque dossier standard (ex: `01_RUSHES` → `RUSHES`, `04_LUT` → `LUTS_SHOW`)
- Changer le préfixe du rapport (ex: `rapport_DIT` → `DIT_LOG`)
- **Ajouter des dossiers supplémentaires** créés vides à la racine du projet (ex: `05_EDIT`, `06_DELIVERABLES`, `MASTER_AUDIO`, `BTS_PHOTOS`)
- Bouton **Réinitialiser** pour revenir aux valeurs par défaut

Tous les noms personnalisés sont sauvegardés et restaurés au prochain lancement.

**Workflow typique DIT plateau** : tu actives la Structure DIT une fois, tu mets le nom du film. Pour chaque carte que tu branches, le tag caméra est détecté tout seul, et la copie atterrit pile au bon endroit avec le rapport et le MHL rangés au bon dossier. Plus besoin de glisser les fichiers à la main en post-prod.

## Les options de copie

Menu **Options** — neuf bascules au total.

- **Simulation** : MisiCopy fait tourner le pipeline complet (indexation, calcul des checksums sources, génération du rapport) mais n'écrit RIEN sur disque. Idéal pour tester une config sans risquer d'écraser quoi que ce soit.
- **Préserver la structure** : réplique l'arborescence des dossiers source. Si votre carte contient `DCIM/100PANA/clip.mov`, le fichier sera copié dans `destination/MA_CARTE/DCIM/100PANA/clip.mov`. Désactivé, les fichiers sont à plat.
- **Éjecter après copie** : équivalent du bouton **Auto eject** mais accessible aussi via menu.
- **Notification système** : à la fin de chaque copie, MisiCopy déclenche une notification macOS standard (avec son). Utile si vous travaillez sur une autre app pendant la copie.
- **Ignorer fichiers système** : MisiCopy ignore les fichiers parasites de macOS et Windows (`.DS_Store`, `.Spotlight-V100`, `.fseventsd`, `Thumbs.db`, etc.) pour ne pas polluer vos rapports.
- **Organiser par date** : crée automatiquement un sous-dossier `2026-06-04/` (date du jour) dans chaque destination. Pratique pour ranger vos rushs par jour de tournage sans avoir à créer les dossiers manuellement.
- **Vignettes dans le PDF** : inclut/exclut les vignettes vidéo dans le rapport PDF généré automatiquement. À désactiver si vous voulez des rapports plus compacts.
- **Détection des doublons** : avant chaque copie, MisiCopy vérifie si le fichier existe déjà à destination AVEC le même checksum. Si oui, il saute la copie. Permet de relancer un job interrompu sans tout recopier.

## Le renommage automatique par tokens

Cas d'usage : vous voulez livrer au monteur des fichiers nommés `2026-06-04_TOURNAGE_001.mxf`, `2026-06-04_TOURNAGE_002.mxf`, etc., au lieu des noms de fichiers caméra incompréhensibles (`A001C001_240604_R1CV.mxf`).

Dans **Réglages → Renommage**, saisissez un modèle utilisant des tokens. Exemple : `{date}_TOURNAGE_{counter:04}.{ext}`

Tokens disponibles :
- `{filename}` — nom d'origine sans extension (ex: `A001C001_240604_R1CV`)
- `{ext}` — extension d'origine (ex: `mxf`)
- `{source}` — nom du dossier source (ex: `A001_C001`)
- `{camera}` — caméra détectée par MisiCopy (RED, BRAW, ARRI, Sony…), ou RAW si non identifié
- `{date}` — date au format `2026-06-04`
- `{time}` — heure au format `14-32-05`
- `{year}` `{month}` `{day}` — composants de la date séparés
- `{hour}` `{minute}` `{second}` — composants de l'heure
- `{counter}` — compteur qui s'incrémente à chaque fichier (1, 2, 3...)
- `{counter:NN}` — compteur avec padding zéros. Exemple : `{counter:04}` produit `0001`, `0002`, `0003`...

L'aperçu en temps réel sous le champ vous montre le résultat sur un fichier fictif. Pratique pour vérifier votre modèle avant de lancer une vraie copie.

## Les filtres d'extensions

Cas d'usage : sur une carte SD, vous voulez copier UNIQUEMENT les vidéos `.mxf` et `.mov`, en ignorant les fichiers de métadonnées `.xmp` et `.thm` que la caméra écrit en plus.

Dans **Réglages → Filtres**, deux champs.

**À inclure (whitelist)** : si renseigné, seuls les fichiers avec une de ces extensions seront copiés. Tout le reste est ignoré. Exemple : `mxf, mov, wav, r3d`.

**À exclure (blacklist)** : ces extensions seront toujours ignorées, même si elles passeraient le filtre d'inclusion. Exemple : `xmp, log, thm, db`.

Les deux peuvent se combiner. Si vous mettez `mxf, mov` en inclusion ET `xmp, thm` en exclusion, vous obtenez : seulement mxf+mov, et de toute façon jamais xmp ni thm.

Séparateurs acceptés : virgule, espace, point-virgule. Le point initial est optionnel — `.mxf` ou `mxf` fonctionnent pareil.

## La limite de débit

Menu **Options → Limite de débit** propose six valeurs : Illimité, 10, 25, 50, 100, 250 MB/s.

À quoi ça sert ? Sur un NAS partagé en studio, si vous copiez à pleine vitesse, vous saturez la connexion réseau et vos collègues (monteur, étalonneur...) ne peuvent plus rien faire. En limitant MisiCopy à 100 MB/s, vous laissez de la bande passante au reste de l'équipe.

Sur un SSD externe en USB-C direct, laissez sur Illimité.

**Limite globale (nouveau · 1.9.0)** : si vous copiez plusieurs cartes en parallèle (voir « La copie multi-cartes en parallèle »), la limite s'applique au **total** — deux cartes avec une limite de 100 MB/s se partagent les 100 MB/s, elles ne les cumulent pas.

## La copie multi-cartes en parallèle (nouveau · 1.9.0)

Par défaut, MisiCopy traite les sources l'une après l'autre. Sur une station de déchargement avec plusieurs lecteurs de cartes et un SSD/NVMe rapide en destination, vous pouvez copier **toutes les cartes en même temps**.

**Activation** : **Réglages → Avancé → Copier les sources en parallèle**.

Chaque carte source obtient alors son propre pipeline de copie ET de vérification : trois cartes branchées = trois flux simultanés vers vos destinations. Les stats et la barre de progression agrègent l'ensemble.

**Quand l'activer ?** Uniquement quand la destination est un SSD/NVMe. Sur un disque dur mécanique, les écritures entrelacées de plusieurs cartes font faire des allers-retours à la tête de lecture et la copie séquentielle reste plus rapide. Règle simple : destination mécanique → séquentiel, destination SSD → parallèle.

## La file d'attente

Cas d'usage : vous avez 3 cartes SD à copier l'une après l'autre, mais vous ne voulez pas attendre la fin de chaque copie pour configurer la suivante.

1. Branchez la carte 1, configurez vos destinations, cliquez **Lancer la copie sécurisée**
2. Pendant que la copie tourne, branchez la carte 2 (ou retirez la 1 et configurez via les sources la 2)
3. Cliquez sur le bouton **+ Ajouter à la file** à côté de **Annuler la copie**
4. La carte 2 est maintenant en attente dans la section **FILE D'ATTENTE** qui apparaît
5. Faites pareil pour la carte 3

Quand la copie de la carte 1 se termine, la 2 démarre automatiquement avec sa propre config. Idem pour la 3.

**Important** : chaque job en file conserve son propre snapshot de configuration (sources, destinations, mode, algo, toggles). Si vous changez les destinations entre l'ajout en file et l'exécution, ça n'affecte pas les jobs déjà en file.

**Priorités (nouveau · 1.9.0)** : chaque job de la file affiche des flèches **↑ / ↓** pour le remonter ou le descendre. Le job en haut de la liste part en premier — pratique quand le réal réclame la carte de la caméra A en priorité alors que trois cartes attendent déjà.

## Pause et reprise

Pendant une copie, à côté du bouton **Annuler**, apparaît un bouton **Pause** (jaune). Cliquez-le pour suspendre la copie entre deux fichiers (le fichier en cours termine avant la pause effective).

Le bouton devient vert avec le texte **Reprendre**. Cliquez pour continuer là où vous en étiez.

Cas d'usage : vous êtes en pleine copie quand votre câble USB devient instable. Plutôt qu'annuler et tout recommencer, vous mettez en pause, rebranchez proprement, puis reprenez.

Raccourci clavier : **⌘ P**.

## La vraie reprise après interruption (nouveau · 1.9.0)

La pause suspend la copie tant que l'app tourne. Mais que se passe-t-il si vous devez **vraiment** vous arrêter — quitter l'app, éteindre le Mac ? Pendant une copie, le gros bouton devient **Interrompre la copie — X %** (avec un rappel sous la barre : la progression est conservée).

MisiCopy mémorise désormais, **fichier par fichier**, tout ce qui a déjà été copié ET vérifié (sauvegardé sur disque toutes les 2 secondes pendant la copie). Concrètement :

- Vous **interrompez** une copie à 70 % → le journal affiche « Progression sauvegardée » → au prochain **Lancer**, MisiCopy saute les fichiers déjà sécurisés et reprend là où il s'était arrêté, **dans les mêmes dossiers** (même date, même REEL) — journal : « ⏩ N fichier(s) déjà sécurisé(s) — ignorés »
- L'app **crashe** ou le Mac s'éteint en pleine copie → au prochain lancement, le bandeau violet « Session précédente détectée » restaure la configuration ET la progression
- Garde-fou : un fichier n'est sauté que si chaque destination contient toujours une copie **de la même taille** — sinon il est recopié. En cas de doute, le mode **Vérification seule** confirme l'intégrité octet par octet.

Une copie menée à son terme efface cette mémoire de reprise : le prochain Lancer repart de zéro, comme attendu.

## Recopier les fichiers en erreur (nouveau · 1.8.0)

Si une copie se termine avec des fichiers en erreur (checksum non concordant, lecture impossible, etc.), un bouton orange **Recopier les fichiers en erreur (N)** apparaît automatiquement sous le bouton principal. Cliquez-le pour relancer la copie **uniquement sur les fichiers en échec** — pas besoin de tout recommencer depuis le début pour récupérer 2 ou 3 clips corrompus.

- Les fichiers déjà vérifiés gardent leur statut "OK" dans le rapport PDF final
- Les destinations sont les mêmes que la copie originale (les fichiers partiels sont remplacés)
- Si certains fichiers échouent à nouveau, le bouton reste affiché — recliquez pour retenter
- Le compteur (N) montre combien de fichiers restent en erreur

Pratique sur plateau quand une carte SD a un secteur instable : tu identifies le problème, tu reconnectes la carte proprement, puis tu cliques **Recopier** pour finir le job sans reprendre 90 minutes de copie.

## Les rapports automatiques

À la fin de chaque copie, une **boîte de dialogue** récapitule le résultat (fichiers vérifiés, volume, durée — désactivable dans Réglages → Général), et MisiCopy génère **automatiquement** un rapport **PDF** à la racine de chaque destination. Ce PDF contient :

- En-tête avec votre logo MisiCopy, date et heure
- Listing des sources et destinations
- Quatre stats colorées (Trouvés, Copiés, Vérifiés, Erreurs)
- Une grille de vignettes des clips détectés (formats vidéo supportés par macOS, ou panneau brandé pour les formats RAW propriétaires)
- Le tableau complet des fichiers avec leur taille, leur checksum (tronqué pour la lisibilité) et leur statut

**Regroupement par plan** : quand vous copiez une séquence d'images (DPX, EXR, ARRIRAW, CinemaDNG, etc. — un fichier par frame), MisiCopy regroupe automatiquement les frames d'un même plan. Le PDF affiche **une seule vignette** et **une seule ligne « vérifié »** par séquence (avec le nombre de frames, par exemple `shot01_####.dpx — 500 frames`), au lieu d'une ligne par frame. Le journal devient lisible, même avec 40 000 frames.

Ce PDF se nomme `MisiCopy-report-AAAAMMJJ-HHMMSS.pdf`. Vous pouvez le livrer tel quel au client comme preuve de bonne réception et d'intégrité.

Vous pouvez aussi exporter d'autres formats via le menu **Fichier** :

- **MHL v1** (`⌘ E`) — Media Hash List, le format XML historique de la production vidéo
- **ASCMHL v2** (`⌘ ⇧ E`) — le successeur officiel de MHL, standard ASC depuis 2020, format XML structuré
- **CSV** — pour ouvrir dans Excel ou Google Sheets, idéal pour des audits
- **HTML** — page web autonome avec dark mode automatique, pour archive ou partage
- **Journal .txt** (`⌘ ⇧ L`) — le journal d'activité complet en texte brut

## Vérifier un MHL existant

Cas d'usage : un client vous demande de vérifier qu'une archive livrée il y a 2 ans est toujours intacte. Vous avez le dossier de rushs ET le fichier `.mhl` qui contient les checksums originaux.

1. Menu **Fichier → Vérifier MHL…** (raccourci `⌘ ⇧ V`)
2. Le sélecteur s'ouvre — choisissez le fichier `.mhl`
3. Un deuxième sélecteur s'ouvre — choisissez le dossier qui contient les fichiers à vérifier
4. MisiCopy recalcule le checksum de chaque fichier listé dans le MHL et le compare à la valeur stockée
5. Le journal affiche le résultat pour chaque fichier : `checksum OK` ou `corrompu (attendu X… reçu Y…)`

À la fin, vous savez exactement si l'archive est saine ou si certains fichiers ont subi du bit-rot.

## Les profils (presets)

Si vous avez plusieurs configurations récurrentes (par exemple : "tournage docu" avec mode vérifié + xxHash3 + éjection, et "rétro vacances" avec copie rapide sans éjection), enregistrez-les comme profils pour basculer en un clic.

**Sauvegarder** : Menu **Profils → Enregistrer le profil actuel…**, donnez-lui un nom évocateur.

**Appliquer** : Menu **Profils → [Nom de votre profil]**.

**Gérer** : Menu **Profils → Gérer les profils…** pour supprimer ceux dont vous n'avez plus besoin.

Un profil capture : mode de copie, algorithme, préservation de structure, éjection auto, notifications, ignorer fichiers système, organisation par date.

## L'historique

Menu **Fichier → Historique…** (`⌘ Y`)

MisiCopy garde une trace des **500 dernières sessions** dans une fenêtre dédiée. Pour chaque session : date/heure, sources, destinations, nombre de fichiers, taille totale, durée, mode utilisé, statut succès/erreur.

Utile pour :
- Vérifier que vous avez bien copié telle carte tel jour
- Faire de l'audit (combien de TB transférés ce mois-ci)
- Retrouver les paramètres d'une session passée

Vous pouvez supprimer une entrée individuelle ou tout effacer.

## Les webhooks (Slack, Email, automatisation)

Cas d'usage : vous voulez recevoir un message Slack à chaque fin de copie, pour vous prévenir à distance.

Dans **Réglages → Intégrations** :

**URL Slack** : collez l'URL d'un Incoming Webhook Slack (créé via api.slack.com/apps). À chaque fin de copie, MisiCopy envoie un message court dans le channel configuré : `MisiCopy — Copie terminée — 8/8 vérifié(s)` ou `Terminé avec 2 erreur(s)`.

**Webhook générique** : collez l'URL d'un endpoint Zapier, Make.com, n8n ou n'importe quel service qui accepte un POST JSON. MisiCopy envoie un payload JSON enrichi avec toutes les stats détaillées + timestamp ISO 8601. À utiliser pour des automatisations plus poussées (envoyer un email au client, créer un row dans un Google Sheet, etc.).

## Le test de vitesse drive

Menu **Tâche → Test vitesse drive → [nom de la destination]**

Avant un gros offload, vous voulez vérifier que votre disque destination est en forme. MisiCopy écrit 100 MB de données pseudo-aléatoires sur le disque, puis les relit, et mesure le débit réel en MB/s. Le résultat est loggué dans le journal :

`bay1 — écriture 540 MB/s, lecture 720 MB/s`

À comparer avec les specs annoncées de votre disque. Si vous voyez 50 MB/s en écriture sur un SSD censé en faire 500, le disque est probablement saturé par autre chose (Spotlight indexe, antivirus scanne, Time Machine sauvegarde…).

## La reprise de session

Cas d'usage : MisiCopy crashe en pleine copie (carte débranchée, crash macOS, kernel panic…). Au prochain lancement, un bandeau violet « Session précédente détectée » apparaît en haut de la section Source.

Cliquez **Reprendre** : MisiCopy restaure automatiquement votre dernière configuration (sources, destinations, mode, algorithme, toggles) **et la progression fichier par fichier** (voir « La vraie reprise après interruption »). Vous n'avez plus qu'à cliquer Lancer : les fichiers déjà sécurisés sont sautés.

Si vous préférez recommencer de zéro, cliquez **Ignorer**.

## L'application iPhone (MisiCopy Remote)

MisiCopy Remote est une app iPhone gratuite qui vous permet de **suivre vos copies à distance**, sans rester devant le Mac. Idéal sur un plateau : vous lancez le déchargement, vous rangez le matériel, et vous surveillez la progression depuis votre poche.

**Activer côté Mac** : **Réglages → iPhone** → activez **Suivi iPhone**. Un QR code d'appairage s'affiche.

**Appairer l'iPhone** : ouvrez MisiCopy Remote → **Scanner** → visez le QR code du Mac. L'appairage est sécurisé (clé chiffrée, jamais transmise en clair) et ne se fait qu'une fois.

**Ce que vous voyez en direct sur l'iPhone :**
- La progression (anneau %, vitesse, temps restant, fichier en cours)
- Les compteurs : trouvés, copiés, vérifiés, erreurs
- Le journal d'activité en temps réel
- **L'espace disque libre de chaque destination** (barre verte / orange / rouge)
- **La phase cascade** : badge « Cascade — cartes libérées ✅ » dès que la copie principale est vérifiée — vous savez depuis votre poche que la carte peut être retirée

**Piloter depuis l'iPhone :**
- **Pause / Reprendre / Annuler** la copie en cours
- **Recopier les fichiers en erreur** : si une copie finit avec des erreurs checksum, relancez uniquement les fichiers concernés directement depuis le téléphone

**Suivi sur l'écran verrouillé (Live Activity · redessiné en 1.2.0)** : pendant une copie, une tuile apparaît sur l'écran verrouillé et dans la Dynamic Island. Elle **se met à jour en temps réel même iPhone en veille** — vous voyez la progression avancer sans déverrouiller. La tuile affiche le pourcentage en grand, la vitesse en MB/s et le temps restant, sur fond sombre contrasté pour une lisibilité à bout de bras. À la fin, une **notification** vous prévient (succès ou erreur), même si l'app est en arrière-plan ou que l'écran est verrouillé — la notification perce le mode Ne pas déranger (interruption urgente).

**Deux canaux de connexion :**
- **Wi-Fi local** (recommandé) : Mac et iPhone sur le même réseau — latence quasi nulle, aucune donnée ne sort du réseau.
- **iCloud** (repli) : quand vous n'êtes pas sur le même Wi-Fi, l'iPhone lit l'état via votre iCloud privé. Le suivi écran verrouillé en temps réel reste actif via les notifications push, où que vous soyez.

## Les langues

Menu **Langue** : Français, English, Español. Le changement est instantané — toute l'interface (y compris la barre de menus système macOS) bascule en temps réel.

## Les raccourcis clavier

| Raccourci | Action |
|---|---|
| ⌘ R | Lancer / Annuler |
| ⌘ P | Pause / Reprendre |
| ⌘ ⇧ A | Ajouter à la file d'attente |
| ⌘ E | Exporter MHL v1 |
| ⌘ ⇧ E | Exporter ASCMHL v2 |
| ⌘ ⇧ V | Vérifier un MHL existant |
| ⌘ ⇧ L | Exporter le journal en .txt |
| ⌘ Y | Ouvrir l'historique |
| ⌘ , | Ouvrir les Réglages |

## Questions fréquentes

**« Carte non détectée » sur macOS Sequoia ou plus récent**
macOS 15+ a introduit une nouvelle permission TCC qui restreint l'accès aux volumes amovibles. Allez dans **Réglages système → Confidentialité et sécurité → Fichiers et dossiers → MisiCopy**, et activez **Volumes amovibles**.

**Comment passer ma licence sur un autre Mac ?**
Sur l'ancien Mac : Réglages → Licence → bouton **Désactiver sur ce poste**. Puis sur le nouveau Mac : installez l'app, ouvrez Réglages → Licence, collez la même clé. C'est instantané.

**J'ai perdu ma clé de licence**
Cherchez dans vos emails l'envoi de Payhip post-achat (objet contenant "MisiCopy" ou "MisiRaca"). Si introuvable, écrivez à misicopy@misiraca.com en précisant l'email utilisé pour l'achat — je retrouverai votre commande dans Payhip et vous renverrai la clé.

**xxHash3 ou xxHash64 ?**
Si vous utilisez MisiCopy en solo (vos rushs, vos archives), restez sur xxHash3 (64-bit) qui est plus rapide. Si vous échangez des fichiers MHL avec un studio qui utilise un outil ancien, vérifiez avec eux quel algo ils attendent — généralement xxHash64 ou MD5.

**La file d'attente s'arrête si un job échoue ?**
Non. MisiCopy traite tous les jobs en file séquentiellement. Si un fichier dans un job a une erreur, le job continue avec les autres fichiers. Si tout un job échoue (carte débranchée par exemple), le job suivant en file démarre quand même.

**Combien de destinations puis-je avoir en simultané ?**
Il n'y a pas de limite codée. Sept ou huit destinations en parallèle sont parfaitement gérables. Au-delà, la vitesse de copie sera limitée par la lecture de la source — chaque destination supplémentaire ne ralentit pas significativement.

## Support

Pour toute question ou souci, écrivez à **misicopy@misiraca.com**. Je réponds sous 24 heures (souvent dans la journée).

Site : **www.misicopy.com**

---

# 🇬🇧 English

## Overview

MisiCopy is a macOS application that copies your footage from memory cards (SD, CFexpress, microSD) or drives (SSD, HDD) to one or several destinations, verifying that no bit is altered during transfer. This is called **checksummed copy**, the industry standard for the past 15 years.

**Why do you need it?** When you copy a file with Finder, macOS doesn't verify that the bytes written to the destination match those read from the source. On critical data like your shooting footage, a defective SD card, a worn-out USB cable or a cosmic ray can silently corrupt a few bytes. You'll only find out during editing, when a clip crashes. MisiCopy computes a digital signature (checksum) before and after each copy: if they don't match, you know immediately.

**For whom?** DITs (Digital Imaging Technicians) on set, solo videographers, wedding photographers, documentary teams — anyone who can't afford to lose a file.

## Installation

1. Download **MisiCopy-1.0.dmg** from the link sent by Payhip after your purchase
2. Double-click the DMG to mount it
3. Drag the **MisiCopy** icon into the **Applications** folder that appears in the same window
4. Eject the DMG (right-click → Eject)
5. Launch MisiCopy from **Applications** or by searching its name in Spotlight (⌘ Space)

On first launch, macOS may show a security dialog asking if you really want to open an app downloaded from the Internet. Click **Open**. The app is signed and notarized by Apple, so it's safe.

## Activate your license

When first opened, MisiCopy runs in **trial mode**: **7 days** of use OR **25 complete transfers** (whichever comes first stops the trial). During this period, you have access to all features without restriction.

To activate your permanent license:

1. Menu **MisiCopy → Settings** (shortcut **⌘ ,**)
2. Click the **License** tab on the left
3. In the **License key** field, paste the key received from Payhip
4. The **Email** field is optional — it's just a label for display
5. Click **Activate**

The green **LICENSED** badge appears in the top-right corner of the main window. Your key is saved in the **macOS Keychain**, meaning it survives the uninstallation/reinstallation of the app.

**One license covers 2 machines.** Activate it on your desktop AND your on-set MacBook with the same key. To free a slot: Settings → License → **Deactivate on this machine**.

## The main interface in detail

The window is divided into three zones.

**Top bar**
- Logo and app name
- License status (trial with days/transfers remaining counter, or active LICENSE, or EXPIRED)
- Language indicator with quick switch

**Left column (configuration)**
- The four **copy mode** cards (simple verification, double verification, fast copy, verify only)
- A row of 4 quick buttons: **Watch**, **Auto-start**, **Auto eject**, **Dupes**
- The **Sources** section where you add your cards and drives
- The **Destinations** section where you add target folders

**Right column (real-time monitoring)**
- Four colored stats: **Found** (blue), **Copied** (indigo), **Verified** (green), **Errors** (orange)
- The big **Start secure copy** button with progress bar
- The **Queue** (only visible if you have multiple jobs)
- The **Activity log** at the bottom, with scrollbar to review the session history

## The four copy modes

### Copy + verification (recommended)

This is the mode you'll use 90% of the time. MisiCopy computes the source file's checksum, copies it to the destination, recomputes the destination file's checksum, and compares. If both signatures are identical, the file is marked **Verified**. This is sufficient for 99% of professional use cases.

### Copy + double verification

Same as above, **plus a second read of the source file after the copy**. This second read detects defective SD cards that return different data on each re-read (rare but it happens on old cards). Use for your **long-term archives** or when you're unsure about a card's state.

Cost: doubles the source read time (the copy itself stays the same speed; it's the verification phase that takes longer).

### Fast copy

**No verification.** MisiCopy copies files but doesn't verify anything. Faster, but no guarantee on destination integrity. Reserve for temporary non-critical work copies (e.g., quick card preview).

### Verify only (new · 1.9.0)

**Copies nothing.** MisiCopy computes the checksum of each source file, then the checksum of the copy **already present** at the destination, and compares. It writes **strictly nothing** to the disks — not even a report. If you want a record, export the report (MHL, CSV, log) via the **File** menu after the verification.

Typical use cases:
- You offloaded a card in **Fast copy** on a rushed set, and want to verify integrity later in the evening, calmly
- Doubt about a backup drive: re-verify a whole day of footage without re-copying
- Quality control before wiping cards: proof that every byte at destination matches the source

Select the source card and the destination drive: MisiCopy **finds the copy by itself**, even if it was made on another day, in another REEL folder or with different settings (it searches every plausible layout — dates, cameras, REELs, with or without a card folder). The main button then reads **Start verification**. A missing or altered file at destination shows up as an error, with the full searched path in the log.

## Checksum algorithms

In **Options → Algorithm** (or **Settings → General**), six choices.

- **xxHash3 (64-bit)** — default. The fastest algorithm on Apple Silicon, the industry standard since 2024. 64-bit signature, enough to detect any accidental corruption.
- **xxHash3 (128-bit)** — same algorithm but 128-bit signature, twice as long. Slightly slower. Use if you exchange footage with tools that require this specific format.
- **xxHash64** — previous version of xxHash. Only use for compatibility with old MHL files generated by ShotPut Pro 2022 and earlier.
- **MD5** — universally compatible. Much slower (8 to 10 times slower than xxHash3). Use if your studio mandates MD5 for delivery.
- **SHA-1** — legacy, avoid unless explicitly required.
- **SHA-256** — cryptographic algorithm, the slowest. Useful for regulatory signature requirements (rare in video production).

**Recommendation**: stay on xxHash3 (64-bit) unless the final client explicitly requests otherwise.

## Adding a source

A "source" is where you copy FROM: an SD card, an external drive, a folder on your internal disk. Three methods.

**Method 1 — Drag & drop**: open Finder, navigate to your card or folder, drag it onto the **Source** area of MisiCopy. The card appears immediately in the list.

**Method 2 — + Button (Choose)**: click the **+** button next to the SOURCE title. The macOS file picker opens. Navigate to your card (usually `/Volumes/CARD_NAME`) and click **Select**.

**Method 3 — Auto-detection banner**: when you plug in a card or external drive, an orange banner « Card detected — NAME » appears automatically at the top of the Source section. Click **Add as source** to use it, or **Dismiss** if it's not the card you want.

**Multiple sources**: you can add as many sources as you want. MisiCopy will process them one after the other, grouping files into sub-folders named after each source. Typical case: multi-cam where you have A-cam, B-cam and an audio recorder. You add all three, MisiCopy copies everything into `bay1/A-cam/`, `bay1/B-cam/`, `bay1/sound/`.

## Adding destinations

A "destination" is a target folder where files will be copied. Multiple destinations are possible — MisiCopy copies in parallel to each and verifies each independently.

Methods are identical to sources: drag & drop a folder or + button. For example:
- **Bay1**: your main working drive
- **Bay2**: backup on a second drive
- **NAS**: a network folder shared with the editor

At the end of the copy, the source file will have been copied to all three destinations AND verified on all three.

**Good to know**: Time Machine volumes are automatically excluded from detection. MisiCopy recognizes their internal structure (`.com.apple.timemachine.donotpresent`, `Backups.backupdb`) and never proposes them as source or destination.

## Cascading destinations (new · 1.10.0)

The classic problem: you copy to a fast SSD AND a big archive hard drive. Without cascading, the whole copy runs at the slowest drive's speed, and the card stays busy for hours.

**The solution**: click the **↳** button on the slow destination — it switches to **CASCADE** mode. It is no longer copied from the card, but **from the first direct destination**, once the primary copy is verified.

1. **Phase 1** — card → direct destinations only, at full speed
2. **The card is released** as soon as phase 1 is verified (and auto-ejected if Auto eject is on) — plug in the next card right away
3. **Phase 2** — the first direct destination feeds the cascades, with full checksum verification against the card's original hash (the re-read even re-checks the primary copy in passing)

**Speed markers**: when you add a destination, MisiCopy measures its write speed (a ~1-second probe, remembered per drive). The badges guide you: **⚡ cyan** = the fastest drive (keep it direct), **🐢 grey** = clearly slower (the ideal cascade candidate). Click the badge to re-measure.

Good to know: keep at least one direct destination (an alert will warn you otherwise); an interrupted cascade re-runs without re-copying everything; cascade checksums appear in the PDF and MHL reports like any other.

## Smart safety nets (new · 1.11.0)

**Disk-space preflight** — On start, after indexing, MisiCopy checks that every destination (direct AND cascade) can hold the full volume. If it won't fit, the copy is refused BEFORE the first byte, with a precise message: "The copy needs 128 GB but \"JUDGEMENT\" only has 90 GB free (38 GB missing)". No more discovering a full disk at 80% of the copy.

**Card memory** — MisiCopy recognizes a card that was already successfully offloaded (via the session history). When you plug it back in, no auto-start: a dedicated banner shows — "\"A001_0719\" already offloaded on 07/19 at 9:32 PM — 48 files, 61 GB" — with three choices: **Re-verify** (the safe move, switches to Verify-only mode), **Re-copy**, or **Dismiss**. No more double offloads… and above all, no more formatting a card you thought was already dumped.

**Daily counter** — In the header, a pill sums up your day: "Today: 8 cards · 1.2 TB · 0 errors". Perfect for the end-of-day wrap with production.

## On-set mode: 100% automated copy

This is THE feature that changes everything on set. Four buttons under the copy mode section:

**Watch** (orange button on left)
When enabled, every card or drive you plug in is automatically added as source — no banner, no click. You plug, it's in the list. Detection also works for pro media that doesn't expose the removable flag — **ARRI Codex / Codex Capture Drive**, Sony XDCAM, RED Mag, Panasonic AVCHD: MisiCopy recognises their characteristic folder layout (`Codex/`, `Clips/`, `OCN/`, `XDROOT/`, `PRIVATE/`, `Footage/`…).

**Auto-start** (indigo button center)
When enabled in addition to Watch, as soon as a source is added and you have at least one destination configured, copy starts automatically. You don't even need to click **Start** anymore.

**Auto eject** (blue button)
At the end of each successful copy, MisiCopy automatically ejects the source card. The green log light means: **you can safely remove the card**.

**Dupes** (teal button on right · new · 1.9.0)
Before each copy, MisiCopy checks whether the file already exists at destination **with the same checksum**. If so, it skips it — handy to relaunch a job without re-copying everything, or when a card contains files already secured the day before. (Same option as **Options → Duplicate detection**, now one click away.)

**Typical on-set workflow**: start of day, you configure Bay1 and Bay2 as destinations. You enable the 3 buttons. You put the computer on your table. The DIT hands you a card, you plug it in, you set it down. While MisiCopy works, you chat with the director. When the card is ejected (green light), you put it away and move to the next. Zero app interaction all day.

## DIT folder structure (automatic layout)

For pro workflows (on-set DIT, long-feature archival), MisiCopy can **automatically** build the industry-standard folder structure on every destination instead of copying files flat.

**Enable**: section **DIT structure** at the top of the right column → toggle **Enable DIT folder structure** + **Project name** field (e.g. `FILM_X_2026`).

**Generated layout** (default names, all customisable in **Settings → DIT structure**):

```
FILM_X_2026/
├── 00_INFOS/                    ← DIT report auto-written here
│   └── rapport_DIT_070626.pdf
├── 01_RUSHES/                   ← source files land here
│   └── 070626/                  ← today's date (DDMMYY)
│       ├── A_CAM/
│       │   └── A001_xxxx/       ← card name
│       ├── B_CAM/
│       └── SON/
├── 02_MHL/                      ← MHL auto-exported here
│   └── 070626_A001_xxxx.mhl
├── 03_PROXY/
│   └── 070626/
└── 04_LUT/
```

**Automatic camera detection**: MisiCopy reads the name of the first clip on each source. If it starts with `A001_`, `B001_`, etc. (ARRI/RED/Sony convention), the card is routed to the matching `*_CAM/` folder. Otherwise you can pick manually via the dropdown next to each source: **A**, **B**, **C**, **D**, **SON** or **AUTRE**.

**REEL subfolder per dump (new · 1.6.0)**: optional toggle that replaces the card name by a `REEL_001`, `REEL_002`… counter numbered **per camera** across the whole project. Handy for on-set DITs who track magazines/rolls independently of the cards' native names.

```
FILM_X_2026/
└── 01_RUSHES/070626/
    ├── A_CAM/
    │   ├── REEL_001/             ← 1st A_CAM dump
    │   └── REEL_002/             ← 2nd A_CAM dump
    ├── B_CAM/
    │   └── REEL_001/             ← 1st B_CAM dump (independent counter)
    └── SON/
        └── REEL_001/
```

The counter is persisted in a hidden `.misicopy-project.json` file at the project root and keeps incrementing across app restarts until the end of the project. If you **cancel** a copy in progress, the REEL number is NOT burned in: relaunch the same dump and it reuses the same `REEL_NNN`.

**Customise the structure**: open **Settings → DIT structure**. You can:
- Rename each standard folder (e.g. `01_RUSHES` → `RUSHES`, `04_LUT` → `SHOW_LUTS`)
- Change the report prefix (e.g. `rapport_DIT` → `DIT_LOG`)
- **Add extra folders** created empty at the project root (e.g. `05_EDIT`, `06_DELIVERABLES`, `MASTER_AUDIO`, `BTS_PHOTOS`)
- **Reset to defaults** button to restore standard names

All customisations are saved and restored on next launch.

## Copy options

Menu **Options** — nine toggles total.

- **Simulation**: MisiCopy runs the full pipeline (indexing, source checksum computation, report generation) but writes NOTHING to disk. Ideal for testing a config without risk.
- **Preserve structure**: replicates the source folder tree. If your card contains `DCIM/100PANA/clip.mov`, the file is copied to `destination/MY_CARD/DCIM/100PANA/clip.mov`. Disabled, files are flat.
- **Eject after copy**: equivalent to the **Auto eject** button but also accessible via menu.
- **System notification**: at the end of each copy, MisiCopy triggers a standard macOS notification (with sound). Useful if you work on another app during the copy.
- **Skip system files**: MisiCopy ignores parasitic macOS and Windows files (`.DS_Store`, `.Spotlight-V100`, `.fseventsd`, `Thumbs.db`, etc.) to keep your reports clean.
- **Organize by date**: automatically creates a sub-folder `2026-06-04/` (today's date) in each destination. Handy to sort your footage by shoot day without manually creating folders.
- **Thumbnails in PDF**: includes/excludes video thumbnails in the auto-generated PDF report. Disable for more compact reports.
- **Duplicate detection**: before each copy, MisiCopy checks if the file already exists at destination WITH the same checksum. If yes, it skips the copy. Allows resuming an interrupted job without re-copying everything.

## Token-based renaming

Use case: you want to deliver to the editor files named `2026-06-04_SHOOT_001.mxf`, `2026-06-04_SHOOT_002.mxf`, etc., instead of the cryptic camera names (`A001C001_240604_R1CV.mxf`).

In **Settings → Renaming**, enter a pattern using tokens. Example: `{date}_SHOOT_{counter:04}.{ext}`

Available tokens:
- `{filename}` — original name without extension (e.g.: `A001C001_240604_R1CV`)
- `{ext}` — original extension (e.g.: `mxf`)
- `{source}` — source folder name (e.g.: `A001_C001`)
- `{camera}` — camera detected by MisiCopy (RED, BRAW, ARRI, Sony…), or RAW if unidentified
- `{date}` — date in `2026-06-04` format
- `{time}` — time in `14-32-05` format
- `{year}` `{month}` `{day}` — date components
- `{hour}` `{minute}` `{second}` — time components
- `{counter}` — counter incremented per file (1, 2, 3...)
- `{counter:NN}` — zero-padded counter. Example: `{counter:04}` produces `0001`, `0002`...

Live preview under the field shows the result on a sample file. Useful to verify your pattern before running a real copy.

## Extension filters

Use case: on an SD card, you want to copy ONLY `.mxf` and `.mov` videos, ignoring `.xmp` and `.thm` metadata files the camera writes.

In **Settings → Filters**, two fields.

**Include (whitelist)**: if set, only files with one of these extensions will be copied. Everything else is ignored. Example: `mxf, mov, wav, r3d`.

**Exclude (blacklist)**: these extensions are always ignored, even if they would pass the include filter. Example: `xmp, log, thm, db`.

Both can combine. If you set `mxf, mov` in include AND `xmp, thm` in exclude, you get: only mxf+mov, and never xmp nor thm anyway.

Accepted separators: comma, space, semicolon. Leading dot is optional — `.mxf` or `mxf` work the same.

## Bandwidth limit

Menu **Options → Bandwidth limit** offers six values: Unlimited, 10, 25, 50, 100, 250 MB/s.

What's it for? On a shared studio NAS, if you copy at full speed, you saturate the network connection and your colleagues (editor, colorist…) can't work. Limiting MisiCopy to 100 MB/s leaves bandwidth for the rest of the team.

On a direct USB-C external SSD, leave on Unlimited.

**Global limit (new · 1.9.0)**: if you copy several cards in parallel (see "Parallel multi-card copy"), the limit applies to the **total** — two cards under a 100 MB/s cap share the 100 MB/s, they don't stack it.

## Parallel multi-card copy (new · 1.9.0)

By default, MisiCopy processes sources one after the other. On an offload station with several card readers and a fast SSD/NVMe destination, you can copy **all cards at the same time**.

**Enable**: **Settings → Advanced → Copy sources in parallel**.

Each source card then gets its own copy AND verification pipeline: three cards plugged in = three simultaneous streams toward your destinations. Stats and the progress bar aggregate the whole.

**When to enable it?** Only when the destination is an SSD/NVMe. On a spinning hard drive, interleaved writes from several cards make the head seek back and forth, and sequential copy stays faster. Simple rule: spinning destination → sequential, SSD destination → parallel.

## The queue

Use case: you have 3 SD cards to copy in sequence, but you don't want to wait for each copy to finish before configuring the next.

1. Plug in card 1, configure your destinations, click **Start secure copy**
2. While the copy runs, plug in card 2 (or remove card 1 and configure card 2 via sources)
3. Click the **+ Add to queue** button next to **Cancel copy**
4. Card 2 is now waiting in the **QUEUE** section that appears
5. Same for card 3

When card 1's copy finishes, card 2 starts automatically with its own config. Same for card 3.

**Important**: each queued job keeps its own configuration snapshot (sources, destinations, mode, algo, toggles). Changing destinations between queueing and execution doesn't affect already-queued jobs.

**Priorities (new · 1.9.0)**: each queued job shows **↑ / ↓** arrows to move it up or down. The job at the top of the list runs first — handy when the director wants the A-cam card first while three cards are already waiting.

## Pause and resume

During a copy, next to the **Cancel** button, a **Pause** button appears (yellow). Click it to suspend the copy between two files (the current file finishes before the actual pause).

The button turns green with **Resume** text. Click to continue where you left off.

Use case: you're mid-copy when your USB cable becomes unstable. Rather than cancel and start over, you pause, replug cleanly, then resume.

Keyboard shortcut: **⌘ P**.

## True resume after interruption (new · 1.9.0)

Pause suspends the copy while the app runs. But what if you must **really** stop — quit the app, shut the Mac down? During a copy the big button becomes **Interrupt copy — X%** (with a reminder under the bar: progress is preserved).

MisiCopy now remembers, **file by file**, everything already copied AND verified (saved to disk every 2 seconds during the copy). Concretely:

- You **interrupt** a copy at 70% → the log shows "Progress saved" → on the next **Start**, MisiCopy skips the files already secured and resumes where it stopped, **in the same folders** (same date, same REEL) — log: "⏩ N file(s) already secured — skipped"
- The app **crashes** or the Mac shuts down mid-copy → on next launch, the purple "Previous session detected" banner restores the configuration AND the progress
- Safety net: a file is only skipped if every destination still holds a copy **of the same size** — otherwise it's re-copied. When in doubt, the **Verify only** mode confirms integrity byte by byte.

A copy that runs to completion clears this resume memory: the next Start begins from scratch, as expected.

## Automatic reports

At the end of each copy, a **dialog box** sums up the result (verified files, volume, duration — can be disabled in Settings → General), and MisiCopy **automatically** generates a **PDF report** at the root of each destination. This PDF contains:

- Header with your MisiCopy logo, date and time
- Listing of sources and destinations
- Four colored stats (Found, Copied, Verified, Errors)
- A grid of thumbnails for detected clips (video formats supported by macOS, or branded panel for proprietary RAW formats)
- Complete table of files with their size, checksum (truncated for readability) and status

**Plan grouping**: when you copy an image sequence (DPX, EXR, ARRIRAW, CinemaDNG, etc. — one file per frame), MisiCopy automatically groups frames belonging to the same shot. The PDF shows **one thumbnail** and **one "verified" row** per sequence (with the frame count, e.g. `shot01_####.dpx — 500 frames`) instead of one row per frame. The journal stays readable even with 40 000 frames.

The PDF is named `MisiCopy-report-YYYYMMDD-HHMMSS.pdf`. You can deliver it as-is to the client as proof of correct receipt and integrity.

You can also export other formats via the **File** menu:

- **MHL v1** (`⌘ E`) — Media Hash List, the historical XML format of video production
- **ASCMHL v2** (`⌘ ⇧ E`) — official MHL successor, ASC standard since 2020
- **CSV** — for Excel or Google Sheets, ideal for audits
- **HTML** — standalone web page with auto dark mode
- **Log .txt** (`⌘ ⇧ L`) — full activity log in plain text

## Verifying an existing MHL

Use case: a client asks you to verify that an archive delivered 2 years ago is still intact. You have the footage folder AND the `.mhl` file with original checksums.

1. Menu **File → Verify MHL…** (shortcut `⌘ ⇧ V`)
2. The picker opens — choose the `.mhl` file
3. A second picker opens — choose the folder containing the files to verify
4. MisiCopy recomputes each file's checksum and compares to the stored value
5. The log shows the result for each file: `checksum OK` or `corrupted (expected X… got Y…)`

At the end, you know exactly if the archive is healthy or if files have suffered bit-rot.

## Presets

If you have several recurring configurations (e.g., "doc shoot" with verified mode + xxHash3 + eject, and "vacation retro" with fast copy without eject), save them as presets to switch in one click.

**Save**: Menu **Presets → Save current preset…**, give it an evocative name.

**Apply**: Menu **Presets → [Your preset name]**.

**Manage**: Menu **Presets → Manage presets…** to delete ones you no longer need.

A preset captures: copy mode, algorithm, structure preservation, auto-eject, notifications, skip system files, organize by date.

## History

Menu **File → History…** (`⌘ Y`)

MisiCopy keeps track of the **last 500 sessions** in a dedicated window. For each session: date/time, sources, destinations, file count, total size, duration, mode used, success/error status.

Useful for:
- Verifying you copied a particular card on a particular day
- Auditing (how many TB transferred this month)
- Recovering parameters from a past session

You can delete an individual entry or clear all.

## Webhooks (Slack, Email, automation)

Use case: you want to receive a Slack message at each end of copy, to alert you remotely.

In **Settings → Integrations**:

**Slack URL**: paste a Slack Incoming Webhook URL (created via api.slack.com/apps). At each end of copy, MisiCopy sends a short message in the configured channel: `MisiCopy — Copy finished — 8/8 verified` or `Finished with 2 error(s)`.

**Generic webhook**: paste a Zapier, Make.com, n8n endpoint URL or any service accepting JSON POST. MisiCopy sends an enriched JSON payload with all detailed stats + ISO 8601 timestamp. Use for more advanced automation (email client, create row in Google Sheet, etc.).

## Drive speed test

Menu **Job → Drive speed test → [destination name]**

Before a big offload, you want to verify your destination drive is in shape. MisiCopy writes 100 MB of pseudo-random data to the disk, then reads it back, and measures actual throughput in MB/s. Result is logged:

`bay1 — write 540 MB/s, read 720 MB/s`

Compare with your drive's spec'd speeds. If you see 50 MB/s write on an SSD rated 500, the drive is probably saturated by something else (Spotlight indexing, antivirus scanning, Time Machine backing up…).

## Session resume

Use case: MisiCopy crashes mid-copy (card unplugged, macOS crash, kernel panic…). At the next launch, a purple banner « Previous session detected » appears at the top of the Source section.

Click **Resume**: MisiCopy automatically restores your last configuration (sources, destinations, mode, algorithm, toggles) **and the file-by-file progress** (see "True resume after interruption"). All you need is to click Start: already-secured files are skipped.

If you prefer to start fresh, click **Dismiss**.

## The iPhone app (MisiCopy Remote)

MisiCopy Remote is a free iPhone app that lets you **monitor your copies remotely**, without staying at the Mac. Perfect on set: start the offload, put your gear away, and watch progress from your pocket.

**Enable on the Mac**: **Settings → iPhone** → turn on **iPhone monitoring**. A pairing QR code appears.

**Pair the iPhone**: open MisiCopy Remote → **Scan** → point at the Mac's QR code. Pairing is secure (encrypted key, never sent in clear) and only happens once.

**What you see live on iPhone:**
- Progress (% ring, speed, time remaining, current file)
- Counters: found, copied, verified, errors
- The live activity log
- **Free disk space of each destination** (green / orange / red bar)
- **The cascade phase**: a "Cascade — cards released ✅" badge as soon as the primary copy is verified — you know from your pocket that the card can be pulled

**Control from the iPhone:**
- **Pause / Resume / Cancel** the running copy
- **Re-copy failed files**: if a copy ends with checksum errors, relaunch only the affected files straight from the phone

**Lock-screen tracking (Live Activity · redesigned in 1.2.0)**: during a copy, a tile appears on the lock screen and in the Dynamic Island. It **updates in real time even while the iPhone is asleep** — you watch progress advance without unlocking. The tile displays the percentage prominently, speed in MB/s, and ETA on a dark contrasted background for arm's-length readability. When it finishes, a **notification** alerts you (success or error), even if the app is in the background or the screen is locked — the notification pierces Do Not Disturb (time-sensitive interruption).

**Two connection channels:**
- **Local Wi-Fi** (recommended): Mac and iPhone on the same network — near-zero latency, no data leaves the network.
- **iCloud** (fallback): when you're not on the same Wi-Fi, the iPhone reads the state via your private iCloud. Real-time lock-screen tracking keeps working through push notifications, wherever you are.

## Languages

Menu **Language**: French, English, Spanish. Change is instant — the entire UI (including the macOS system menu bar) switches in real-time.

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘ R | Start / Cancel |
| ⌘ P | Pause / Resume |
| ⌘ ⇧ A | Add to queue |
| ⌘ E | Export MHL v1 |
| ⌘ ⇧ E | Export ASCMHL v2 |
| ⌘ ⇧ V | Verify an existing MHL |
| ⌘ ⇧ L | Export log as .txt |
| ⌘ Y | Open history |
| ⌘ , | Open Settings |

## FAQ

**« Card not detected » on macOS Sequoia or newer**
macOS 15+ introduced a new TCC permission restricting access to removable volumes. Go to **System Settings → Privacy & Security → Files and Folders → MisiCopy**, and enable **Removable Volumes**.

**How do I move my license to another Mac?**
On the old Mac: Settings → License → **Deactivate on this machine** button. Then on the new Mac: install the app, open Settings → License, paste the same key. Instant.

**I lost my license key**
Search your emails for the Payhip post-purchase send (subject containing "MisiCopy" or "MisiRaca"). If not found, write to misicopy@misiraca.com specifying the email used for purchase — I'll find your order in Payhip and resend the key.

**xxHash3 or xxHash64?**
If you use MisiCopy solo (your footage, your archives), stick with xxHash3 (64-bit) which is faster. If you exchange MHL files with a studio using an old tool, check with them which algo they expect — usually xxHash64 or MD5.

**Does the queue stop if a job fails?**
No. MisiCopy processes all queued jobs sequentially. If a file in a job has an error, the job continues with other files. If a whole job fails (card unplugged for example), the next queued job still starts.

**How many destinations can I have at once?**
There's no hard-coded limit. Seven or eight parallel destinations are perfectly manageable. Beyond that, copy speed will be limited by source read — each additional destination doesn't significantly slow down.

## Support

For any question or issue, write to **misicopy@misiraca.com**. I respond within 24 hours (often same day).

Website: **www.misicopy.com**

---

# 🇪🇸 Español

## Presentación

MisiCopy es una aplicación macOS que copia tus brutos desde tarjetas de memoria (SD, CFexpress, microSD) o discos (SSD, HDD) a uno o varios destinos, verificando que ningún bit se altera durante la transferencia. Esto se llama **copia con checksum**, el estándar de la industria desde hace 15 años.

**¿Por qué la necesitas?** Cuando copias un archivo con el Finder, macOS no verifica que los bytes escritos en el destino coincidan con los leídos del origen. Sobre datos críticos como tus brutos de rodaje, una tarjeta SD defectuosa, un cable USB gastado o un cosmic ray pueden corromper silenciosamente algunos bytes. Solo lo descubrirás en montaje, cuando un clip falle. MisiCopy calcula una firma digital (checksum) antes y después de cada copia: si no coinciden, lo sabes al instante.

**¿Para quién?** DITs (Digital Imaging Technicians) en rodaje, videógrafos solitarios, fotógrafos de bodas, equipos documentales — cualquier persona que no puede permitirse perder un archivo.

## Instalación

1. Descarga **MisiCopy-1.0.dmg** desde el enlace enviado por Payhip tras tu compra
2. Haz doble clic en el DMG para montarlo
3. Arrastra el icono **MisiCopy** a la carpeta **Aplicaciones** que aparece en la misma ventana
4. Expulsa el DMG (clic derecho → Expulsar)
5. Abre MisiCopy desde **Aplicaciones** o buscando su nombre en Spotlight (⌘ Espacio)

En el primer arranque, macOS puede mostrar un diálogo de seguridad preguntando si realmente quieres abrir una app descargada de Internet. Haz clic en **Abrir**. La app está firmada y notarizada por Apple, así que no hay riesgo.

## Activar tu licencia

Al abrir, MisiCopy arranca en **modo prueba**: **7 días** de uso O **25 transferencias completas** (lo primero que ocurra detiene la prueba). Durante este periodo, tienes acceso a todas las funciones sin restricción.

Para activar tu licencia permanente:

1. Menú **MisiCopy → Ajustes** (atajo **⌘ ,**)
2. Haz clic en la pestaña **Licencia** a la izquierda
3. En el campo **Clave de licencia**, pega la clave recibida de Payhip
4. El campo **Email** es opcional — sirve solo como etiqueta de visualización
5. Haz clic en **Activar**

La insignia verde **LICENCIA** aparece en la esquina superior derecha. Tu clave se guarda en el **Llavero de macOS**, lo que significa que sobrevive a la desinstalación/reinstalación de la app.

**Una licencia cubre 2 ordenadores.** Actívala en tu fijo Y tu MacBook de rodaje con la misma clave. Para liberar un equipo: Ajustes → Licencia → **Desactivar en este equipo**.

## La interfaz en detalle

La ventana se divide en tres zonas.

**Barra superior**
- Logo y nombre de la app
- Estado de licencia (prueba con contador días/transferencias restantes, o LICENCIA activa, o EXPIRADO)
- Indicador de idioma con cambio rápido

**Columna izquierda (configuración)**
- Las cuatro tarjetas de **modo de copia** (verificación simple, doble verificación, copia rápida, solo verificación)
- Una fila de 4 botones rápidos: **Vigilancia**, **Auto-inicio**, **Auto eject**, **Duplicados**
- La sección **Orígenes** donde añades tus tarjetas y discos
- La sección **Destinos** donde añades las carpetas destino

**Columna derecha (seguimiento en tiempo real)**
- Cuatro estadísticas en colores: **Encontrados** (azul), **Copiados** (índigo), **Verificados** (verde), **Errores** (naranja)
- El botón grande **Iniciar copia segura** con su barra de progreso
- La **Cola** (visible solo si tienes varios trabajos)
- El **Registro de actividad** abajo, con scroll para revisar la sesión

## Los cuatro modos de copia

### Copia + verificación (recomendado)

Es el modo que usarás el 90% del tiempo. MisiCopy calcula el checksum del archivo origen, lo copia al destino, recalcula el checksum del archivo destino, y compara. Si ambas firmas son idénticas, el archivo se marca como **Verificado**. Suficiente para el 99% de los casos profesionales.

### Copia + doble verificación

Igual que el anterior, **más una segunda lectura del archivo origen tras la copia**. Esta segunda lectura permite detectar tarjetas SD defectuosas que devuelven datos distintos en cada relectura (raro pero ocurre). Úsalo para tus **archivos a largo plazo** o cuando dudes del estado de una tarjeta.

Coste: duplica el tiempo de lectura del origen.

### Copia rápida

**Sin verificación.** MisiCopy copia los archivos pero no verifica nada. Más rápida, pero sin garantía de integridad. Resérvalo para copias de trabajo temporales no críticas.

### Solo verificación (nuevo · 1.9.0)

**No copia nada.** MisiCopy calcula el checksum de cada archivo origen, luego el de la copia **ya presente** en el destino, y compara. No escribe **estrictamente nada** en los discos — ni siquiera un informe. Si quieres un registro, exporta el informe (MHL, CSV, registro) vía el menú **Archivo** tras la verificación.

Casos de uso típicos:
- Descargaste una tarjeta en **Copia rápida** en un rodaje con prisas, y quieres verificar la integridad por la noche, con calma
- Dudas sobre un disco de backup: re-verifica un día entero de brutos sin volver a copiar
- Control de calidad antes de borrar las tarjetas: la prueba de que cada byte en destino coincide con el origen

Selecciona la tarjeta origen y el disco destino: MisiCopy **encuentra la copia por sí solo**, aunque se hiciera otro día, en otra carpeta REEL o con ajustes distintos (explora todas las disposiciones plausibles — fechas, cámaras, REELs, con o sin carpeta de tarjeta). El botón principal muestra entonces **Iniciar verificación**. Un archivo ausente o alterado en destino aparece como error, con la ruta completa buscada en el registro.

## Los algoritmos de checksum

En **Opciones → Algoritmo** (o en **Ajustes → General**), seis opciones.

- **xxHash3 (64-bit)** — por defecto. El más rápido en Apple Silicon, estándar de la industria desde 2024.
- **xxHash3 (128-bit)** — mismo algoritmo pero firma de 128 bits. Ligeramente más lento.
- **xxHash64** — versión anterior. Solo para compatibilidad con MHL antiguos de ShotPut Pro 2022 y anterior.
- **MD5** — universal. Mucho más lento (8-10x más lento que xxHash3). Úsalo si tu estudio exige MD5.
- **SHA-1** — heredado, evítalo salvo petición.
- **SHA-256** — criptográfico, el más lento. Para requisitos regulatorios.

**Recomendación**: quédate en xxHash3 (64-bit) salvo petición explícita del cliente final.

## Añadir un origen

Un "origen" es de dónde copias: una tarjeta SD, un disco externo, una carpeta. Tres métodos.

**Método 1 — Arrastrar y soltar**: abre el Finder, navega a tu tarjeta o carpeta, arrástrala a la zona **Origen** de MisiCopy.

**Método 2 — Botón + (Elegir)**: haz clic en el botón **+** junto al título ORIGEN. Se abre el selector de archivos de macOS. Navega a tu tarjeta y haz clic en **Seleccionar**.

**Método 3 — Banda de auto-detección**: cuando conectas una tarjeta o disco externo, aparece automáticamente una banda naranja « Tarjeta detectada — NOMBRE ». Haz clic en **Añadir como origen** para usarla.

**Orígenes múltiples**: puedes añadir tantos orígenes como quieras. MisiCopy los procesa secuencialmente, agrupando archivos en subcarpetas con el nombre de cada origen.

## Añadir destinos

Un "destino" es una carpeta donde se copiarán los archivos. Múltiples destinos son posibles — MisiCopy copia en paralelo a cada uno y verifica cada uno independientemente.

Métodos idénticos a los orígenes: arrastrar y soltar o botón +.

**Bueno saber**: los volúmenes Time Machine se excluyen automáticamente de la detección.

## Destinos en cascada (nuevo · 1.10.0)

El problema clásico: copias hacia un SSD rápido Y un gran disco duro de archivo. Sin cascada, toda la copia avanza a la velocidad del disco más lento, y la tarjeta queda ocupada durante horas.

**La solución**: haz clic en el botón **↳** del destino lento — pasa a modo **CASCADA**. Ya no se copia desde la tarjeta, sino **desde el primer destino directo**, una vez verificada la copia principal.

1. **Fase 1** — tarjeta → solo destinos directos, a plena velocidad
2. **La tarjeta queda libre** en cuanto la fase 1 está verificada (y se expulsa automáticamente si Auto eject está activo) — conecta la siguiente tarjeta
3. **Fase 2** — el primer destino directo alimenta las cascadas, con verificación checksum completa contra la huella original de la tarjeta

**Indicadores de velocidad**: al añadir un destino, MisiCopy mide su velocidad de escritura (sonda de ~1 segundo, memorizada por disco). Las insignias te guían: **⚡ cian** = el disco más rápido (mantenlo directo), **🐢 gris** = claramente más lento (el candidato ideal a la cascada). Haz clic en la insignia para volver a medir.

A saber: conserva al menos un destino directo (una alerta te avisará si no); una cascada interrumpida se relanza sin volver a copiarlo todo; los checksums de cascada figuran en los informes PDF y MHL.

## Salvaguardas inteligentes (nuevo · 1.11.0)

**Comprobación previa de espacio** — Al iniciar, tras la indexación, MisiCopy comprueba que cada destino (directos Y cascadas) puede recibir el volumen completo. Si no cabe, la copia se rechaza ANTES del primer byte, con un mensaje preciso: « La copia necesita 128 GB pero "JUDGEMENT" solo tiene 90 GB libres (faltan 38 GB) ». Se acabó descubrir el disco lleno al 80 % de la copia.

**Memoria de tarjetas** — MisiCopy reconoce una tarjeta ya descargada con éxito (vía el historial de sesiones). Al reconectarla, sin auto-inicio: aparece un banner dedicado — « "A001_0719" ya descargada el 19/07 a las 21:32 — 48 archivos, 61 GB » — con tres opciones: **Re-verificar** (lo seguro, pasa al modo Solo verificación), **Recopiar** o **Ignorar**. Se acabaron las descargas dobles… y sobre todo, formatear una tarjeta que creías descargada.

**Contador del día** — En la cabecera, una píldora resume tu jornada: « Hoy: 8 tarjetas · 1,2 TB · 0 errores ». Ideal para el balance de fin de día con producción.

## El modo rodaje: copia 100% automática

LA función que cambia todo en rodaje. Cuatro botones bajo la sección de modo de copia:

**Vigilancia** (botón naranja izquierda)
Cada tarjeta o disco que conectes se añade automáticamente como origen. La detección también funciona con soportes profesionales que no exponen la marca «extraíble» — **ARRI Codex / Codex Capture Drive**, Sony XDCAM, RED Mag, Panasonic AVCHD: MisiCopy reconoce su estructura de carpetas característica (`Codex/`, `Clips/`, `OCN/`, `XDROOT/`, `PRIVATE/`, `Footage/`…).

**Auto-inicio** (botón índigo centro)
Si está activo además de Vigilancia, en cuanto se añade un origen y hay un destino configurado, la copia arranca sola.

**Auto eject** (botón azul)
Al final de cada copia correcta, MisiCopy expulsa automáticamente la tarjeta origen.

**Duplicados** (botón turquesa derecha · nuevo · 1.9.0)
Antes de cada copia, MisiCopy comprueba si el archivo ya existe en destino **con el mismo checksum**. Si es así, lo salta — práctico para relanzar un trabajo sin volver a copiarlo todo. (Es la misma opción que **Opciones → Detección de duplicados**, ahora a un clic.)

**Flujo de rodaje típico**: a primera hora configuras Bay1 y Bay2 como destinos. Activas los 3 botones. El DIT te pasa una tarjeta, la conectas, la dejas. MisiCopy trabaja. Cuando se expulsa (luz verde), la guardas. Cero interacción durante el día.

## Estructura DIT (árbol automático)

Para flujos profesionales (DIT en rodaje, archivo de largometraje), MisiCopy crea **automáticamente** la estructura de carpetas estándar en cada destino en lugar de copiar los archivos planos.

**Activación**: sección **Estructura DIT** en la parte superior de la columna derecha → interruptor **Activar estructura DIT** + campo **Nombre del proyecto** (ej: `FILM_X_2026`).

**Árbol generado** (nombres por defecto, todos personalizables en **Ajustes → Estructura DIT**):

```
FILM_X_2026/
├── 00_INFOS/                    ← informe DIT generado aquí
│   └── rapport_DIT_070626.pdf
├── 01_RUSHES/                   ← los rushes van aquí
│   └── 070626/                  ← fecha del día (DDMMAA)
│       ├── A_CAM/
│       │   └── A001_xxxx/       ← nombre de la tarjeta
│       ├── B_CAM/
│       └── SON/
├── 02_MHL/                      ← MHL exportado aquí
│   └── 070626_A001_xxxx.mhl
├── 03_PROXY/
│   └── 070626/
└── 04_LUT/
```

**Detección automática de cámara**: MisiCopy lee el nombre del primer clip de cada fuente. Si empieza por `A001_`, `B001_`, etc. (convención ARRI/RED/Sony), la tarjeta va a la carpeta `*_CAM/` correcta. También puedes elegir manualmente con el menú desplegable junto a cada fuente: **A**, **B**, **C**, **D**, **SON** o **AUTRE**.

**Subcarpeta REEL por descarga (nuevo · 1.6.0)**: interruptor opcional que reemplaza el nombre de la tarjeta por un contador `REEL_001`, `REEL_002`… numerado **por cámara** en todo el proyecto. Útil para DITs de rodaje que rastrean magazines/rolls independientemente del nombre nativo de las tarjetas.

```
FILM_X_2026/
└── 01_RUSHES/070626/
    ├── A_CAM/
    │   ├── REEL_001/             ← 1ª descarga A_CAM
    │   └── REEL_002/             ← 2ª descarga A_CAM
    ├── B_CAM/
    │   └── REEL_001/             ← 1ª descarga B_CAM (contador independiente)
    └── SON/
        └── REEL_001/
```

El contador se guarda en un archivo oculto `.misicopy-project.json` en la raíz del proyecto y sigue incrementándose hasta el final del proyecto (sobrevive a reinicios de la app). Si **cancelas** una copia en curso, el número REEL NO se confirma: relanza el mismo dump y reutilizará el mismo `REEL_NNN`.

**Personalizar la estructura**: abre **Ajustes → Estructura DIT**. Puedes:
- Renombrar cada carpeta estándar
- Cambiar el prefijo del informe
- **Añadir carpetas adicionales** vacías a la raíz del proyecto (ej: `05_EDIT`, `06_DELIVERABLES`)
- Botón **Restablecer valores predeterminados**

Todas las personalizaciones se guardan y restauran al reiniciar.

## Las opciones de copia

Menú **Opciones** — nueve interruptores.

- **Simulación**: corre el pipeline completo pero no escribe NADA al disco. Para testear sin riesgo.
- **Conservar estructura**: replica el árbol de carpetas origen.
- **Expulsar tras copia**: equivalente al botón **Auto eject**.
- **Notificación del sistema**: notificación macOS al final de cada copia.
- **Omitir archivos del sistema**: ignora `.DS_Store`, `.Spotlight-V100`, etc.
- **Organizar por fecha**: crea subcarpeta `2026-06-04/` automáticamente.
- **Miniaturas en PDF**: incluye/excluye miniaturas de vídeo del informe.
- **Detección de duplicados**: salta archivos ya presentes con mismo checksum.

## Renombrado con tokens

Caso de uso: quieres entregar al montador archivos llamados `2026-06-04_RODAJE_001.mxf` en lugar de `A001C001_240604_R1CV.mxf`.

En **Ajustes → Renombrado**, introduce un patrón con tokens. Ejemplo: `{date}_RODAJE_{counter:04}.{ext}`

Tokens: `{filename}` `{ext}` `{source}` `{camera}` `{date}` `{time}` `{year}` `{month}` `{day}` `{hour}` `{minute}` `{second}` `{counter}` `{counter:NN}`

Vista previa en vivo bajo el campo te muestra el resultado.

## Los filtros de extensiones

En **Ajustes → Filtros**, dos campos.

**Incluir (whitelist)**: solo se copian estos archivos. Ej.: `mxf, mov, wav, r3d`.

**Excluir (blacklist)**: estos siempre se ignoran. Ej.: `xmp, log, thm`.

Pueden combinarse. Separadores: coma, espacio, punto y coma. El punto inicial es opcional.

## El límite de ancho de banda

Menú **Opciones → Límite de ancho** ofrece seis valores: Ilimitado, 10, 25, 50, 100, 250 MB/s. Útil en NAS compartido para no saturar la red.

**Límite global (nuevo · 1.9.0)**: si copias varias tarjetas en paralelo (ver «Copia multi-tarjeta en paralelo»), el límite se aplica al **total** — dos tarjetas con un límite de 100 MB/s se reparten los 100 MB/s, no los acumulan.

## Copia multi-tarjeta en paralelo (nuevo · 1.9.0)

Por defecto, MisiCopy procesa los orígenes uno tras otro. En una estación de descarga con varios lectores y un SSD/NVMe rápido como destino, puedes copiar **todas las tarjetas a la vez**.

**Activación**: **Ajustes → Avanzado → Copiar orígenes en paralelo**.

Cada tarjeta origen obtiene su propio flujo de copia Y verificación: tres tarjetas conectadas = tres flujos simultáneos hacia tus destinos. Las estadísticas y la barra de progreso agregan el conjunto.

**¿Cuándo activarlo?** Solo cuando el destino es un SSD/NVMe. En un disco duro mecánico, las escrituras entrelazadas de varias tarjetas hacen que el cabezal vaya y venga, y la copia secuencial sigue siendo más rápida. Regla simple: destino mecánico → secuencial, destino SSD → paralelo.

## La cola

Caso de uso: tienes 3 tarjetas SD a copiar en serie, sin esperar a que termine cada una.

1. Conecta tarjeta 1, configura destinos, haz clic en **Iniciar copia segura**
2. Mientras corre, conecta tarjeta 2 y configura sus orígenes
3. Haz clic en **+ Añadir a la cola**
4. Lo mismo para tarjeta 3

Cuando termina la 1, la 2 arranca automáticamente con su config.

**Importante**: cada trabajo en cola conserva su propio snapshot de configuración.

**Prioridades (nuevo · 1.9.0)**: cada trabajo en cola muestra flechas **↑ / ↓** para subirlo o bajarlo. El trabajo en cabeza de la lista arranca primero.

## Pausa y reanudar

Durante una copia, junto al botón **Cancelar**, aparece un botón **Pausar** (amarillo). Suspende la copia entre dos archivos.

El botón se vuelve verde con texto **Reanudar**. Continúa donde estabas.

Atajo: **⌘ P**.

## La verdadera reanudación tras interrupción (nuevo · 1.9.0)

La pausa suspende la copia mientras la app funciona. Pero ¿y si debes parar **de verdad** — salir de la app, apagar el Mac? Durante una copia el botón grande se convierte en **Interrumpir la copia — X %** (con un recordatorio bajo la barra: el progreso se conserva).

MisiCopy memoriza ahora, **archivo por archivo**, todo lo ya copiado Y verificado (guardado en disco cada 2 segundos durante la copia). En concreto:

- **Interrumpes** una copia al 70 % → el registro muestra «Progreso guardado» → en el próximo **Iniciar**, MisiCopy salta los archivos ya asegurados y continúa donde se detuvo, **en las mismas carpetas** (misma fecha, mismo REEL) — registro: «⏩ N archivo(s) ya asegurado(s) — omitidos»
- La app **falla** o el Mac se apaga en plena copia → al siguiente arranque, la banda violeta «Sesión anterior detectada» restaura la configuración Y el progreso
- Salvaguarda: un archivo solo se salta si cada destino contiene aún una copia **del mismo tamaño** — si no, se vuelve a copiar. Ante la duda, el modo **Solo verificación** confirma la integridad byte a byte.

Una copia completada borra esta memoria de reanudación: el próximo Iniciar empieza de cero, como cabe esperar.

## Los informes automáticos

Al final de cada copia, un **cuadro de diálogo** resume el resultado (archivos verificados, volumen, duración — desactivable en Ajustes → General), y MisiCopy genera **automáticamente** un **informe PDF** en la raíz de cada destino, con cabecera de marca, listing de orígenes/destinos, estadísticas, miniaturas de clips, y tabla completa de archivos con checksums y estado.

**Agrupación por plano**: al copiar una secuencia de imágenes (DPX, EXR, ARRIRAW, CinemaDNG, etc. — un archivo por frame), MisiCopy agrupa automáticamente las frames del mismo plano. El PDF muestra **una sola miniatura** y **una sola línea «verificado»** por secuencia (con el número de frames, por ejemplo `shot01_####.dpx — 500 frames`) en lugar de una línea por frame.

También puedes exportar:
- **MHL v1** (`⌘ E`)
- **ASCMHL v2** (`⌘ ⇧ E`)
- **CSV** — para hojas de cálculo
- **HTML** — página web autónoma
- **Registro .txt** (`⌘ ⇧ L`)

## Verificar un MHL existente

Caso de uso: un cliente te pide verificar que un archivo entregado hace 2 años sigue intacto.

1. Menú **Archivo → Verificar MHL…** (`⌘ ⇧ V`)
2. Selecciona el archivo `.mhl`
3. Selecciona la carpeta con los archivos
4. MisiCopy recalcula y compara cada checksum

Al final, sabes si el archivo está sano o si hay bit-rot.

## Los perfiles

**Guardar**: Menú **Perfiles → Guardar perfil actual…**.

**Aplicar**: Menú **Perfiles → [Nombre]**.

**Gestionar**: Menú **Perfiles → Gestionar perfiles…**.

Un perfil captura: modo, algoritmo, estructura, auto-expulsión, notificaciones, omitir archivos sistema, organizar por fecha.

## El historial

Menú **Archivo → Historial…** (`⌘ Y`)

Últimas 500 sesiones con sus estadísticas, duración, formatos. Útil para auditoría y reconstitución de parámetros.

## Webhooks

En **Ajustes → Integraciones**:

**Slack URL**: pega un Incoming Webhook. Al final de cada copia, mensaje en el canal.

**Webhook genérico**: URL aceptando POST JSON. Compatible con Zapier, Make.com, n8n.

## Prueba de velocidad de disco

Menú **Tarea → Prueba velocidad → [destino]**

MisiCopy escribe 100 MB y los relee para medir el rendimiento real:
`bay1 — escritura 540 MB/s, lectura 720 MB/s`

Compara con las especificaciones de tu disco.

## Reanudar sesión

Si MisiCopy se cierra inesperadamente, al siguiente arranque aparece una banda violeta « Sesión anterior detectada ». Haz clic en **Reanudar** para restaurar la configuración **y el progreso archivo por archivo** (ver «La verdadera reanudación tras interrupción») — los archivos ya asegurados se saltan.

## La aplicación iPhone (MisiCopy Remote)

MisiCopy Remote es una app de iPhone gratuita para **seguir tus copias a distancia**, sin quedarte frente al Mac. Ideal en rodaje: lanzas la descarga, guardas el material y vigilas el progreso desde el bolsillo.

**Activar en el Mac**: **Ajustes → iPhone** → activa **Seguimiento iPhone**. Aparece un código QR de emparejamiento.

**Emparejar el iPhone**: abre MisiCopy Remote → **Escanear** → apunta al código QR del Mac. El emparejamiento es seguro (clave cifrada, nunca enviada en claro) y solo se hace una vez.

**Lo que ves en directo en el iPhone:**
- El progreso (anillo %, velocidad, tiempo restante, archivo en curso)
- Los contadores: encontrados, copiados, verificados, errores
- El registro de actividad en tiempo real
- **El espacio libre de cada destino** (barra verde / naranja / roja)
- **La fase cascada**: insignia « Cascada — tarjetas liberadas ✅ » en cuanto la copia principal está verificada — sabes desde el bolsillo que la tarjeta puede retirarse

**Controlar desde el iPhone:**
- **Pausar / Reanudar / Cancelar** la copia en curso
- **Volver a copiar los archivos con error**: si una copia termina con errores de suma de comprobación, relanza solo los archivos afectados desde el teléfono

**Seguimiento en la pantalla bloqueada (Live Activity · rediseñado en 1.2.0)**: durante una copia, aparece un mosaico en la pantalla bloqueada y en la Dynamic Island. Se **actualiza en tiempo real incluso con el iPhone en reposo** — ves avanzar el progreso sin desbloquear. El mosaico muestra el porcentaje en grande, la velocidad en MB/s y el tiempo restante sobre un fondo oscuro contrastado para legibilidad a distancia. Al terminar, una **notificación** te avisa (éxito o error), incluso con la app en segundo plano o la pantalla bloqueada — la notificación atraviesa el modo No molestar (interrupción urgente).

**Dos canales de conexión:**
- **Wi-Fi local** (recomendado): Mac e iPhone en la misma red — latencia casi nula, ningún dato sale de la red.
- **iCloud** (respaldo): cuando no estás en la misma Wi-Fi, el iPhone lee el estado vía tu iCloud privado. El seguimiento en pantalla bloqueada en tiempo real sigue funcionando mediante notificaciones push, estés donde estés.

## Los idiomas

Menú **Idioma**: Français, English, Español. Cambio instantáneo en toda la interfaz.

## Atajos de teclado

| Atajo | Acción |
|---|---|
| ⌘ R | Iniciar / Cancelar |
| ⌘ P | Pausar / Reanudar |
| ⌘ ⇧ A | Añadir a la cola |
| ⌘ E | Exportar MHL v1 |
| ⌘ ⇧ E | Exportar ASCMHL v2 |
| ⌘ ⇧ V | Verificar MHL |
| ⌘ ⇧ L | Exportar registro |
| ⌘ Y | Historial |
| ⌘ , | Ajustes |

## Preguntas frecuentes

**« Tarjeta no detectada » en macOS Sequoia o más reciente**
macOS 15+ introdujo una nueva permisión TCC. Ve a **Ajustes del sistema → Privacidad y seguridad → Archivos y carpetas → MisiCopy**, y activa **Volúmenes extraíbles**.

**¿Cómo paso mi licencia a otro Mac?**
En el Mac antiguo: Ajustes → Licencia → **Desactivar en este equipo**. En el nuevo: instala la app, abre Ajustes → Licencia, pega la misma clave.

**He perdido mi clave**
Busca en tu email el envío de Payhip post-compra. Si no la encuentras, escribe a misicopy@misiraca.com.

**¿xxHash3 o xxHash64?**
En uso solitario, xxHash3 (64-bit) es más rápido. Si intercambias MHL con un estudio antiguo, pregúntales qué algoritmo esperan.

**¿La cola se detiene si un trabajo falla?**
No. MisiCopy procesa todos los trabajos secuencialmente. Si un archivo falla, el trabajo continúa con el resto. Si todo un trabajo falla, el siguiente arranca igualmente.

**¿Cuántos destinos puedo tener a la vez?**
Sin límite hardcodeado. Siete u ocho destinos paralelos son perfectamente manejables.

## Soporte

Para cualquier duda o problema, escribe a **misicopy@misiraca.com**. Respondo en 24h.

Sitio: **www.misicopy.com**

---

*MisiCopy © 2026 Matthieu Misiraca. Bons tournages · Happy shoots · Buenos rodajes.*
