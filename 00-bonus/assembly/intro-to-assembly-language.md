# Cheatsheet - Intro to Assembly Language (HTB Academy)

---

## 1. Architecture & Concepts

### Von Neumann Architecture
- **CPU** : Control Unit (CU) + Arithmetic/Logic Unit (ALU) + Registres
- **Memory** : Cache (L1/L2/L3) + RAM
- **I/O** : Clavier, ecran, stockage

### Segments memoire (RAM)

| Segment | Description |
|---------|-------------|
| **Stack** | LIFO, taille fixe. Acces par `push`/`pop` |
| **Heap** | Hierarchique, plus grand et flexible, mais plus lent |
| **Data** | Variables (`.data`) + buffer non assigne (`.bss`) |
| **Text** | Instructions assembleur (read-only, executable) |

### Cycle d'instruction CPU
1. **Fetch** : Recupere l'instruction depuis `rip`
2. **Decode** : Decodage du binaire pour identifier l'instruction
3. **Execute** : Execution par le CU ou l'ALU
4. **Store** : Stockage du resultat dans l'operande destination

### ISA : CISC vs RISC

| | CISC (x86) | RISC (ARM) |
|---|------------|------------|
| Instructions | Complexes, peu nombreuses | Simples, nombreuses |
| Cycles | Moins de cycles, mais plus longs | Plus de cycles, mais plus courts |
| Puissance | Plus gourmand | Plus econome |

### Endianness
- **Little-Endian** (x86) : octets stockes de droite a gauche. `0x0011223344556677` -> stocke `0x7766554433221100`
- **Big-Endian** : octets stockes de gauche a droite (ordre naturel)

---

## 2. Registres x86_64

### Registres de donnees/arguments

| Description | 64-bit | 32-bit | 16-bit | 8-bit |
|------------|--------|--------|--------|-------|
| Syscall Number / Return value | `rax` | `eax` | `ax` | `al` |
| Callee Saved | `rbx` | `ebx` | `bx` | `bl` |
| 1st arg - Destination | `rdi` | `edi` | `di` | `dil` |
| 2nd arg - Source | `rsi` | `esi` | `si` | `sil` |
| 3rd arg | `rdx` | `edx` | `dx` | `dl` |
| 4th arg - Loop counter | `rcx` | `ecx` | `cx` | `cl` |
| 5th arg | `r8` | `r8d` | `r8w` | `r8b` |
| 6th arg | `r9` | `r9d` | `r9w` | `r9b` |

### Registres pointeurs

| Description | 64-bit | 32-bit | 16-bit | 8-bit |
|------------|--------|--------|--------|-------|
| Base Stack Pointer | `rbp` | `ebp` | `bp` | `bpl` |
| Current/Top Stack Pointer | `rsp` | `esp` | `sp` | `spl` |
| Instruction Pointer | `rip` | `eip` | `ip` | `ipl` |

### Modes d'adressage

| Mode | Description | Exemple |
|------|------------|---------|
| Immediate | Valeur directe | `add 2` |
| Register | Valeur dans un registre | `add rax` |
| Direct | Adresse complete | `call 0xffffffffaa8a25ff` |
| Indirect | Pointeur/reference | `call [rax]` |
| Stack | Adresse au sommet de la pile | `add rsp` |

---

## 3. Structure d'un fichier Assembly

```nasm
global  _start          ; directive : execution commence a _start

section .data           ; section des variables
    message db "Hello HTB Academy!"
    length  equ $-message   ; constante = longueur de message

section .text           ; section du code (executable)
_start:
    mov     rax, 1      ; syscall write
    mov     rdi, 1      ; fd = stdout
    mov     rsi, message
    mov     rdx, 18     ; longueur
    syscall

    mov     rax, 60     ; syscall exit
    mov     rdi, 0      ; code retour 0
    syscall
```

### Elements par ligne
1. **Labels** : etiquettes pour referencer du code/donnees
2. **Instructions** : operations a executer
3. **Operandes** : arguments de l'instruction

### Directives de donnees

