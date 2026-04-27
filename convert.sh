#! /usr/bin/env bash
# convert.sh — converts posts_md/*.md → blog/posts/*.html
# Requires: pandoc  (sudo apt install pandoc)
# Usage:    ./convert.sh

set -euo pipefail

TEMPLATE="templates/post.html"
INPUT_DIR="posts_md"
OUTPUT_DIR="blog/posts"

# ── Sanity checks ─────────────────────────────────
command -v pandoc &>/dev/null || {
    echo "✗ pandoc not found — install with: sudo apt install pandoc"
    exit 1
}

[[ -f "$TEMPLATE" ]] || {
    echo "✗ Template not found: $TEMPLATE"
    exit 1
}

mkdir -p "$OUTPUT_DIR"

shopt -s nullglob
files=("$INPUT_DIR"/*.md)

if [[ ${#files[@]} -eq 0 ]]; then
    echo "No .md files found in $INPUT_DIR"
    exit 0
fi

# ── Convert ───────────────────────────────────────
for file in "${files[@]}"; do
    filename=$(basename "$file" .md)

    # Strip leading date prefix from filename for output
    # e.g. 2024-03-22-my-post  →  my-post
    slug=$(echo "$filename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')

    output="$OUTPUT_DIR/${slug}.html"

    pandoc "$file" \
        --from       markdown+yaml_metadata_block \
        --to         html5 \
        --template   "$TEMPLATE" \
        --highlight-style=zenburn \
        --output     "$output"

    echo "✓  $filename  →  $output"
done

echo ""
echo "Done — ${#files[@]} post(s) built into $OUTPUT_DIR/"
echo "Run: git add . && git commit -m 'new post' && git push"
