# Common Ports & Services

---

## Ports essentiels

| Port | Service | Protocole | Notes |
|------|---------|-----------|-------|
| 21 | FTP | TCP | Transfert fichiers. Check anonymous login |
| 22 | SSH | TCP | Shell securise. Brute force / cles |
| 23 | Telnet | TCP | Shell non-chiffre (legacy) |
| 25 | SMTP | TCP | Email. Enum users (VRFY, EXPN) |
| 53 | DNS | TCP/UDP | Zone transfer (AXFR), enum sous-domaines |
| 80 | HTTP | TCP | Web. Toujours scanner |
| 88 | Kerberos | TCP | AD auth. Kerberoasting, AS-REP |
| 110 | POP3 | TCP | Email retrieval |
| 111 | RPCbind | TCP | NFS, enum RPC services |
| 135 | MSRPC | TCP | Windows RPC. Enum via rpcclient |
| 139 | NetBIOS | TCP | Legacy SMB |
| 143 | IMAP | TCP | Email retrieval |
| 161 | SNMP | UDP | Community strings, enum reseau |
| 389 | LDAP | TCP | AD enum. ldapsearch |
| 443 | HTTPS | TCP | Web TLS. Certificats = info |
| 445 | SMB | TCP | Shares, enum, relay, psexec |
| 464 | Kpasswd | TCP | Kerberos password change |
| 593 | HTTP-RPC | TCP | RPC over HTTP |
| 636 | LDAPS | TCP | LDAP over TLS |
| 1433 | MSSQL | TCP | SQL Server. xp_cmdshell |
| 1521 | Oracle | TCP | Oracle DB |
| 2049 | NFS | TCP | Network shares. showmount |
| 3306 | MySQL | TCP | MySQL/MariaDB |
| 3389 | RDP | TCP | Bureau a distance Windows |
| 5432 | PostgreSQL | TCP | PostgreSQL |
| 5985 | WinRM | TCP | Windows Remote Management (HTTP) |
| 5986 | WinRM | TCP | WinRM over HTTPS |
| 6379 | Redis | TCP | In-memory DB. Souvent pas d'auth |
| 8080 | HTTP-Alt | TCP | Web alternatif, proxies, Tomcat |
| 8443 | HTTPS-Alt | TCP | Web alternatif TLS |
| 9200 | Elasticsearch | TCP | API REST, souvent expose |
| 27017 | MongoDB | TCP | NoSQL. Souvent pas d'auth |

---

## Services Windows / AD specifiques

| Port | Service | Usage pentest |
|------|---------|---------------|
| 88 | Kerberos | AS-REP Roasting, Kerberoasting |
| 135 | RPC | rpcclient, enum users/groups |
| 139/445 | SMB | smbclient, crackmapexec, enum shares |
| 389/636 | LDAP | ldapsearch, enum AD objects |
| 1433 | MSSQL | xp_cmdshell, linked servers |
| 3389 | RDP | xfreerdp, rdesktop |
| 5985 | WinRM | evil-winrm |

---

## Scan rapide de reference

```bash
# Top ports rapide
nmap -sC -sV -p- --min-rate 5000 TARGET_IP

# UDP top 20
nmap -sU --top-ports 20 TARGET_IP

# Scripts specifiques
nmap --script smb-enum-shares TARGET_IP
nmap --script ftp-anon TARGET_IP
```
