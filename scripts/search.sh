#!/usr/bin/env bash
#
# search.sh - Recherche rapide dans les cheatsheets et notes du repo
#
# Usage:
#   ./scripts/search.sh              # mode interactif (fzf)
#   ./scripts/search.sh <keyword>    # recherche directe
#   ./scripts/search.sh -s smb       # recherche par section (titres)
#   ./scripts/search.sh -f nmap      # recherche dans les fichiers (noms)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo -e "${BOLD}Usage:${NC}"
    echo "  search.sh                  Mode interactif (fzf)"
    echo "  search.sh <keyword>        Recherche dans tout le contenu"
    echo "  search.sh -s <keyword>     Recherche par section (titres #)"
    echo "  search.sh -f <keyword>     Recherche dans les noms de fichiers"
    echo ""
    echo -e "${BOLD}Exemples:${NC}"
    echo "  search.sh nmap             Toutes les lignes contenant 'nmap'"
    echo "  search.sh reverse shell    Cherche 'reverse shell'"
    echo "  search.sh -s privesc       Sections contenant 'privesc'"
    echo "  search.sh -f transfer      Fichiers contenant 'transfer'"
}

# Recherche dans le contenu avec grep, formatée proprement
search_content() {
    local query="$1"
    grep -rni --include="*.md" --color=always "$query" "$REPO_ROOT" \
        | sed "s|$REPO_ROOT/||" \
        | while IFS= read -r line; do
            local file="${line%%:*}"
            local rest="${line#*:}"
            echo -e "${CYAN}${file}${NC}:${rest}"
        done
}

# Recherche par titres/sections uniquement
search_sections() {
    local query="$1"
    grep -rni --include="*.md" "^#.*$query" "$REPO_ROOT" \
        | sed "s|$REPO_ROOT/||" \
        | while IFS= read -r line; do
            local file="${line%%:*}"
            local rest="${line#*:}"
            echo -e "${GREEN}${file}${NC}:${rest}"
        done
}

# Recherche dans les noms de fichiers
search_files() {
    local query="$1"
    find "$REPO_ROOT" -name "*.md" -path "*${query}*" \
        | sed "s|$REPO_ROOT/||" \
        | sort \
        | while IFS= read -r file; do
            echo -e "${YELLOW}${file}${NC}"
        done
}

# Mode interactif avec fzf
interactive_search() {
    if ! command -v fzf &>/dev/null; then
        echo -e "${RED}fzf non installé.${NC} Installe-le avec : brew install fzf / apt install fzf"
        echo ""
        echo "En attendant, utilise : ./scripts/search.sh <keyword>"
        exit 1
    fi

    # Prépare toutes les lignes de contenu avec fichier:ligne:contenu
    grep -rn --include="*.md" "" "$REPO_ROOT" \
        | sed "s|$REPO_ROOT/||" \
        | fzf \
            --ansi \
            --delimiter=':' \
            --preview "file=\"$REPO_ROOT/{1}\"; line={2}; start=\$((line > 5 ? line - 5 : 1)); end=\$((line + 15)); sed -n \"\${start},\${end}p\" \"\$file\"" \
            --preview-window=right:50%:wrap \
            --header="Recherche dans les cheatsheets (ESC pour quitter)" \
            --bind="enter:accept" \
            --color="header:yellow,pointer:green,marker:cyan"
}

# --- Main ---

# Pas d'arguments -> mode interactif
if [[ $# -eq 0 ]]; then
    interactive_search
    exit 0
fi

# Parse les options
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    -s)
        shift
        [[ $# -eq 0 ]] && { echo "Erreur: -s nécessite un mot-clé"; exit 1; }
        search_sections "$*"
        ;;
    -f)
        shift
        [[ $# -eq 0 ]] && { echo "Erreur: -f nécessite un mot-clé"; exit 1; }
        search_files "$*"
        ;;
    *)
        search_content "$*"
        ;;
esac
