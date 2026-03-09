default:
    just --list

# Install compression tools
prep-png:
    which oxipng || brew install oxipng
    which optipng || brew install optipng
    which advpng || brew install advancecomp
    which pngquant || brew install pngquant

# [oxipng] Lossless compression using oxipng max + zopfli (best ratio, slower)
# Usage: just png-oxipng <dir>
png-oxipng dir:
    find "{{dir}}" -maxdepth 1 -name "*.png" -print0 | \
      xargs -0 -P $(nproc) -I {} \
      oxipng -o max --zopfli --strip all "{}"

# [oxipng] Lossless compression using oxipng max without zopfli (faster, for large files >10MB)
# Usage: just png-oxipng-fast <dir>
png-oxipng-fast dir:
    find "{{dir}}" -maxdepth 1 -name "*.png" -print0 | \
      xargs -0 -P $(nproc) -I {} \
      oxipng -o max --strip all "{}"

# [oxipng] Recursively compress all PNGs in a directory tree (auto: zopfli for small, fast for large)
# Usage: just png-oxipng-all <dir>
png-oxipng-all dir:
    #!/usr/bin/env bash
    set -euo pipefail
    total_before=0
    total_after=0
    while IFS= read -r -d '' f; do
        size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
        total_before=$((total_before + size))
        if [ "$size" -gt 5242880 ]; then
            # Large files (>5MB): use fast mode (no zopfli)
            echo "[large] $f"
            oxipng -o max --strip all "$f"
        else
            # Small files: use zopfli for best compression
            echo "[small] $f"
            oxipng -o max --zopfli --strip all "$f"
        fi
        size_after=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
        total_after=$((total_after + size_after))
    done < <(find "{{dir}}" -name "*.png" -print0)
    saved=$((total_before - total_after))
    echo ""
    echo "=== Summary ==="
    echo "Before: $((total_before / 1024)) KB"
    echo "After:  $((total_after / 1024)) KB"
    echo "Saved:  $((saved / 1024)) KB ($(( saved * 100 / total_before ))%)"

# [legacy] Original lossless compression (optipng + advpng) — superseded by png-oxipng
# Usage: just png-legacy <dir>
png-legacy dir:
    find "{{dir}}" -maxdepth 1 -name "*.png" -print0 | xargs -0 -P $(nproc) -I {} sh -c 'echo "Compressing: {}"; optipng -o7 -strip all "{}" && advpng -z4 "{}"'

# [lossy] Fast lossy compression using pngquant (95-100 quality)
# Usage: just png-fast <dir>
png-fast dir:
    #!/usr/bin/env bash
    for file in "{{dir}}"/*.png; do
        [ -f "$file" ] || continue
        echo "Compressing: $file"
        pngquant --quality=95-100 --skip-if-larger --ext .png --force "$file" || echo "Skipped $file (already optimized or can't improve)"
    done
