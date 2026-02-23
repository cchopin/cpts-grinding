# Outils de base

[<< Retour](README.md) | [Suivant : Enumeration de services >>](02-enumeration-services.md)

---

## SSH

Protocole sur le port 22 - acces distant securise. Sert de "jump host" pour pivoter, transferer des outils, poser de la persistence.

```bash
ssh user@TARGET_IP                    # connexion basique
ssh user@TARGET_IP -p 2222            # port custom
ssh user@TARGET_IP -i id_rsa          # avec cle privee
```

---

## Netcat

Utilitaire reseau pour interagir avec les ports TCP/UDP. Usages principaux : banner grabbing, reverse/bind shells, transfert de fichiers.

```bash
nc -nv TARGET_IP 22                   # banner grabbing
nc -lvnp 4444                         # listener (reverse shell)
```

Flags a retenir :
- `-l` : mode ecoute (listen)
- `-v` : verbose
- `-n` : pas de resolution DNS (plus rapide)
- `-p` : port d'ecoute

**Socat** : alternative a netcat avec plus de fonctionnalites (forwarding, TTY complet). Un binaire standalone peut etre transfere sur la cible.

---

## tmux

Multiplexeur de terminal - essentiel pour gerer plusieurs taches en parallele pendant un pentest (listener + enumeration + exploit).

Raccourcis de base (prefixe `Ctrl+B`) :

| Raccourci | Action |
|-----------|--------|
| `c` | Nouvelle fenetre |
| `1`, `2`, ... | Changer de fenetre |
| `%` | Split vertical |
| `"` | Split horizontal |
| fleches | Naviguer entre les panes |

---

## Vim

Editeur clavier-only, souvent le seul disponible sur un systeme compromis.

Minimum a connaitre :
- `i` : mode insertion
- `Esc` : retour mode normal
- `:wq` : sauver et quitter
- `:q!` : quitter sans sauver
- `dd` : supprimer la ligne
- `yy` / `p` : copier / coller une ligne

> Voir [cheatsheet basics](../../../cheatsheets/basics.md) pour les raccourcis complets.
