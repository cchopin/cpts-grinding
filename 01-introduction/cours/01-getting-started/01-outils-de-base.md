# Outils de base

[<< Retour](README.md) | [Suivant : Énumération de services >>](02-enumeration-services.md)

---

## SSH

Protocole sur le port 22 - accès distant sécurisé. Sert de "jump host" pour pivoter, transférer des outils, poser de la persistence.

```bash
ssh user@TARGET_IP                    # connexion basique
ssh user@TARGET_IP -p 2222            # port custom
ssh user@TARGET_IP -i id_rsa          # avec clé privée
```

---

## Netcat

Utilitaire réseau pour interagir avec les ports TCP/UDP. Usages principaux : banner grabbing, reverse/bind shells, transfert de fichiers.

```bash
nc -nv TARGET_IP 22                   # banner grabbing
nc -lvnp 4444                         # listener (reverse shell)
```

Flags à retenir :
- `-l` : mode écoute (listen)
- `-v` : verbose
- `-n` : pas de résolution DNS (plus rapide)
- `-p` : port d'écoute

**Socat** : alternative à netcat avec plus de fonctionnalités (forwarding, TTY complet). Un binaire standalone peut être transféré sur la cible.

---

## tmux

Multiplexeur de terminal - essentiel pour gérer plusieurs tâches en parallèle pendant un pentest (listener + énumération + exploit).

Raccourcis de base (préfixe `Ctrl+B`) :

| Raccourci | Action |
|-----------|--------|
| `c` | Nouvelle fenêtre |
| `1`, `2`, ... | Changer de fenêtre |
| `%` | Split vertical |
| `"` | Split horizontal |
| fleches | Naviguer entre les panes |

---

## Vim

Éditeur clavier-only, souvent le seul disponible sur un système compromis.

Minimum à connaître :
- `i` : mode insertion
- `Esc` : retour mode normal
- `:wq` : sauver et quitter
- `:q!` : quitter sans sauver
- `dd` : supprimer la ligne
- `yy` / `p` : copier / coller une ligne

> Voir [cheatsheet basics](../../../cheatsheets/basics.md) pour les raccourcis complets.
