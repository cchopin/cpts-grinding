# Tools - Shellcoding Workflow

Scripts utilitaires pour le workflow de shellcoding. Prérequis : `pwntools` (`pip3 install pwntools`).

## Workflow en 4 étapes

```
 program.s ──► assembler.sh ──► shellcoder.py ──► loader.py ──► assembler.py
  (code ASM)    (compile+run)    (extract sc)     (exec sc)     (sc -> ELF + gdb)
   étape 1        étape 2          étape 3         étape 4        si debug
```

### Étape 1 - Écrire le code ASM

```bash
vim program.s
```

### Étape 2 - Assembler et tester

```bash
./assembler.sh program.s
# -> assemble (nasm), link (ld), exécute le binaire
```

### Étape 3 - Extraire et valider le shellcode

```bash
python3 shellcoder.py program
# -> affiche le shellcode hex + vérifie les NULL bytes
# Si NULL bytes détectés : corriger le code ASM et recommencer étape 1
```

Alternative sans pwntools :
```bash
./shellcoder.sh program
```

### Étape 4 - Exécuter le shellcode en mémoire

```bash
python3 loader.py '4831db66bb...'
# -> charge et exécute le shellcode directement en mémoire
```

### Debug (optionnel) - Reconvertir en ELF pour gdb

```bash
python3 assembler.py '4831db66bb...' program_dbg
gdb -q ./program_dbg
(gdb) b *0x401000
(gdb) r
```

## Résumé des scripts

| Script | Input | Output | Description |
|--------|-------|--------|-------------|
| `assembler.sh` | `fichier.s` | binaire ELF | Assemble + link + exécute |
| `shellcoder.py` | binaire ELF | shellcode hex | Extrait `.text` + check NULL |
| `shellcoder.sh` | binaire ELF | shellcode hex | Idem via objdump (sans pwntools) |
| `loader.py` | shellcode hex | exécution | Charge en mémoire et exécute |
| `assembler.py` | shellcode hex + nom | binaire ELF | Reconstruit un ELF pour debug |
