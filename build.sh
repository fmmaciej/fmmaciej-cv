#!/usr/bin/env bash
set -euo pipefail

TEMPLATE="src/templates/eisvogel.latex"
ASSETS=".:assets:src"
BUILD_DIR="build"
PARTIALS_DIR="src/partials"

PDF_ENGINE=xelatex

mkdir -p "$BUILD_DIR"

usage() {
    cat <<EOF
Usage: $0 [--en | --pl | --all]

Options:
  --en      Build English CV (cv-en.pdf)
  --pl      Build Polish CV (cv-pl.pdf)
  --all     Build both versions

Requirements:
  - Pandoc
  - LaTeX distribution with XeLaTeX engine (TeX Live or MacTeX or MiKTeX)
  - LaTeX packages commonly required by Eisvogel template:
EOF
    exit 1
}

build_cv() {
    local lang=$1
    local src="src/cv-$lang.md"
    local out="$BUILD_DIR/cv-$lang.pdf"

    local header="$PARTIALS_DIR/header.tex"
    local preamble="$PARTIALS_DIR/preamble.tex"
    local identity="$PARTIALS_DIR/identity.tex"
    local langfile="$PARTIALS_DIR/lang-$lang.tex"

    echo "Building $out..."
    pandoc "$src" -o "$out" \
        --from markdown \
        --template "$TEMPLATE" \
        --pdf-engine="$PDF_ENGINE" \
        --resource-path="$ASSETS" \
        -H "$preamble" \
        -H "$identity" \
        -H "$langfile" \
        --include-before-body="$header"
    echo "Done: $out"
}

case "${1:-}" in
    --en)
        build_cv en
        ;;
    --pl)
        build_cv pl
        ;;
    --all)
        build_cv en
        build_cv pl
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Unknown option: ${1:-}"
        usage
        ;;
esac
