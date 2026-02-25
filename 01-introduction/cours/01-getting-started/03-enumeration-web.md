# Énumération web

[<< Précédent : Énumération de services](02-enumeration-services.md) | [Suivant : Exploits publics >>](04-exploits-publics.md)

---

## Fingerprinting

```bash
whatweb TARGET_IP                     # identification des technos (CMS, framework, serveur)
whatweb --no-errors 10.10.10.0/24     # scan réseau rapide
curl -IL https://TARGET               # headers HTTP (serveur, redirections, cookies)
```

`whatweb` identifie le CMS, le framework, le serveur HTTP, les cookies, les meta-generateurs. Très utile pour savoir rapidement à quoi on a affaire.

---

## Fuzzing de répertoires

```bash
# Gobuster
gobuster dir -u http://TARGET_IP/ -w /usr/share/seclists/Discovery/Web-Content/common.txt

# Feroxbuster (recursif par défaut, plus rapide)
feroxbuster -u http://TARGET_IP/ -w /usr/share/seclists/Discovery/Web-Content/common.txt
```

Codes HTTP à connaître :
- **200** : OK (accès direct)
- **301** : redirection permanente
- **403** : accès interdit (le fichier existe mais pas de permission)
- **404** : n'existe pas

---

## Fuzzing de sous-domaines

```bash
gobuster dns -d domain.com -w /usr/share/SecLists/Discovery/DNS/namelist.txt
```

---

## Sources d'information passives

- **Certificats SSL/TLS** : révèlent email, nom d'entreprise, sous-domaines (SAN)
- **robots.txt** : répertoires cachés, pages admin
- **Code source** (`Ctrl+U` dans Firefox) : commentaires développeurs, credentials de test, chemins internes, répertoires cachés dans les commentaires HTML
