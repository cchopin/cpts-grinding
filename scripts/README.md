# Scripts

Scripts d'automatisation développés au fil des boxes et des cours.

## search.sh - Recherche rapide

Recherche dans toutes les notes et cheatsheets du repo.

```bash
# Mode interactif (nécessite fzf)
./scripts/search.sh

# Recherche par mot-clé
./scripts/search.sh nmap
./scripts/search.sh reverse shell
./scripts/search.sh sudo -l

# Recherche par section (titres uniquement)
./scripts/search.sh -s privilege

# Recherche par nom de fichier
./scripts/search.sh -f transfer
```

> Installer fzf pour le mode interactif : `brew install fzf` ou `apt install fzf`

## Autres scripts

Ajouter ici les scripts d'automatisation, d'énumération, ou tout outil custom créé pendant le grinding.

## Exemples d'idées

- Script d'enum initial (nmap + gobuster + whatweb en une commande)
- Script de génération de reverse shell adapté
- Script d'extraction de credentials depuis des fichiers
- Wrapper autour de ffuf avec les options par défaut
