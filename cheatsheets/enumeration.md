# Énumération

---

## Reconnaissance réseau

```bash
# Scan complet
nmap -sC -sV -p- --min-rate 5000 -oN nmap/full TARGET_IP

# Scan rapide top 1000
nmap -sC -sV TARGET_IP

# UDP
sudo nmap -sU --top-ports 50 TARGET_IP

# Scan réseau (sweep)
nmap -sn 10.10.10.0/24
```

---

## Banner Grabbing

```bash
# Netcat
nc -nv TARGET_IP 21
nc -nv TARGET_IP 22

# Nmap
nmap -sV --script=banner -p21 TARGET_IP
nmap -sV --script=banner -p21 10.10.10.0/24    # sur un range
```

---

## Web

### Énumération de base
```bash
# Technos & headers
whatweb http://TARGET_IP
whatweb --no-errors 10.10.10.0/24               # scan réseau
curl -IL http://TARGET_IP                        # headers HTTP

# Fuzzing directories
ffuf -u http://TARGET_IP/FUZZ -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
gobuster dir -u http://TARGET_IP -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
feroxbuster -u http://TARGET_IP -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt

# Fuzzing fichiers
ffuf -u http://TARGET_IP/FUZZ -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -e .php,.html,.txt,.bak,.old
feroxbuster -u http://TARGET_IP -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -x php,html,txt,bak,old

# Sous-domaines (vhost)
ffuf -u http://TARGET_IP -H "Host: FUZZ.target.htb" -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -fs SIZE_TO_FILTER

# Nikto
nikto -h http://TARGET_IP
```

### Sous-domaines DNS
```bash
gobuster dns -d domain.com -w /usr/share/SecLists/Discovery/DNS/namelist.txt
```

### Sources d'info passives
```bash
# Certificats SSL/TLS -> email, noms, sous-domaines (SAN)
# robots.txt -> répertoires cachés, pages admin
curl http://TARGET_IP/robots.txt

# Code source (Ctrl+U dans Firefox) -> commentaires, credentials de test, chemins internes
```

### CMS
```bash
# WordPress
wpscan --url http://TARGET_IP --enumerate u,vp,vt

# Joomla
joomscan --url http://TARGET_IP

# Drupal
droopescan scan drupal -u http://TARGET_IP
```

---

## SMB (445)

```bash
# Enum shares
smbclient -L //TARGET_IP -N
crackmapexec smb TARGET_IP --shares
smbmap -H TARGET_IP

# Connexion à un share
smbclient //TARGET_IP/share -N
smbclient //TARGET_IP/share -U 'user%password'

# Enum users
crackmapexec smb TARGET_IP --users
rpcclient -U "" -N TARGET_IP
> enumdomusers
> enumdomgroups

# Énumération avec creds
crackmapexec smb TARGET_IP -u user -p password --shares
```

---

## LDAP (389)

```bash
# Énumération anonyme
ldapsearch -x -H ldap://TARGET_IP -b "DC=domain,DC=htb"

# Avec creds
ldapsearch -x -H ldap://TARGET_IP -D "user@domain.htb" -w 'password' -b "DC=domain,DC=htb"

# Énumération users
ldapsearch -x -H ldap://TARGET_IP -b "DC=domain,DC=htb" "(objectClass=user)" sAMAccountName
```

---

## DNS (53)

```bash
# Zone transfer
dig axfr @TARGET_IP domain.htb

# Reverse lookup
dig -x TARGET_IP @TARGET_IP

# Enum sous-domaines
dnsenum --dnsserver TARGET_IP domain.htb
```

---

## SNMP (161)

```bash
# Brute force community strings
onesixtyone -c /usr/share/seclists/Discovery/SNMP/snmp.txt TARGET_IP

# Enum avec community string
snmpwalk -v2c -c public TARGET_IP
snmpwalk -v2c -c public TARGET_IP 1.3.6.1.2.1.25.4.2.1.2  # processes
```

---

## FTP (21)

```bash
# Anonymous login
ftp TARGET_IP
> anonymous / anonymous

# Nmap scripts
nmap --script ftp-anon,ftp-bounce TARGET_IP -p 21
```

---

## Post-exploitation enum

### Linux
```bash
# Basique
id && whoami && hostname
uname -a
cat /etc/os-release
ip a

# Automatisé
./linpeas.sh
./linux-exploit-suggester.sh
```

### Windows
```cmd
whoami /all
systeminfo
ipconfig /all
net user
net localgroup administrators

:: Automatisé
.\winPEASx64.exe
.\Seatbelt.exe -group=all
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```
