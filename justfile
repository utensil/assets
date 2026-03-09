default:
    just --list

# Install compression tools
prep-png:
    which oxipng || brew install oxipng
    which optipng || brew install optipng
    which advpng || brew install advancecomp
    which pngquant || brew install pngquant

# =============================================================================
# Proxy commands — delegate to recommended defaults
# =============================================================================

# Lossless compression (proxy → png-oxipng-all, auto size-routing)
png dir:
    just png-oxipng-all "{{dir}}"

# Fast lossless compression (proxy → png-oxipng-fast, no zopfli)
png-fast dir:
    just png-oxipng-fast "{{dir}}"

# Recursive all-files compression (proxy → png-oxipng-all)
png-all dir:
    just png-oxipng-all "{{dir}}"

# =============================================================================
# oxipng — recommended
# =============================================================================

# [oxipng] Lossless, oxipng max + zopfli (best ratio, slower; good for files <5MB)
# Usage: just png-oxipng <dir>
png-oxipng dir:
    find "{{dir}}" -maxdepth 1 -name "*.png" -print0 | \
      xargs -0 -P $(nproc) -I {} \
      oxipng -o max --zopfli --strip all "{}"

# [oxipng] Lossless, oxipng max without zopfli (faster; good for files >5MB)
# Usage: just png-oxipng-fast <dir>
png-oxipng-fast dir:
    find "{{dir}}" -maxdepth 1 -name "*.png" -print0 | \
      xargs -0 -P $(nproc) -I {} \
      oxipng -o max --strip all "{}"

# [oxipng] Recursive, auto size-routing: zopfli for small (<5MB), fast for large
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
            echo "[large] $f"
            oxipng -o max --strip all "$f"
        else
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

# =============================================================================
# Legacy — kept for reference
# =============================================================================

# [optipng] Lossless via optipng -o7 + advpng -z4 (largely ineffective on these assets)
# Usage: just png-optipng <dir>
png-optipng dir:
    find "{{dir}}" -maxdepth 1 -name "*.png" -print0 | \
      xargs -0 -P $(nproc) -I {} sh -c \
      'echo "Compressing: {}"; optipng -o7 -strip all "{}" && advpng -z4 "{}"'

# [pngquant] Lossy compression, quality 95-100 (skips if result is larger)
# Usage: just png-pngquant <dir>
png-pngquant dir:
    #!/usr/bin/env bash
    for file in "{{dir}}"/*.png; do
        [ -f "$file" ] || continue
        echo "Compressing: $file"
        pngquant --quality=95-100 --skip-if-larger --ext .png --force "$file" \
          || echo "Skipped $file (already optimized or can't improve)"
    done
