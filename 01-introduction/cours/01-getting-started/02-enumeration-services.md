# Énumération de services

[<< Précédent : Outils de base](01-outils-de-base.md) | [Suivant : Énumération web >>](03-enumeration-web.md)

---

## Nmap - les scans essentiels

```bash
# Scan rapide (top 1000 ports, versions + scripts par défaut)
nmap -sV -sC TARGET_IP

# Scan complet tous les ports
nmap -sV -sC -p- TARGET_IP

# Scan initial + sauvegarde de tous les formats de sortie
nmap -sV --open -oA scan_initial TARGET_IP

# Script spécifique
nmap --script smb-os-discovery.nse -p445 TARGET_IP

# Énumération HTTP
nmap -sV --script=http-enum TARGET_IP
```

**Points clés :**
- Sans option, nmap scanne les 1000 ports TCP les plus courants
- `-sC` : scripts par défaut (info supplémentaire, plus lent)
- `-sV` : fingerprint des services (version)
- `-p-` : tous les 65535 ports
- `-oA` : sauvegarde en XML, greppable et texte (toujours le faire)
- La version d'un service peut révéler l'OS (ex: `OpenSSH 7.2p2 Ubuntu 4ubuntu2.8` = Ubuntu Xenial)
- Lancer le scan complet `-p-` en arrière-plan pendant l'énumération manuelle

---

## Banner Grabbing

Technique pour identifier rapidement un service en récupérant sa bannière.

```bash
nc -nv TARGET_IP 22                   # bannière SSH
nc -nv TARGET_IP 80                   # bannière HTTP
nmap -sV --script=banner -p21 TARGET_IP
```

---

## FTP (port 21)

```bash
ftp -p TARGET_IP
# Tester le login anonyme : anonymous / (vide)
# Commandes : ls, cd, get, put
```

Toujours vérifier si le login anonyme est activé (`ftp-anon` dans les scripts nmap).

---

## SMB (port 445)

```bash
smbclient -N -L \\\\TARGET_IP        # lister les shares (anonyme)
smbclient -U user \\\\TARGET_IP\\share  # connexion avec creds
```

Le script nmap `smb-os-discovery.nse` révèle l'OS, le hostname, le workgroup. Vulnérabilités connues : EternalBlue (MS17-010) sur les vieux Windows.

---

## SNMP (port 161)

```bash
snmpwalk -v 2c -c public TARGET_IP 1.3.6.1.2.1.1.5.0
onesixtyone -c dict.txt TARGET_IP     # brute force community strings
```

Versions 1 et 2c : community string en clair. Permet d'extraire des infos système (processes, routes, software, parfois des credentials en ligne de commande).
