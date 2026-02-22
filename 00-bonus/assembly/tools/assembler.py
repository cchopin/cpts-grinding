#!/usr/bin/python3
"""Construit un binaire ELF executable a partir d'un shellcode.

Utile pour debugger un shellcode avec gdb (b *0x401000).

Usage : python3 assembler.py '<shellcode_hex>' <output_binary>
Exemple : python3 assembler.py '4831db...0f05' helloworld_dbg

Etape typique : 4/4 du workflow shellcoding (optionnel)
Si le shellcode ne fonctionne pas comme prevu, on le reconvertit
en binaire ELF pour le debugger pas a pas avec gdb.
"""
import sys, os, stat
from pwn import *

context(os="linux", arch="amd64", log_level="error")

if len(sys.argv) < 3:
    print("Usage: python3 assembler.py '<shellcode_hex>' <output_binary>")
    sys.exit(1)

ELF.from_bytes(unhex(sys.argv[1])).save(sys.argv[2])
os.chmod(sys.argv[2], stat.S_IEXEC)
print("[+] Built: %s" % sys.argv[2])
