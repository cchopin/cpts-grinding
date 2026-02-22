#!/bin/bash
# Assemble et link un fichier .s en executable ELF, puis l'execute.
#
# Usage : ./assembler.sh <fichier.s>
# Exemple : ./assembler.sh helloworld.s
#
# Etape typique : 1/4 du workflow shellcoding
# Apres avoir ecrit le code ASM, ce script le compile et le teste.

if [ -z "$1" ]; then
    echo "Usage: $0 <fichier.s>"
    exit 1
fi

nasm -f elf64 "$1" -o "${1%.s}.o" && \
ld -o "${1%.s}" "${1%.s}.o" && \
rm "${1%.s}.o" && \
echo "[+] Assembled: ${1%.s}" && \
./"${1%.s}"
