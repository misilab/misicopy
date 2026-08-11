# MisiCopy — Workflow de release

Système de mises à jour automatiques basé sur **Sparkle 2** + **GitHub Releases**.

## URLs

- **Appcast** : https://raw.githubusercontent.com/misilab/misicopy/main/appcast.xml
- **DMG** : https://github.com/misilab/misicopy/releases/download/v{VERSION}/MisiCopy-{VERSION}.dmg
- **Clé publique EdDSA** : `bxP11zE5Pla4VRO1J3UhVM3TRD4WUFdkKNDPWFWjU/I=` (déjà dans Info.plist)
- **Clé privée EdDSA** : Keychain macOS (entrée `ed25519` / Sparkle) — **ne jamais partager**

## Pour publier une nouvelle version

### 1. Bumper la version dans Xcode
- Projet **MisiCopy** → cible → onglet **General**
- Section **Identity** → **Version** : ex. `1.0.3`

### 2. Lancer le pipeline
```bash
bash scripts/release.sh
```
Produit dans `build/` :
- `MisiCopy-1.0.3.dmg` (signé Developer ID + notarisé Apple + signé Sparkle)
- `appcast-entry.xml` (snippet à insérer dans l'appcast)

### 3. Mettre à jour `marketing/appcast.xml`
- Ouvrir `marketing/appcast.xml`
- Coller le contenu de `build/appcast-entry.xml` **juste après** `<language>fr</language>`, **au-dessus** de l'entrée précédente (ordre = plus récent en haut)
- Remplacer le `TODO` dans `<description>` par les vraies notes de version (HTML, ex: `<ul><li>Fix X</li><li>Add Y</li></ul>`)

### 4. Pousser l'appcast sur GitHub
Via l'interface web :
- https://github.com/misilab/misicopy/blob/main/appcast.xml
- Clique le crayon (Edit)
- Colle le contenu mis à jour
- **Commit changes**

### 5. Créer la Release GitHub
- https://github.com/misilab/misicopy/releases/new
- **Tag** : `v1.0.3`
- **Title** : `MisiCopy 1.0.3`
- **Description** : copie les bullet points
- **Attach binary** : `build/MisiCopy-1.0.3.dmg`
- **Publish release**

### 6. C'est fait
Les utilisateurs verront la MAJ proposée dans les 24h (Sparkle vérifie quotidiennement).
Ils peuvent aussi forcer via le menu **MisiCopy → Vérifier les mises à jour…**

## Vérifier qu'une release est bien en ligne

```bash
# Appcast accessible ?
curl -sIL https://raw.githubusercontent.com/misilab/misicopy/main/appcast.xml | head -1

# DMG accessible et bonne taille ?
curl -sIL https://github.com/misilab/misicopy/releases/download/v1.0.3/MisiCopy-1.0.3.dmg | grep content-length
```

La taille `content-length` doit matcher la valeur `length="..."` dans l'appcast (sinon Sparkle refusera l'install).

## Sauvegarde de la clé privée EdDSA

La clé privée est dans le Keychain. Pour la sauvegarder (utile si tu changes de Mac) :

```bash
# Trouve l'outil
find ~/Library/Developer/Xcode/DerivedData -name generate_keys -type f | head -1

# Export
/path/to/generate_keys -x ~/Desktop/misicopy-sparkle-private.key
# Garde ce fichier en LIEU SÛR (1Password, coffre, etc.) — pas dans le repo
```

Sur un nouveau Mac :
```bash
/path/to/generate_keys -f ~/Desktop/misicopy-sparkle-private.key
```
