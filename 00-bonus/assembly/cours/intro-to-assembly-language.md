# Cheatsheet - Intro to Assembly Language (HTB Academy)

---

## 1. Architecture & Concepts

### Von Neumann Architecture
- **CPU** : Control Unit (CU) + Arithmetic/Logic Unit (ALU) + Registres
- **Memory** : Cache (L1/L2/L3) + RAM
- **I/O** : Clavier, écran, stockage

### Segments mémoire (RAM)

| Segment | Description |
|---------|-------------|
| **Stack** | LIFO, taille fixe. Accès par `push`/`pop` |
| **Heap** | Hiérarchique, plus grand et flexible, mais plus lent |
| **Data** | Variables (`.data`) + buffer non assigné (`.bss`) |
| **Text** | Instructions assembleur (read-only, exécutable) |

### Cycle d'instruction CPU
1. **Fetch** : Récupère l'instruction depuis `rip`
2. **Decode** : Décodage du binaire pour identifier l'instruction
3. **Execute** : Exécution par le CU ou l'ALU
4. **Store** : Stockage du résultat dans l'opérande destination

### ISA : CISC vs RISC

| | CISC (x86) | RISC (ARM) |
|---|------------|------------|
| Instructions | Complexes, peu nombreuses | Simples, nombreuses |
| Cycles | Moins de cycles, mais plus longs | Plus de cycles, mais plus courts |
| Puissance | Plus gourmand | Plus économe |

### Endianness
- **Little-Endian** (x86) : octets stockés de droite à gauche. `0x0011223344556677` -> stocké `0x7766554433221100`
- **Big-Endian** : octets stockés de gauche à droite (ordre naturel)

---

## 2. Registres x86_64

### Registres de données/arguments

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
| Direct | Adresse complète | `call 0xffffffffaa8a25ff` |
| Indirect | Pointeur/référence | `call [rax]` |
| Stack | Adresse au sommet de la pile | `add rsp` |

---

## 3. Structure d'un fichier Assembly

```nasm
global  _start          ; directive : exécution commence à _start

section .data           ; section des variables
    message db "Hello HTB Academy!"
    length  equ $-message   ; constante = longueur de message

section .text           ; section du code (exécutable)
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

### Éléments par ligne
1. **Labels** : étiquettes pour référencer du code/données
2. **Instructions** : opérations à exécuter
3. **Opérandes** : arguments de l'instruction

### Directives de données

| Instruction | Description |
|------------|-------------|
| `db 0x0a` | Définit l'octet `0x0a` (newline) |
| `message db "Hello!", 0x0a` | Définit une chaîne avec label |
| `length equ $-message` | Constante = longueur de la chaîne |
| `dw` | Liste de words (2 bytes) |
| `dd` | Liste de double-words (4 bytes) |

---

## 4. Assemblage & Désassemblage

| Commande | Description |
|----------|-------------|
| `nasm -f elf64 file.s` | Assembler le code |
| `ld -o file file.o` | Linker le binaire |
| `ld -o file file.o -lc --dynamic-linker /lib64/ld-linux-x86-64.so.2` | Linker avec libc |
| `objdump -M intel -d file` | Désassembler section `.text` |
| `objdump -M intel --no-show-raw-insn --no-addresses -d file` | Afficher code ASM propre |
| `objdump -sj .data file` | Désassembler section `.data` |

---

## 5. GDB (GNU Debugger)

| Commande | Description |
|----------|-------------|
| `gdb -q ./binary` | Ouvrir un binaire dans GDB |
| `info functions` | Lister les fonctions |
| `info variables` | Lister les variables |
| `registers` | Afficher les registres |
| `disas _start` | Désassembler un label/fonction |
| `b _start` | Breakpoint sur un label |
| `b *0x401000` | Breakpoint sur une adresse |
| `r` | Exécuter le binaire |
| `si` | Step instruction (une instruction) |
| `s` | Step (une ligne de code) |
| `ni` | Next instruction (saute les fonctions) |
| `c` | Continue jusqu'au prochain breakpoint |
| `x/4xg $rip` | Examiner mémoire : `x/count-format-size $reg` |
| `patch string 0x402000 "Patched!\x0a"` | Patcher une valeur en mémoire |
| `set $rdx=0x9` | Modifier la valeur d'un registre |

### Commande `x/` (examine memory)

Syntaxe : `x/[count][format][size] [adresse/registre]`

```
x/  [combien] [comment] [quelle taille]  [ou]
     count     format     size             address

