#!/bin/bash
# Dynamic theme seed. Matugen writes themes/dynamic/.config and .cache, which
# are gitignored. themes/dynamic/baseline holds the shipped copies.
# Sourced by install/stow.sh and install/themes/hyprluggage.
# Run directly to re-seed: bash install/themes/dynamic-seed.sh [repo]

# Copy each baseline file whose live copy is missing. Never overwrites a file
# and never writes through a symlink: a dangling link is left alone (and
# reported by dynamic_seed_missing).
ensure_dynamic_seed() {
	local repo="$1" base live src rel dest
	base="$repo/themes/dynamic/baseline"
	live="$repo/themes/dynamic"
	[[ -d "$base" ]] || return 0
	while IFS= read -r -d '' src; do
		rel="${src#"$base"/}"
		dest="$live/$rel"
		if [[ -e "$dest" || -L "$dest" ]]; then
			continue
		fi
		if ! mkdir -p "$(dirname "$dest")" || ! cp -a "$src" "$dest"; then
			echo "dynamic seed: could not copy $rel" >&2
		fi
	done < <(find "$base" -type f -print0)
	return 0
}

# Print baseline-relative paths that have no usable live file (missing, or a
# dangling symlink). Prints nothing when the dynamic theme is complete.
dynamic_seed_missing() {
	local repo="$1" base live src rel
	base="$repo/themes/dynamic/baseline"
	live="$repo/themes/dynamic"
	[[ -d "$base" ]] || return 0
	while IFS= read -r -d '' src; do
		rel="${src#"$base"/}"
		if [[ ! -f "$live/$rel" ]]; then
			printf '%s\n' "$rel"
		fi
	done < <(find "$base" -type f -print0 | sort -z)
	return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	repo="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
	ensure_dynamic_seed "$repo"
	missing=$(dynamic_seed_missing "$repo")
	if [[ -n "$missing" ]]; then
		echo "still missing (remove any broken link there, then rerun):" >&2
		printf '  %s\n' "$missing" >&2
		exit 1
	fi
	echo "dynamic theme files present"
fi
