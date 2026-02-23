# Basics - Outils de base

---

## Connexion & Réseau

```bash
# Connexion VPN (HTB)
sudo openvpn user.ovpn

# Vérifier notre IP
ip a
ifconfig

# Voir les réseaux accessibles via VPN
netstat -rn
ip route

# SSH
ssh user@TARGET_IP
ssh user@TARGET_IP -i id_rsa          # avec clé privée
ssh -p 2222 user@TARGET_IP            # port custom

# FTP
ftp TARGET_IP
```

---

## tmux

```bash
# Lancer tmux
tmux
tmux new -s session_name              # session nommée
tmux attach -t session_name           # rattacher une session
tmux ls                               # lister les sessions
```

### Raccourcis (prefix = Ctrl+b)

| Raccourci | Action |
|-----------|--------|
| `prefix c` | Nouvelle fenêtre |
| `prefix ,` | Renommer fenêtre |
| `prefix n` / `prefix p` | Fenêtre suivante / précédente |
| `prefix 0-9` | Aller à la fenêtre N |
| `prefix %` | Split vertical |
| `prefix "` | Split horizontal |
| `prefix →←↑↓` | Naviguer entre panes |
| `prefix z` | Zoom/dézoom un pane |
| `prefix d` | Détacher la session |
| `prefix x` | Fermer le pane courant |
| `prefix [` | Mode scroll (q pour quitter) |

---

## Vim

```bash
vim file
```

### Modes

| Touche | Mode |
|--------|------|
| `i` | Insert (avant curseur) |
| `a` | Insert (après curseur) |
| `o` | Insert (nouvelle ligne dessous) |
| `Esc` | Retour mode Normal |
| `v` | Mode Visual |
| `V` | Mode Visual Line |

### Commandes essentielles (mode Normal)

| Commande | Action |
|----------|--------|
| `x` | Supprimer caractère |
| `dw` | Supprimer mot |
| `dd` | Supprimer ligne |
| `yw` | Copier mot |
| `yy` | Copier ligne |
| `p` | Coller après |
| `P` | Coller avant |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `/pattern` | Rechercher |
| `n` / `N` | Résultat suivant / précédent |
| `gg` | Début du fichier |
| `G` | Fin du fichier |
| `:N` | Aller à la ligne N |

### Sauvegarder / Quitter

| Commande | Action |
|----------|--------|
| `:w` | Sauvegarder |
| `:q` | Quitter |
| `:q!` | Quitter sans sauvegarder |
| `:wq` | Sauvegarder et quitter |
| `:x` | Sauvegarder et quitter (idem) |
