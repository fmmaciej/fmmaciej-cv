#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT_DIR"
NAME="organisciak-maciej"
BUILD_DIR="$ROOT_DIR/build"
TEMPLATE="$ROOT_DIR/src/templates/eisvogel.latex"

usage() {
    cat <<EOF
Usage: $0 --en | --pl | --all | --check | --update-eisvogel [VERSION] | --help
  --en                      Build build/cv-$NAME-en.pdf
  --pl                      Build build/cv-$NAME-pl.pdf
  --all                     Build both CVs (EN, then PL)
  --check                   Check Bash, run ShellCheck and trial builds
  --update-eisvogel [VERSION] Update the template (default: latest stable)
  -h, --help                Show this help
EOF
}

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
require_command() { command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"; }

MODE=${1:-}
case "$MODE" in
    --en|--pl|--all|--check|-h|--help) valid_count=1 ;;
    --update-eisvogel) valid_count=2 ;;
    *) usage >&2; exit 2 ;;
esac
if [ "$#" -gt "$valid_count" ]; then
    usage >&2
    exit 2
fi
VERSION=${2:-latest}
if [ "$MODE" = --update-eisvogel ] && [ "$VERSION" != latest ] &&
        [[ ! $VERSION =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    usage >&2
    exit 2
fi
if [ "$MODE" = --help ] || [ "$MODE" = -h ]; then
    usage
    exit 0
fi

require_command pandoc
require_command xelatex
if [ "$MODE" = --check ]; then require_command shellcheck; fi
if [ "$MODE" = --update-eisvogel ]; then
    require_command python3
    require_command curl
fi
for file in pandoc.yaml src/templates/eisvogel.latex src/partials/{preamble,identity,header}.tex; do
    [ -r "$file" ] || fail "Required file not found: $file"
done

mkdir -p "$BUILD_DIR"
LOCK_DIR="$BUILD_DIR/.build-lock"
mkdir "$LOCK_DIR" 2>/dev/null || fail "Another build or update is running: $LOCK_DIR"
RUN_DIR=
cleanup() {
    if [ -n "$RUN_DIR" ]; then
        rm -rf "$RUN_DIR" || true
    fi
    rmdir "$LOCK_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
RUN_DIR=$(mktemp -d "$BUILD_DIR/.work-XXXXXX")

build_cv() {
    local lang=$1 template=${2:-$TEMPLATE}
    local log="$BUILD_DIR/$lang.log"
    for file in "src/cv-$lang.md" "src/partials/lang-$lang.tex"; do
        [ -r "$file" ] || { printf 'Required file not found: %s\n' "$file" >&2; return 1; }
    done
    printf 'Building %s... Log: %s\n' "$lang" "$log"
    if ! pandoc "src/cv-$lang.md" --defaults pandoc.yaml --template "$template" \
            -H "src/partials/lang-$lang.tex" --verbose \
            -o "$RUN_DIR/cv-$NAME-$lang.pdf" > "$log" 2>&1; then
        printf 'Build failed (%s). Log: %s\n' "$lang" "$log" >&2
        return 1
    fi
}

build_both() {
    local template=${1:-$TEMPLATE}
    build_cv en "$template"
    build_cv pl "$template"
}

update_eisvogel() {
    local file
    python3 tools/update_eisvogel.py "$VERSION" "$RUN_DIR/update"
    build_both "$RUN_DIR/update/eisvogel.latex"
    for file in eisvogel.latex eisvogel.version.json; do
        [ ! -L "$ROOT_DIR/src/templates/$file" ] ||
            fail "Cannot replace symbolic link: $ROOT_DIR/src/templates/$file"
        mv "$RUN_DIR/update/$file" "$ROOT_DIR/src/templates/$file"
    done
    printf 'Template updated. Run --all to rebuild the published PDFs.\n'
}

case "$MODE" in
    --check)
        bash -n build.sh
        shellcheck build.sh
        build_both
        printf 'Checks passed; published PDFs preserved.\n'
        ;;
    --update-eisvogel) update_eisvogel ;;
    *)
        case "$MODE" in
            --en) build_cv en ;;
            --pl) build_cv pl ;;
            --all) build_both ;;
        esac
        for file in "$RUN_DIR"/*.pdf; do
            [ ! -L "$BUILD_DIR/${file##*/}" ] ||
                fail "Cannot replace symbolic link: $BUILD_DIR/${file##*/}"
            mv "$file" "$BUILD_DIR/"
        done
        printf 'Done. PDFs: %s\n' "$BUILD_DIR"
        ;;
esac
