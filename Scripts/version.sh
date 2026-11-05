#!/bin/sh
# Engine version numbering: MAJOR.MINOR.PATCH, kept in Sources/Engine/Core/EngineVersion.swift.
#
#   Scripts/version.sh                  print the version
#   Scripts/version.sh install          set up the git hook and merge driver (once per clone)
#   Scripts/version.sh major            bump MAJOR (X+1.0.0): the developer's call, never automatic
#   Scripts/version.sh minor | patch    force a MINOR / PATCH bump
#   Scripts/version.sh set 1.2.3        set it outright
#   Scripts/version.sh auto             what the pre-commit hook runs (see below)
#
# Automatic bumps (pre-commit hook, at most one per commit, from what is staged):
#   - MINOR when the public API of Engine / EngineMCP changed: the hash of their `public` /
#     `open` declaration lines (comments and bodies stripped, sorted) differs from the last one.
#   - PATCH when anything else under Sources/ or Package.swift changed: the hash of the staged
#     file list with blob ids differs. Tests, docs, assets and projects don't count.
# The hashes are kept in .engine-version. A commit whose version was already changed by hand
# (differs from HEAD's) is not bumped again; its hashes are just recorded.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)  # not `git rev-parse`: in a linked worktree hooks get GIT_DIR, which makes that the cwd
cd "$ROOT"
VERSION_FILE=Sources/Engine/Core/EngineVersion.swift
STATE_FILE=.engine-version
EXCLUDE=":(exclude)$VERSION_FILE"

# The version in a Swift file (stdin when no argument).
version_in() { sed -n 's/.*static let current = "\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' "$@" | head -n 1; }

write_version() {  # file version
    sed "s/\(static let current = \)\"[0-9]*\.[0-9]*\.[0-9]*\"/\1\"$2\"/" "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

max_version() { printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1; }

bump() {  # version part
    major=${1%%.*}; rest=${1#*.}; minor=${rest%%.*}; patch=${rest#*.}
    case $2 in
        major) echo "$((major + 1)).0.0" ;;
        minor) echo "$major.$((minor + 1)).0" ;;
        patch) echo "$major.$minor.$((patch + 1))" ;;
    esac
}

source_hash() { git ls-files -s -- Sources Package.swift "$EXCLUDE" | git hash-object --stdin; }

api_hash() {
    { git grep --cached -h -I -E \
        '^[^/"]*(^|[[:space:]])(public[[:space:]]|open[[:space:]]+(class|func|var|override|subscript|static|final))' \
        -- Sources/Engine Sources/EngineMCP "$EXCLUDE" || true; } |
        sed -e 's://.*$::' -e 's/[[:space:]]*{.*$//' -e 's/[[:space:]][[:space:]]*/ /g' -e 's/^ //' -e 's/ $//' |
        LC_ALL=C sort | git hash-object --stdin
}

state() { [ -f "$STATE_FILE" ] && sed -n "s/^$1=//p" "$STATE_FILE" || true; }

record_state() {
    printf '# Scripts/version.sh: hashes of the last versioned sources (see that script).\napi=%s\nsource=%s\n' \
        "$1" "$2" > "$STATE_FILE"
}

current=$(version_in "$VERSION_FILE")
[ -n "$current" ] || { echo "version.sh: no 'static let current = \"x.y.z\"' in $VERSION_FILE" >&2; exit 1; }

case ${1:-show} in
show)
    echo "$current" ;;

major | minor | patch)
    new=$(bump "$current" "$1")
    write_version "$VERSION_FILE" "$new"
    echo "$current -> $new" ;;

set)
    echo "${2:-}" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo "usage: version.sh set MAJOR.MINOR.PATCH" >&2; exit 1; }
    write_version "$VERSION_FILE" "$2"
    echo "$current -> $2" ;;

auto)
    api=$(api_hash); src=$(source_hash)
    old_api=$(state api); old_src=$(state source)
    head=$(git show "HEAD:$VERSION_FILE" 2>/dev/null | version_in || true)
    staged=$(git show ":$VERSION_FILE" 2>/dev/null | version_in)
    staged=${staged:-$current}
    if [ -z "$old_api" ] || { [ -n "$head" ] && [ "$staged" != "$head" ]; }; then
        :  # first run, or bumped by hand in this commit: only record the hashes
    elif [ "$api" != "$old_api" ]; then
        new=$(bump "$staged" minor)
    elif [ "$src" != "$old_src" ]; then
        new=$(bump "$staged" patch)
    else
        exit 0
    fi
    if [ -n "${new:-}" ]; then
        write_version "$VERSION_FILE" "$new"
        git add "$VERSION_FILE"
        echo "engine version $staged -> $new ($([ "$api" != "$old_api" ] && echo "public API changed" || echo "sources changed"))"
    fi
    record_state "$api" "$src"
    git add "$STATE_FILE" ;;

install)
    git config core.hooksPath Scripts/git-hooks
    git config merge.engine-version.name "engine version: keep the higher version"
    git config merge.engine-version.driver 'Scripts/version.sh merge-driver %O %A %B %P'
    echo "Installed: pre-commit hook (Scripts/git-hooks) and the engine-version merge driver." ;;

merge-driver)
    # Merging two branches that both bumped: take the higher version, merge the rest as usual.
    # The state file keeps ours (the next commit rehashes the merged sources anyway).
    base=$2; ours=$3; theirs=$4; path=${5:-}
    [ "$path" = "$STATE_FILE" ] && exit 0
    top=$(max_version "$(version_in "$ours")" "$(version_in "$theirs")")
    for f in "$base" "$ours" "$theirs"; do [ -n "$(version_in "$f")" ] && write_version "$f" "$top"; done
    git merge-file "$ours" "$base" "$theirs" ;;

*)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 1 ;;
esac
