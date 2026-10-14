#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 5 ]; then
  echo "usage: $0 <tag> <release-id-or-empty> <run-id-or-empty> <destination> <pattern>..." >&2
  exit 2
fi

tag=$1
release_id=$2
run_id=$3
destination=$4
shift 4
patterns=("$@")

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"

mkdir -p "$destination"

if [ -n "$run_id" ]; then
  run_path="repos/$GITHUB_REPOSITORY/actions/runs/$run_id"
  run_metadata=$(gh api "$run_path" --jq '[.path, .status, .conclusion] | @tsv')
  IFS=$'\t' read -r run_workflow run_status run_conclusion <<< "$run_metadata"
  if [ "$run_workflow" != ".github/workflows/publish-linux-desktop.yml" ] \
    || [ "$run_status" != "completed" ] \
    || [ "$run_conclusion" != "success" ]; then
    echo "run $run_id is not a successful publish-linux-desktop workflow run" >&2
    exit 1
  fi
  gh run download "$run_id" -R "$GITHUB_REPOSITORY" \
    -n draft-release-assets -D "$destination"
elif [ -z "$release_id" ]; then
  args=(release download "$tag" -R "$GITHUB_REPOSITORY" -D "$destination")
  for pattern in "${patterns[@]}"; do
    args+=(-p "$pattern")
  done
  gh "${args[@]}"
else
  release_path="repos/$GITHUB_REPOSITORY/releases/$release_id"
  actual_tag=$(gh api "$release_path" --jq '.tag_name')
  if [ "$actual_tag" != "$tag" ]; then
    echo "release id $release_id has tag $actual_tag, expected $tag" >&2
    exit 1
  fi

  assets=$(gh api "$release_path" --jq '.assets[] | [.id, .name, .size] | @tsv')
  while IFS=$'\t' read -r asset_id asset_name asset_size; do
    [ -n "$asset_id" ] || continue
    for pattern in "${patterns[@]}"; do
      if [[ "$asset_name" == $pattern ]]; then
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
    done
  done <<< "$assets"
fi

for pattern in "${patterns[@]}"; do
  matched=0
  while IFS= read -r asset_path; do
    if [[ "$(basename "$asset_path")" == $pattern ]]; then
      matched=$((matched + 1))
    fi
  done < <(find "$destination" -type f -print)
  if [ "$matched" -ne 1 ]; then
    echo "downloaded assets contain $matched files matching $pattern, expected 1" >&2
    exit 1
  fi
done