x/    4          x          g              $rsp
     "4 valeurs  en hex    de 8 bytes    depuis rsp"
```

#### Format (comment afficher)

| Format | Description | Exemple |
|--------|------------|---------|
| `x` | Hexadécimal | `x/x $rax` -> `0x41` |
| `d` | Décimal (signé) | `x/d $rax` -> `65` |
| `u` | Décimal non-signé | `x/u $rax` -> `65` |
| `s` | String (jusqu'au null byte) | `x/s $rsi` -> `"Hello HTB Academy!"` |
| `i` | Instruction (désassemble) | `x/i $rip` -> `mov eax, 0x1` |
| `c` | Caractère ASCII | `x/c $rax` -> `'A'` |
| `t` | Binaire (bits) | `x/t $rax` -> `01000001` |
| `o` | Octal | `x/o $rax` -> `0101` |
| `a` | Adresse (avec symbole) | `x/a $rsp` -> `0x401000 <_start>` |

#### Size (taille de chaque unite)

| Size | Nom | Taille |
|------|-----|--------|
| `b` | byte | 1 octet |
| `h` | halfword | 2 octets |
| `w` | word | 4 octets |
| `g` | giant | 8 octets (le plus courant en x86_64) |

#### Exemples concrets

```bash
# Strings
x/s  $rsi              # string pointée par rsi
x/s  0x402000          # string à une adresse
x/20c 0x402000         # 20 caracteres un par un

# Stack
x/8xg $rsp             # 8 éléments de la stack en hex (64-bit)
x/8dg $rsp             # pareil en décimal

# Code / Instructions
x/i  $rip              # prochaine instruction
x/10i $rip             # 10 prochaines instructions
x/5i  _start           # 5 premières instructions de _start

# Binaire (utile pour les bitwise ops)
x/t  $rax              # valeur de rax en binaire
x/4tb $rax             # 4 bytes en binaire
```

---

## 6. Instructions de mouvement de données

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `mov` | Copier une donnée (ne modifie pas la source) | `mov rax, 1` -> `rax = 1` |
| `lea` | Charger une adresse (pas la valeur) | `lea rax, [rsp+5]` -> `rax = rsp+5` |
| `xchg` | Échanger les valeurs de deux registres | `xchg rax, rbx` -> swap |

> **Tip** : Utiliser des sous-registres adaptés à la taille des données pour plus d'efficacité.
> `mov rax, 0` = 5 bytes de shellcode vs `mov al, 0` = 2 bytes.

---

## 7. Instructions arithmétiques

### Unaires (1 opérande)

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `inc` | Incrémenter de 1 | `inc rax` -> `rax += 1` |
| `dec` | Décrémenter de 1 | `dec rax` -> `rax -= 1` |

### Binaires (2 opérandes)

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `add` | Addition | `add rax, rbx` -> `rax = rax + rbx` |
| `sub` | Soustraction | `sub rax, rbx` -> `rax = rax - rbx` |
| `imul` | Multiplication | `imul rax, rbx` -> `rax = rax * rbx` |

### Bitwise (opérations sur les bits)

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `not` | Inversion de tous les bits | `not rax` -> `NOT 00000001` = `11111110` |
| `and` | ET logique (1 AND 1 = 1, sinon 0) | `and rax, rbx` |
| `or` | OU logique (0 OR 0 = 0, sinon 1) | `or rax, rbx` |
| `xor` | OU exclusif (bits différents = 1) | `xor rax, rax` -> met `rax` à 0 |

> **Astuce** : `xor rax, rax` est la façon la plus efficace de mettre un registre à 0 (1 byte de shellcode).

---

## 8. Instructions de contrôle

### Boucles (Loops)

```nasm
    mov rcx, 3          ; compteur = 3
loopExample:
    ; ... instructions ...
    loop loopExample     ; rcx--, saute si rcx != 0
