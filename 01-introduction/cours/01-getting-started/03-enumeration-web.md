# Enumeration web

[<< Precedent : Enumeration de services](02-enumeration-services.md) | [Suivant : Exploits publics >>](04-exploits-publics.md)

---

## Fingerprinting

```bash
whatweb TARGET_IP                     # identification des technos (CMS, framework, serveur)
whatweb --no-errors 10.10.10.0/24     # scan reseau rapide
curl -IL https://TARGET               # headers HTTP (serveur, redirections, cookies)
```

`whatweb` identifie le CMS, le framework, le serveur HTTP, les cookies, les meta-generateurs. Tres utile pour savoir rapidement a quoi on a affaire.

---

## Fuzzing de repertoires

```bash
# Gobuster
gobuster dir -u http://TARGET_IP/ -w /usr/share/seclists/Discovery/Web-Content/common.txt

# Feroxbuster (recursif par defaut, plus rapide)
feroxbuster -u http://TARGET_IP/ -w /usr/share/seclists/Discovery/Web-Content/common.txt
```

Codes HTTP a connaitre :
- **200** : OK (acces direct)
- **301** : redirection permanente
- **403** : acces interdit (le fichier existe mais pas de permission)
- **404** : n'existe pas

---

## Fuzzing de sous-domaines

```bash
gobuster dns -d domain.com -w /usr/share/SecLists/Discovery/DNS/namelist.txt
```

---

## Sources d'information passives

- **Certificats SSL/TLS** : relevent email, nom d'entreprise, sous-domaines (SAN)
- **robots.txt** : repertoires caches, pages admin
- **Code source** (`Ctrl+U` dans Firefox) : commentaires developpeurs, credentials de test, chemins internes, repertoires caches dans les commentaires HTML
