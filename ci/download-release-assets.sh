#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "usage: $0 <tag> <release-id-or-empty> <destination> <pattern>..." >&2
  exit 2
fi

tag=$1
release_id=$2
destination=$3
shift 3
patterns=("$@")

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"

mkdir -p "$destination"

if [ -z "$release_id" ]; then
  args=(release download "$tag" -R "$GITHUB_REPOSITORY" -D "$destination")
  for pattern in "${patterns[@]}"; do
    args+=(-p "$pattern")
  done
  gh "${args[@]}"
  exit 0
fi

release_path="repos/$GITHUB_REPOSITORY/releases/$release_id"
actual_tag=$(gh api "$release_path" --jq '.tag_name')
if [ "$actual_tag" != "$tag" ]; then
  echo "release id $release_id has tag $actual_tag, expected $tag" >&2
  exit 1
fi

assets=$(gh api "$release_path" --jq '.assets[] | [.id, .name, .size] | @tsv')
for pattern in "${patterns[@]}"; do
  matched=0
  while IFS=$'\t' read -r asset_id asset_name asset_size; do
    [ -n "$asset_id" ] || continue
    if [[ "$asset_name" == $pattern ]]; then
      matched=$((matched + 1))
      output="$destination/$asset_name"
      gh api \
        -H 'Accept: application/octet-stream' \
        "repos/$GITHUB_REPOSITORY/releases/assets/$asset_id" > "$output"
      actual_size=$(stat -c '%s' "$output")
      if [ "$actual_size" -ne "$asset_size" ]; then
        echo "$asset_name has $actual_size bytes, expected $asset_size" >&2
        exit 1
      fi
    fi
  done <<< "$assets"
  if [ "$matched" -ne 1 ]; then
    echo "release id $release_id has $matched assets matching $pattern, expected 1" >&2
    exit 1
  fi
done