```

- `rcx` est le compteur de boucle
- `loop` décrémente `rcx` et saute au label si `rcx != 0`

### Branchement inconditionnel

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `jmp` | Saut inconditionnel vers un label/adresse | `jmp loop` |

### Branchement conditionnel (`Jcc`)

| Instruction | Condition | Description |
|------------|-----------|-------------|
| `jz` | `D = 0` | Saut si zero |
| `jnz` | `D != 0` | Saut si non-zero |
| `js` | `D < 0` | Saut si négatif |
| `jns` | `D >= 0` | Saut si non-négatif |
| `jg` | `D > S` | Saut si plus grand |
| `jge` | `D >= S` | Saut si plus grand ou égal |
| `jl` | `D < S` | Saut si plus petit |
| `jle` | `D <= S` | Saut si plus petit ou égal |

### Comparaison

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `cmp` | Compare en soustrayant (modifie RFLAGS) | `cmp rax, rbx` -> `rax - rbx` |

### Registre RFLAGS (flags principaux)

| Flag | Bit | Description |
|------|-----|-------------|
| CF (Carry Flag) | 0 | Retenue lors d'une opération |
| ZF (Zero Flag) | 6 | Résultat = 0 |
| SF (Sign Flag) | 7 | Résultat négatif |
| OF (Overflow Flag) | 11 | Dépassement de capacité |

### Instructions conditionnelles additionnelles
- `cmovz rax, rbx` : mov conditionnel si zero
- `cmovl rax, rbx` : mov conditionnel si inférieur
- `setz rax` : set byte a 1 si zero, 0 sinon

---

## 9. La Stack (Pile)

| Instruction | Description | Exemple |
|------------|-------------|---------|
| `push` | Empile une valeur (au sommet = `rsp`) | `push rax` |
| `pop` | Dépile du sommet vers un registre | `pop rax` |

- **LIFO** (Last-In First-Out)
- `rsp` pointe vers le sommet
- `rbp` pointe vers la base
- `push` décrémente `rsp` de 8, puis écrit la valeur
- `pop` lit la valeur à `rsp`, puis incrémente de 8

---

## 10. Syscalls

### Convention d'appel

1. Sauvegarder les registres sur la stack
2. Mettre le numéro du syscall dans `rax`
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
cat /usr/include/x86_64-linux-gnu/asm/unistd_64.h | grep write  # trouver le numéro
man -s 2 write    # man page du syscall
man -s 3 printf   # man page de la fonction libc
```

### Exemple : write "Hello" sur stdout
```nasm
mov rax, 1          ; syscall write
mov rdi, 1          ; fd = stdout
mov rsi, message    ; pointeur vers la chaîne
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

## 11. Procédures & Fonctions

### Procédures (call/ret)

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
4. **Récupérer la valeur de retour** dans `rax`

### Fonctions Libc

```nasm
; Linker avec : ld -o prog prog.o -lc --dynamic-linker /lib64/ld-linux-x86-64.so.2
extern printf           ; déclarer la fonction externe

section .data
    fmt db "Value: %d", 0x0a, 0x00

section .text
    mov rdi, fmt        ; 1er arg = format string
    mov rsi, 42         ; 2ème arg = valeur
    call printf
```

---

> **Shellcoding** : Voir le fichier dédié [shellcoding.md](shellcoding.md) pour les techniques de shellcoding, scripts utilitaires et exemples complets.

---

## 12. Récapitulatif rapide

| Catégorie | Instructions |
|-----------|-------------|
| **Mouvement** | `mov`, `lea`, `xchg` |
| **Arithmétique** | `inc`, `dec`, `add`, `sub`, `imul` |
| **Bitwise** | `not`, `and`, `or`, `xor` |
| **Boucles** | `mov rcx, n` + `loop` |
| **Sauts** | `jmp`, `jz`, `jnz`, `js`, `jns`, `jg`, `jge`, `jl`, `jle` |
| **Comparaison** | `cmp` |
| **Stack** | `push`, `pop` |
| **Fonctions** | `call`, `ret`, `syscall` |

---

## 13. Workflow typique

```bash
# 1. Écrire le code assembly
vim program.s

# 2. Assembler
nasm -f elf64 program.s

# 3. Linker
ld -o program program.o

# 4. Exécuter
./program

# 5. Debugger
gdb -q ./program
(gdb) b _start
(gdb) r
(gdb) si        # step instruction par instruction
```

---
