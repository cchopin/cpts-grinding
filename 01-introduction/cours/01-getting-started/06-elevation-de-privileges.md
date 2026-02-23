# Elevation de privileges

[<< Precedent : Types de shells](05-types-de-shells.md) | [Suivant : Transfert de fichiers >>](07-transfert-de-fichiers.md)

---

## Methodologie

1. Lancer un script d'enumeration automatisee (LinPEAS, WinPEAS, LinEnum)
2. Verifier les vecteurs dans l'ordre :

| Vecteur | Commandes |
|---------|-----------|
| Privileges sudo | `sudo -l` |
| Binaires SUID | `find / -perm -4000 2>/dev/null` |
| Kernel exploits | `uname -r` puis `searchsploit` |
| Software vulnerable | `dpkg -l` (Linux), `wmic product get` (Windows) |
| Taches planifiees | `crontab -l`, `ls /etc/cron*` |
| Credentials exposes | configs, logs, historique bash, cles SSH |

---

## sudo

```bash
sudo -l                               # lister les privileges
sudo su -                             # passer root
sudo -u user /bin/command              # executer en tant qu'autre user
```

`NOPASSWD` = execution sans mot de passe. Toujours verifier [GTFOBins](https://gtfobins.github.io) pour les binaires autorises.

---

## Credentials exposes

Chercher dans :
- Fichiers de config : `/etc/`, configs applicatives
- Historique : `~/.bash_history`
- Cles SSH : `~/.ssh/id_rsa`
- Windows : `%userprofile%\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`

Toujours tester le **password reuse** (meme mot de passe pour plusieurs services/utilisateurs).

---

## Cles SSH

```bash
# Lire une cle privee existante sur la cible
cat /home/user/.ssh/id_rsa

# L'utiliser depuis notre machine
chmod 600 id_rsa
ssh user@TARGET_IP -i id_rsa

# Ou ajouter notre propre cle publique
ssh-keygen -f key
echo "ssh-rsa AAAAB...= user@attacker" >> /home/user/.ssh/authorized_keys
ssh user@TARGET_IP -i key
```

> Voir [cheatsheet privilege-escalation](../../../cheatsheets/privilege-escalation.md) pour les commandes detaillees.
