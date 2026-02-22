#!/usr/bin/python3
"""Extrait le shellcode (section .text) d'un binaire ELF.

Verifie la presence de NULL bytes et affiche la taille.

Usage : python3 shellcoder.py <binary>
Exemple : python3 shellcoder.py helloworld

Etape typique : 2/4 du workflow shellcoding
Apres avoir assemble le binaire avec assembler.sh, on extrait son shellcode.
"""
import sys
from pwn import *

context(os="linux", arch="amd64", log_level="error")

if len(sys.argv) < 2:
    print("Usage: python3 shellcoder.py <binary>")
    sys.exit(1)

file = ELF(sys.argv[1])
shellcode = file.section(".text")
print(shellcode.hex())

if [i for i in shellcode if i == 0]:
    print("%d bytes - ATTENTION : Found NULL byte" % len(shellcode))
else:
    print("%d bytes - No NULL bytes" % len(shellcode))
