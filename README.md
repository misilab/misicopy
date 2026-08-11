# MisiCopy

App macOS de copie sécurisée — vendue 49,90 € sur [payhip.com/b/ITG5N](https://payhip.com/b/ITG5N)

## 🚀 Sortir une nouvelle version

```bash
# 1. Ferme Xcode complètement
# 2. Bumpe la version dans Xcode → Target → Marketing Version
# 3. Lance :
bash scripts/release.sh
```

→ Produit `build/MisiCopy-X.X.dmg` signé + notarisé, prêt à uploader sur Payhip.

## 🔑 Recharger le pool de clés Payhip

Quand il reste moins de 100 clés dans Payhip :

```bash
swift scripts/generate_keys_batch.swift 1000
```

→ Produit `out/keys-1000-<date>.txt`. À uploader dans Payhip → Product → License Keys → Upload.

## ⚠️ À ne JAMAIS toucher

Le secret de licence dans **deux** endroits (doivent rester identiques) :
- `MisiCopy/Models/LicenseStatus.swift` ligne 32
- `scripts/generate_keys_batch.swift` ligne 19

Si tu le changes, toutes les clés vendues deviennent invalides.

## 📁 Dossiers

- `MisiCopy/` — code Swift de l'app
- `scripts/` — outils CLI (release, génération de clés)
- `marketing/` — logo SVG + texte Payhip + template PDF welcome
- `out/` — fichiers générés (non versionné)
- `build/` — DMG finaux (non versionné)

## 📞 Support client

misicopy@misiraca.com
