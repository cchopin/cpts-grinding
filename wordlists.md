# Wordlists

> Principalement depuis [SecLists](https://github.com/danielmiessler/SecLists) (pré-installé sur Kali/Parrot/PwnBox)

---

## Passwords

| Wordlist | Usage | Path |
|----------|-------|------|
| `rockyou.txt` | Brute force passwords (classique) | `/usr/share/wordlists/rockyou.txt` |
| `fasttrack.txt` | Passwords courants (rapide) | `/usr/share/wordlists/fasttrack.txt` |
| `best1050.txt` | Top 1050 passwords | `SecLists/Passwords/Common-Credentials/best1050.txt` |
| `10-million-password-list-top-1000000.txt` | Large brute force | `SecLists/Passwords/Common-Credentials/` |

---

## Usernames

| Wordlist | Usage | Path |
|----------|-------|------|
| `names.txt` | Prénoms courants | `SecLists/Usernames/Names/names.txt` |
| `top-usernames-shortlist.txt` | Top usernames | `SecLists/Usernames/top-usernames-shortlist.txt` |
| `xato-net-10-million-usernames.txt` | Large enum users | `SecLists/Usernames/` |

---

## Web - Directories & Files

| Wordlist | Usage | Path |
|----------|-------|------|
| `directory-list-2.3-medium.txt` | Dir fuzzing (standard) | `SecLists/Discovery/Web-Content/` |
| `directory-list-2.3-small.txt` | Dir fuzzing (rapide) | `SecLists/Discovery/Web-Content/` |
| `big.txt` | Dir fuzzing (large) | `SecLists/Discovery/Web-Content/` |
| `common.txt` | Dir fuzzing (rapide) | `SecLists/Discovery/Web-Content/` |
| `raft-medium-directories.txt` | Bonne alternative | `SecLists/Discovery/Web-Content/` |
| `raft-medium-files.txt` | Fichiers spécifiques | `SecLists/Discovery/Web-Content/` |

---

## Web - Sous-domaines / VHosts

| Wordlist | Usage | Path |
|----------|-------|------|
| `subdomains-top1million-5000.txt` | Vhost fuzzing (rapide) | `SecLists/Discovery/DNS/` |
| `subdomains-top1million-20000.txt` | Vhost fuzzing (medium) | `SecLists/Discovery/DNS/` |
| `subdomains-top1million-110000.txt` | Vhost fuzzing (large) | `SecLists/Discovery/DNS/` |

---

## Web - Extensions

Ajouter avec `-e` (gobuster) ou en suffixe dans ffuf :
```
.php, .html, .txt, .asp, .aspx, .jsp, .bak, .old, .conf, .xml, .json, .yml, .env, .log, .sql, .zip
```

---

## SNMP

| Wordlist | Usage | Path |
|----------|-------|------|
| `snmp.txt` | Community strings | `SecLists/Discovery/SNMP/snmp.txt` |

---

## Custom wordlists

```bash
# CeWL : générer une wordlist depuis un site
cewl http://TARGET_IP -m 5 -w cewl_wordlist.txt

# Username generator depuis noms
username-anarchy -i names.txt > usernames.txt

# Hashcat rules (mutation de passwords)
hashcat --stdout -r /usr/share/hashcat/rules/best64.rule wordlist.txt > mutated.txt

# Crunch (pattern-based)
crunch 8 8 -t @@@@2024 -o custom.txt
```

---

## Où les trouver

- **SecLists** : https://github.com/danielmiessler/SecLists
- **PayloadsAllTheThings** : https://github.com/swisskyrepo/PayloadsAllTheThings
- **FuzzDB** : https://github.com/fuzzdb-project/fuzzdb
- **Kali** : `/usr/share/wordlists/`
