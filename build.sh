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

mkdir -p "$BUILD_DIR/diagnostics"
LOCK_DIR="$BUILD_DIR/.build-lock"
mkdir "$LOCK_DIR" 2>/dev/null || fail "Another build or update is running: $LOCK_DIR"
trap 'rmdir "$LOCK_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
RUN_DIR=$(mktemp -d "$BUILD_DIR/diagnostics/run-XXXXXX")

build_cv() {
    local lang=$1 template=${2:-$TEMPLATE}
    for file in "src/cv-$lang.md" "src/partials/lang-$lang.tex"; do
        [ -r "$file" ] || { printf 'Required file not found: %s\n' "$file" >&2; return 1; }
    done
    printf 'Building %s...\n' "$lang"
    if ! pandoc "src/cv-$lang.md" --defaults pandoc.yaml --template "$template" \
            -H "src/partials/lang-$lang.tex" --verbose \
            -o "$RUN_DIR/cv-$NAME-$lang.pdf" > "$RUN_DIR/$lang.log" 2>&1; then
        printf 'Build failed (%s). Log: %s\n' "$lang" "$RUN_DIR/$lang.log" >&2
        return 1
    fi
}

build_both() {
    local template=${1:-$TEMPLATE}
    build_cv en "$template"
    build_cv pl "$template"
}

replace_pair() {
    local source_dir=$1 destination_dir=$2 backup="$RUN_DIR/backup" file
    local signal_status=0 result
    mkdir "$backup"
    for file in "$3" "$4"; do
        [ ! -L "$destination_dir/$file" ] ||
            fail "Cannot replace symbolic link: $destination_dir/$file"
        if [ -e "$destination_dir/$file" ]; then
            cp -p "$destination_dir/$file" "$backup/$file" ||
                fail "Cannot back up: $destination_dir/$file"
        fi
    done
    trap 'signal_status=130' INT
    trap 'signal_status=143' TERM
    if mv "$source_dir/$3" "$destination_dir/$3" &&
            mv "$source_dir/$4" "$destination_dir/$4"; then
        result=updated
    else
        # Keep restoration commands alive when a signal reaches the process group.
        for file in "$3" "$4"; do
            if [ -e "$backup/$file" ]; then
                (trap '' INT TERM; exec cp -p "$backup/$file" "$destination_dir/$file") ||
                    fail "Cannot restore files. Backups: $backup"
            else
                (trap '' INT TERM; exec rm -f "$destination_dir/$file") ||
                    fail "Cannot restore missing files. Backups: $backup"
            fi
        done
        result=restored
    fi
    trap 'exit 130' INT
    trap 'exit 143' TERM
    if [ "$signal_status" -ne 0 ]; then
        printf 'Interrupted; files %s. Diagnostics: %s\n' "$result" "$RUN_DIR" >&2
        exit "$signal_status"
    fi
    [ "$result" = updated ] ||
        fail "Replacement failed; previous files restored. Backups: $backup"
}

update_eisvogel() {
    python3 tools/update_eisvogel.py "$VERSION" "$RUN_DIR/update"
    build_both "$RUN_DIR/update/eisvogel.latex"
    replace_pair "$RUN_DIR/update" "$ROOT_DIR/src/templates" eisvogel.latex eisvogel.version.json
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
        if [ "$MODE" = --all ]; then
            replace_pair "$RUN_DIR" "$BUILD_DIR" "cv-$NAME-en.pdf" "cv-$NAME-pl.pdf"
        else
            mv "$RUN_DIR"/*.pdf "$BUILD_DIR/"
        fi
        printf 'Done. PDFs: %s\n' "$BUILD_DIR"
        ;;
esac
printf 'Logs: %s\n' "$RUN_DIR"