| Instruction | Description |
|------------|-------------|
| `db 0x0a` | Definit l'octet `0x0a` (newline) |
| `message db "Hello!", 0x0a` | Definit une chaine avec label |
| `length equ $-message` | Constante = longueur de la chaine |
| `dw` | Liste de words (2 bytes) |
| `dd` | Liste de double-words (4 bytes) |

---

## 4. Assemblage & Desassemblage

| Commande | Description |
|----------|-------------|
| `nasm -f elf64 file.s` | Assembler le code |
| `ld -o file file.o` | Linker le binaire |
| `ld -o file file.o -lc --dynamic-linker /lib64/ld-linux-x86-64.so.2` | Linker avec libc |
| `objdump -M intel -d file` | Desassembler section `.text` |
| `objdump -M intel --no-show-raw-insn --no-addresses -d file` | Afficher code ASM propre |
| `objdump -sj .data file` | Desassembler section `.data` |

---

## 5. GDB (GNU Debugger)

| Commande | Description |
|----------|-------------|
| `gdb -q ./binary` | Ouvrir un binaire dans GDB |
| `info functions` | Lister les fonctions |
| `info variables` | Lister les variables |
| `registers` | Afficher les registres |
| `disas _start` | Desassembler un label/fonction |
| `b _start` | Breakpoint sur un label |
| `b *0x401000` | Breakpoint sur une adresse |
| `r` | Executer le binaire |
| `si` | Step instruction (une instruction) |
| `s` | Step (une ligne de code) |
| `ni` | Next instruction (saute les fonctions) |
| `c` | Continue jusqu'au prochain breakpoint |
| `x/4xg $rip` | Examiner memoire : `x/count-format-size $reg` |
| `patch string 0x402000 "Patched!\x0a"` | Patcher une valeur en memoire |
| `set $rdx=0x9` | Modifier la valeur d'un registre |

### Formats d'examen memoire (`x/`)
- **Count** : nombre d'unites a afficher
- **Format** : `x` (hex), `s` (string), `i` (instruction)
- **Size** : `b` (byte), `h` (halfword/2B), `w` (word/4B), `g` (giant/8B)

---

## 6. Instructions de mouvement de donnees

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `mov` | Copier une donnee (ne modifie pas la source) | `mov rax, 1` -> `rax = 1` |
| `lea` | Charger une adresse (pas la valeur) | `lea rax, [rsp+5]` -> `rax = rsp+5` |
| `xchg` | Echanger les valeurs de deux registres | `xchg rax, rbx` -> swap |

> **Tip** : Utiliser des sous-registres adaptes a la taille des donnees pour plus d'efficacite.
> `mov rax, 0` = 5 bytes de shellcode vs `mov al, 0` = 2 bytes.

---

## 7. Instructions arithmetiques

### Unaires (1 operande)

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `inc` | Incrementer de 1 | `inc rax` -> `rax += 1` |
| `dec` | Decrementer de 1 | `dec rax` -> `rax -= 1` |

### Binaires (2 operandes)

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `add` | Addition | `add rax, rbx` -> `rax = rax + rbx` |
| `sub` | Soustraction | `sub rax, rbx` -> `rax = rax - rbx` |
| `imul` | Multiplication | `imul rax, rbx` -> `rax = rax * rbx` |

### Bitwise (operations sur les bits)

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `not` | Inversion de tous les bits | `not rax` -> `NOT 00000001` = `11111110` |
| `and` | ET logique (1 AND 1 = 1, sinon 0) | `and rax, rbx` |
| `or` | OU logique (0 OR 0 = 0, sinon 1) | `or rax, rbx` |
| `xor` | OU exclusif (bits differents = 1) | `xor rax, rax` -> met `rax` a 0 |

> **Astuce** : `xor rax, rax` est la facon la plus efficace de mettre un registre a 0 (1 byte de shellcode).

---

## 8. Instructions de controle

### Boucles (Loops)

```nasm
    mov rcx, 3          ; compteur = 3
loopExample:
    ; ... instructions ...
    loop loopExample     ; rcx--, saute si rcx != 0
```

