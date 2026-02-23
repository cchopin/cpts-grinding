# Assembly x86_64 & Shellcoding

> Cours détaillés : [intro-to-assembly-language](../00-bonus/assembly/cours/intro-to-assembly-language.md) | [shellcoding](../00-bonus/assembly/cours/shellcoding.md) | [shellcodes-reference](../00-bonus/assembly/cours/shellcodes-reference.md)

---

## Registres

### Data / Arguments

| Description | 64-bit | 8-bit |
|-------------|--------|-------|
| Syscall Number / Return value | `rax` | `al` |
| Callee Saved | `rbx` | `bl` |
| 1st arg | `rdi` | `dil` |
| 2nd arg | `rsi` | `sil` |
| 3rd arg | `rdx` | `dl` |
| 4th arg / Loop Counter | `rcx` | `cl` |
| 5th arg | `r8` | `r8b` |
| 6th arg | `r9` | `r9b` |

### Pointeurs

| Description | 64-bit | 8-bit |
|-------------|--------|-------|
| Base Stack Pointer | `rbp` | `bpl` |
| Current/Top Stack Pointer | `rsp` | `spl` |
| Instruction Pointer (call only) | `rip` | `ipl` |

---

## Assembly & Disassembly

```bash
# Assembler
nasm -f elf64 helloWorld.s

# Linker
ld -o helloWorld helloWorld.o

# Linker avec libc
ld -o fib fib.o -lc --dynamic-linker /lib64/ld-linux-x86-64.so.2

# Désassembler .text
objdump -M intel -d helloWorld

# Désassembler proprement (sans raw bytes ni adresses)
objdump -M intel --no-show-raw-insn --no-addresses -d helloWorld

# Désassembler .data
objdump -sj .data helloWorld
```

---

## GDB

```bash
# Ouvrir un binaire
gdb -q ./helloWorld
```

| Commande | Action |
|----------|--------|
| `info functions` | Lister les fonctions |
| `info variables` | Lister les variables |
| `registers` | Voir les registres |
| `disas _start` | Désassembler un label/fonction |
| `b _start` | Breakpoint sur label |
| `b *0x401000` | Breakpoint sur adresse |
| `r` | Run |
| `x/4xg $rip` | Examiner mémoire (count/format/size register) |
| `si` | Step instruction |
| `s` | Step line |
| `ni` | Step over (next function) |
| `c` | Continue jusqu'au prochain breakpoint |
| `patch string 0x402000 "Patched!\x0a"` | Patcher une valeur en mémoire |
| `set $rdx=0x9` | Modifier un registre |

---

## Instructions Assembly

### Data Movement

| Instruction | Description | Exemple |
|-------------|-------------|---------|
| `mov` | Déplacer / charger une valeur | `mov rax, 1` |
| `lea` | Charger une adresse | `lea rax, [rsp+5]` |
| `xchg` | Swap entre 2 registres | `xchg rax, rbx` |

### Arithmétique unaire

| Instruction | Description | Exemple |
|-------------|-------------|---------|
| `inc` | Incrémenter de 1 | `inc rax` -> rax++ |
| `dec` | Décrémenter de 1 | `dec rax` -> rax-- |

### Arithmétique binaire

| Instruction | Description | Exemple |
|-------------|-------------|---------|
| `add` | Addition | `add rax, rbx` -> rax = rax + rbx |
| `sub` | Soustraction | `sub rax, rbx` -> rax = rax - rbx |
| `imul` | Multiplication | `imul rax, rbx` -> rax = rax * rbx |

### Bitwise

| Instruction | Description | Exemple |
|-------------|-------------|---------|
| `not` | NOT (inverse tous les bits) | `not rax` |
| `and` | AND (1 si les 2 bits sont 1) | `and rax, rbx` |
| `or` | OR (1 si au moins 1 bit est 1) | `or rax, rbx` |
| `xor` | XOR (1 si les bits sont différents) | `xor rax, rbx` |

### Boucles

```nasm
mov rcx, 3            ; compteur = 3
exampleLoop:
    ; ... instructions ...
    loop exampleLoop  ; rcx-- et jump si rcx != 0
```

### Branching (sauts conditionnels)

| Instruction | Condition |
|-------------|-----------|
| `jmp` | Saut inconditionnel |
| `jz` | Destination == 0 |
| `jnz` | Destination != 0 |
| `js` | Destination < 0 |
| `jns` | Destination >= 0 |
| `jg` | Destination > Source |
| `jge` | Destination >= Source |
| `jl` | Destination < Source |
| `jle` | Destination <= Source |
| `cmp` | Compare (soustrait sans stocker) : `cmp rax, rbx` -> flags de rax - rbx |

### Stack

| Instruction | Action |
|-------------|--------|
| `push rax` | Empile rax (rsp -= 8, [rsp] = rax) |
| `pop rax` | Dépile dans rax (rax = [rsp], rsp += 8) |

### Fonctions

| Instruction | Action |
|-------------|--------|
| `call func` | Push rip sur la stack, jump à func |
| `ret` | Pop [rsp] dans rip, jump |

---

## Syscalls & Fonctions

```bash
# Trouver le numéro d'un syscall
cat /usr/include/x86_64-linux-gnu/asm/unistd_64.h | grep write

# Man page syscall
man -s 2 write

# Man page libc
man -s 3 printf
```

### Convention d'appel syscall

1. Sauvegarder les registres sur la stack
2. Mettre le numéro du syscall dans `rax`
3. Mettre les arguments dans `rdi`, `rsi`, `rdx`, `rcx`/`r10`, `r8`, `r9`
4. `syscall`

### Convention d'appel fonction

1. Sauvegarder les registres (Caller Saved)
2. Passer les arguments (`rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9`)
3. Aligner la stack (16 bytes)
4. Récupérer la valeur de retour dans `rax`

---

## Shellcoding

### Exigences

Un shellcode valide :
- **Pas de variables** (pas de section `.data`)
- **Pas d'adresses mémoire directes** (position-independent)
- **Pas de null bytes** (`0x00`) - coupe les strings C

### Outils pwntools

```bash
# Instruction -> shellcode hex
pwn asm 'push rax' -c 'amd64'

# Shellcode hex -> instructions
pwn disasm '50' -c 'amd64'

# Extraire le shellcode d'un binaire
python3 shellcoder.py helloworld

# Charger et exécuter un shellcode
python3 loader.py '4831...0f05'

# Assembler un shellcode en binaire
python3 assembler.py '4831...0f05'
```

### Shellcraft (pwntools)

```bash
# Lister les syscalls disponibles
pwn shellcraft -l 'amd64.linux'

# Générer un shellcode
pwn shellcraft amd64.linux.sh

# Générer et exécuter
pwn shellcraft amd64.linux.sh -r
```

### Msfvenom (shellcodes)

```bash
# Lister les payloads linux x64
msfvenom -l payloads | grep 'linux/x64'

# Générer un shellcode exec sh
msfvenom -p 'linux/x64/exec' CMD='sh' -a 'x64' --platform 'linux' -f 'hex'

# Générer un shellcode encodé (bypass null bytes)
msfvenom -p 'linux/x64/exec' CMD='sh' -a 'x64' --platform 'linux' -f 'hex' -e 'x64/xor'
```
