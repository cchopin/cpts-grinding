# Methodologie Pentest

> Checklist a suivre sur chaque box / engagement

---

## Phase 1 : Reconnaissance

- [ ] **Nmap** : scan complet TCP (`-sC -sV -p-`)
- [ ] **Nmap** : scan UDP top 50 (`-sU --top-ports 50`)
- [ ] **Ajouter** le hostname dans `/etc/hosts` si besoin
- [ ] **Identifier** l'OS et la version (TTL, banniere, nmap)
- [ ] **Noter** tous les ports ouverts et services

---

## Phase 2 : Enumeration

### Par service
- [ ] **Web (80/443)** : whatweb, ffuf (dirs + fichiers + vhosts), nikto, code source
- [ ] **SMB (445)** : enum shares, users, politique de password
- [ ] **FTP (21)** : anonymous login, fichiers accessibles
- [ ] **SSH (22)** : version (vulns connues), brute force si users connus
- [ ] **DNS (53)** : zone transfer, enum sous-domaines
- [ ] **LDAP (389)** : enum anonyme, users, groupes
- [ ] **SNMP (161)** : community strings, enum
- [ ] **MSSQL (1433)** : login, xp_cmdshell
- [ ] **WinRM (5985)** : evil-winrm si creds

### Web specifique
- [ ] **Technos** : langage, framework, CMS, version
- [ ] **Login pages** : creds par defaut, brute force, SQLi
- [ ] **Input fields** : SQLi, XSS, command injection, SSTI
- [ ] **Upload** : tester bypass d'extension et de content-type
- [ ] **LFI/RFI** : traversal, wrappers PHP, log poisoning
- [ ] **API** : endpoints, documentation, parametres caches

---

## Phase 3 : Exploitation

- [ ] **Chercher** les exploits connus (searchsploit, Google, CVE)
- [ ] **Tester** les creds par defaut
- [ ] **Obtenir** un shell (reverse shell / web shell / bind shell)
- [ ] **Stabiliser** le shell (pty, stty)
- [ ] **Recuperer** le flag user

---

## Phase 4 : Post-Exploitation

### Enumeration locale
- [ ] `whoami /all` ou `id`
- [ ] Fichiers sensibles (configs, cles SSH, credentials)
- [ ] Processus en cours / services internes
- [ ] Connexions reseau internes (`netstat -tlnp`)
- [ ] Taches planifiees (cron / scheduled tasks)
- [ ] LinPEAS / WinPEAS

### Privilege Escalation Linux
- [ ] `sudo -l`
- [ ] SUID/SGID binaries (`find / -perm -4000 2>/dev/null`)
- [ ] Capabilities (`getcap -r / 2>/dev/null`)
- [ ] Cron jobs writables
- [ ] Kernel exploits
- [ ] Fichiers writables dans PATH
- [ ] Docker / LXC group

### Privilege Escalation Windows
- [ ] `whoami /priv` (SeImpersonate, SeBackup, etc.)
- [ ] Services mal configures (unquoted paths, writable dirs)
- [ ] AlwaysInstallElevated
- [ ] Stored credentials (`cmdkey /list`)
- [ ] SAM / SYSTEM / SECURITY dumps
- [ ] Token impersonation (Potato attacks)
- [ ] Kernel exploits (`systeminfo`)

---

## Phase 5 : Active Directory (si applicable)

- [ ] **Enum** : BloodHound, ldapsearch, crackmapexec
- [ ] **Users** : AS-REP Roastable, Kerberoastable
- [ ] **Shares** : fichiers sensibles, scripts, GPP
- [ ] **Delegation** : constrained, unconstrained, RBCD
- [ ] **Creds** : spray, relay, dump NTDS
- [ ] **Lateral movement** : psexec, wmiexec, evil-winrm, RDP
- [ ] **Domain admin** : DCSync, Golden Ticket, Silver Ticket

---

## Phase 6 : Pivoting (si multi-network)

- [ ] **Identifier** les interfaces reseau supplementaires
- [ ] **Scanner** le reseau interne
- [ ] **Tunnel** : chisel, ligolo-ng, SSH, proxychains
- [ ] **Repeter** les phases 1-5 sur les nouvelles cibles

---

## Phase 7 : Loot & Documentation

- [ ] **Flags** : user.txt, root.txt
- [ ] **Screenshots** des etapes cles
- [ ] **Noter** le chemin d'attaque complet
- [ ] **Lecons apprises** : ce qui a marche, ce qui a bloque
- [ ] **Commit** la writeup dans le repo