- `rcx` est le compteur de boucle
- `loop` decremente `rcx` et saute au label si `rcx != 0`

### Branchement inconditionnel

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `jmp` | Saut inconditionnel vers un label/adresse | `jmp loop` |

### Branchement conditionnel (`Jcc`)

| Instruction | Condition | Description |
|------------|-----------|-------------|
| `jz` | `D = 0` | Saut si zero |
| `jnz` | `D != 0` | Saut si non-zero |
| `js` | `D < 0` | Saut si negatif |
| `jns` | `D >= 0` | Saut si non-negatif |
| `jg` | `D > S` | Saut si plus grand |
| `jge` | `D >= S` | Saut si plus grand ou egal |
| `jl` | `D < S` | Saut si plus petit |
| `jle` | `D <= S` | Saut si plus petit ou egal |

### Comparaison

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `cmp` | Compare en soustrayant (modifie RFLAGS) | `cmp rax, rbx` -> `rax - rbx` |

### Registre RFLAGS (flags principaux)

| Flag | Bit | Description |
|------|-----|-------------|
| CF (Carry Flag) | 0 | Retenue lors d'une operation |
| ZF (Zero Flag) | 6 | Resultat = 0 |
| SF (Sign Flag) | 7 | Resultat negatif |
| OF (Overflow Flag) | 11 | Depassement de capacite |

### Instructions conditionnelles additionnelles
- `cmovz rax, rbx` : mov conditionnel si zero
- `cmovl rax, rbx` : mov conditionnel si inferieur
- `setz rax` : set byte a 1 si zero, 0 sinon

---

## 9. La Stack (Pile)

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `push` | Empile une valeur (au sommet = `rsp`) | `push rax` |
| `pop` | Depile du sommet vers un registre | `pop rax` |

- **LIFO** (Last-In First-Out)
- `rsp` pointe vers le sommet
- `rbp` pointe vers la base
- `push` decremente `rsp` de 8, puis ecrit la valeur
- `pop` lit la valeur a `rsp`, puis incremente de 8

---

## 10. Syscalls

### Convention d'appel

1. Sauvegarder les registres sur la stack
2. Mettre le numero du syscall dans `rax`
3. Mettre les arguments dans les registres (`rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9`)
4. Appeler `syscall`

### Syscalls courants

| Syscall | rax | rdi | rsi | rdx |
|---------|-----|-----|-----|-----|
| **read** | 0 | fd (0=stdin) | buffer | count |
| **write** | 1 | fd (1=stdout) | buffer | count |
| **open** | 2 | filename | flags | mode |
| **close** | 3 | fd | - | - |
| **exit** | 60 | error_code | - | - |

### Commandes utiles
```bash
cat /usr/include/x86_64-linux-gnu/asm/unistd_64.h | grep write  # trouver le numero
man -s 2 write    # man page du syscall
man -s 3 printf   # man page de la fonction libc
```

### Exemple : write "Hello" sur stdout
```nasm
mov rax, 1          ; syscall write
mov rdi, 1          ; fd = stdout
mov rsi, message    ; pointeur vers la chaine
mov rdx, 5          ; longueur = 5
syscall
```

### Exemple : exit propre
```nasm
mov rax, 60         ; syscall exit
mov rdi, 0          ; code retour 0
syscall
```

---

## 11. Procedures & Fonctions

### Procedures (call/ret)

| Instruction | Description |
|------------|-------------|
| `call label` | Push `rip` sur la stack, puis saute au label |
| `ret` | Pop l'adresse du sommet de la stack dans `rip` |

```nasm
_start:
    call printMessage
    call initFib
    call loopFib
    call Exit

printMessage:
    ; ... code ...
    ret

initFib:
    xor rax, rax
    xor rbx, rbx
    inc rbx
    ret
```

### Convention d'appel des fonctions

1. **Sauvegarder les registres** sur la stack (Caller Saved)
2. **Passer les arguments** (`rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9`)
3. **Aligner la stack** (sur 16 bytes avant le `call`)
4. **Recuperer la valeur de retour** dans `rax`

