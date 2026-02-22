#!/usr/bin/python3
"""Charge et execute un shellcode directement en memoire.

Usage : python3 loader.py '<shellcode_hex>'
Exemple : python3 loader.py '4831db66bb7921...0f05'

Etape typique : 3/4 du workflow shellcoding
Apres avoir extrait et valide le shellcode (pas de NULL bytes),
on le charge en memoire pour verifier qu'il fonctionne.
"""
import sys
from pwn import *

context(os="linux", arch="amd64", log_level="error")

if len(sys.argv) < 2:
    print("Usage: python3 loader.py '<shellcode_hex>'")
    sys.exit(1)

run_shellcode(unhex(sys.argv[1])).interactive()
