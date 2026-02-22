#!/bin/bash
# Extrait le shellcode d'un binaire via objdump.
# Methode alternative a shellcoder.py (ne necessite pas pwntools).
#
# Usage : ./shellcoder.sh <binary>
# Exemple : ./shellcoder.sh helloworld

if [ -z "$1" ]; then
    echo "Usage: $0 <binary>"
    exit 1
fi

for i in $(objdump -d "$1" | grep "^ " | cut -f2); do echo -n $i; done; echo;
