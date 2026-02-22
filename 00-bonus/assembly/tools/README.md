# Tools - Shellcoding Workflow

Scripts utilitaires pour le workflow de shellcoding. Prerequis : `pwntools` (`pip3 install pwntools`).

## Workflow en 4 etapes

```
 program.s ──► assembler.sh ──► shellcoder.py ──► loader.py ──► assembler.py
  (code ASM)    (compile+run)    (extract sc)     (exec sc)     (sc -> ELF + gdb)
   etape 1        etape 2          etape 3         etape 4        si debug
```

### Etape 1 - Ecrire le code ASM

```bash
vim program.s
```

### Etape 2 - Assembler et tester

```bash
./assembler.sh program.s
# -> assemble (nasm), link (ld), execute le binaire
```

### Etape 3 - Extraire et valider le shellcode

```bash
python3 shellcoder.py program
# -> affiche le shellcode hex + verifie les NULL bytes
# Si NULL bytes detectes : corriger le code ASM et recommencer etape 1
```

Alternative sans pwntools :
```bash
./shellcoder.sh program
```

### Etape 4 - Executer le shellcode en memoire

```bash
python3 loader.py '4831db66bb...'
# -> charge et execute le shellcode directement en memoire
```

### Debug (optionnel) - Reconvertir en ELF pour gdb

```bash
python3 assembler.py '4831db66bb...' program_dbg
gdb -q ./program_dbg
(gdb) b *0x401000
(gdb) r
```

## Resume des scripts

| Script | Input | Output | Description |
|--------|-------|--------|-------------|
| `assembler.sh` | `fichier.s` | binaire ELF | Assemble + link + execute |
| `shellcoder.py` | binaire ELF | shellcode hex | Extrait `.text` + check NULL |
| `shellcoder.sh` | binaire ELF | shellcode hex | Idem via objdump (sans pwntools) |
| `loader.py` | shellcode hex | execution | Charge en memoire et execute |
| `assembler.py` | shellcode hex + nom | binaire ELF | Reconstruit un ELF pour debug |