### Fonctions Libc

```nasm
; Linker avec : ld -o prog prog.o -lc --dynamic-linker /lib64/ld-linux-x86-64.so.2
extern printf           ; declarer la fonction externe

section .data
    fmt db "Value: %d", 0x0a, 0x00

section .text
    mov rdi, fmt        ; 1er arg = format string
    mov rsi, 42         ; 2eme arg = valeur
    call printf
```

---

## 12. Shellcoding

### Exigences d'un shellcode valide
1. **Pas de variables** (pas de section `.data`)
2. **Pas d'adresses memoire directes**
3. **Pas de bytes NULL (`00`)** (termineraient une chaine)

### Techniques pour eviter les variables
```nasm
; Methode : push les chaines sur la stack
mov rbx, 'y!'
push rbx
mov rbx, 'B Academ'
push rbx
mov rbx, 'Hello HT'
push rbx
mov rsi, rsp            ; rsi pointe vers la chaine sur la stack
```

### Techniques pour eviter les NULL bytes
```nasm
; MAUVAIS (contient des 00) :
mov rax, 0              ; b8 00 00 00 00

; BON (pas de 00) :
xor rax, rax            ; 48 31 c0

; MAUVAIS :
mov rdi, 1              ; bf 01 00 00 00

; BON :
xor rdi, rdi
inc rdi                 ; ou : mov dil, 1
```

### Outils pwntools

| Commande | Description |
|----------|-------------|
| `pwn asm 'push rax' -c 'amd64'` | Instruction -> shellcode |
| `pwn disasm '50' -c 'amd64'` | Shellcode -> instruction |
| `python3 shellcoder.py helloworld` | Extraire le shellcode d'un binaire |
| `python3 loader.py '4831..0f05'` | Executer un shellcode |

### Extraction du shellcode avec Python
```python
from pwn import *
context(os="linux", arch="amd64")
file = ELF('binary')
shellcode = file.section(".text").hex()
print(shellcode)
```

### Shellcraft (pwntools)

| Commande | Description |
|----------|-------------|
| `pwn shellcraft -l 'amd64.linux'` | Lister les syscalls disponibles |
| `pwn shellcraft amd64.linux.sh` | Generer un shellcode shell |
| `pwn shellcraft amd64.linux.sh -r` | Executer le shellcode genere |

### Msfvenom

| Commande | Description |
|----------|-------------|
| `msfvenom -l payloads \| grep 'linux/x64'` | Lister les payloads |
| `msfvenom -p 'linux/x64/exec' CMD='sh' -a 'x64' --platform 'linux' -f 'hex'` | Generer un shellcode |
| `msfvenom -p 'linux/x64/exec' CMD='sh' -a 'x64' --platform 'linux' -f 'hex' -e 'x64/xor'` | Shellcode encode |

---

## 13. Recapitulatif rapide des instructions

| Categorie | Instructions |
|-----------|-------------|
| **Mouvement** | `mov`, `lea`, `xchg` |
| **Arithmetique** | `inc`, `dec`, `add`, `sub`, `imul` |
| **Bitwise** | `not`, `and`, `or`, `xor` |
| **Boucles** | `mov rcx, n` + `loop` |
| **Sauts** | `jmp`, `jz`, `jnz`, `js`, `jns`, `jg`, `jge`, `jl`, `jle` |
| **Comparaison** | `cmp` |
| **Stack** | `push`, `pop` |
| **Fonctions** | `call`, `ret`, `syscall` |

---

## 14. Workflow typique

```bash
# 1. Ecrire le code assembly
vim program.s

# 2. Assembler
nasm -f elf64 program.s

# 3. Linker
ld -o program program.o

# 4. Executer
./program

# 5. Debugger
gdb -q ./program
(gdb) b _start
(gdb) r
(gdb) si        # step instruction par instruction
```

---

*Cheatsheet generee a partir du module HTB Academy "Intro to Assembly Language" (Module 85)*
