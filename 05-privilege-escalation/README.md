# 05 - Privilege Escalation

## Cours

| # | Module | Statut |
|---|--------|--------|
| 1 | [Linux Privilege Escalation](cours/linux-privilege-escalation.md) | [ ] |
| 2 | [Windows Privilege Escalation](cours/windows-privilege-escalation.md) | [ ] |

## Boxes

| # | Box | OS | Difficulté | User | Root |
|---|-----|----|------------|------|------|
| 1 | [Access](boxes/access.md) | Windows | Easy | [ ] | [ ] |
| 2 | [Arctic](boxes/arctic.md) | Windows | Easy | [ ] | [ ] |
| 3 | [Beep](boxes/beep.md) | Linux | Easy | [ ] | [ ] |
| 4 | [Grandpa](boxes/grandpa.md) | Windows | Easy | [ ] | [ ] |
| 5 | [Granny](boxes/granny.md) | Windows | Easy | [ ] | [ ] |
| 6 | [Optimum](boxes/optimum.md) | Windows | Easy | [ ] | [ ] |
| 7 | [Postman](boxes/postman.md) | Linux | Easy | [ ] | [ ] |
| 8 | [Sense](boxes/sense.md) | FreeBSD | Easy | [ ] | [ ] |
| 9 | [Valentine](boxes/valentine.md) | Linux | Easy | [ ] | [ ] |
| 10 | [Bastard](boxes/bastard.md) | Windows | Medium | [ ] | [ ] |

## Checklist Linux Privesc

- [ ] `sudo -l` / SUID binaries / Capabilities
- [ ] Cron jobs / Writable scripts
- [ ] Kernel exploits (`uname -a`)
- [ ] Fichiers sensibles lisibles (.ssh, /etc/shadow, configs)
- [ ] Services internes (127.0.0.1)
- [ ] LinPEAS / LinEnum

## Checklist Windows Privesc

- [ ] `whoami /priv` / Token privileges
- [ ] Services mal configurés
- [ ] Unquoted service paths
- [ ] AlwaysInstallElevated
- [ ] Stored credentials / SAM & SYSTEM
- [ ] Kernel exploits (`systeminfo`)
- [ ] WinPEAS / PowerUp / Seatbelt
