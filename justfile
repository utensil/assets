default:
    just --list

prep-png:
    which optipng || brew install optipng
    which advpng || brew install advancecomp
    which pngquant || brew install pngquant

png dir:
    find "{{dir}}" -maxdepth 1 -name "*.png" -print0 | xargs -0 -P $(nproc) -I {} sh -c 'echo "Compressing: {}"; optipng -o7 -strip all "{}" && advpng -z4 "{}"'

png-fast dir:
    #!/usr/bin/env bash
    for file in "{{dir}}"/*.png; do
        [ -f "$file" ] || continue
        echo "Compressing: $file"
        pngquant --quality=95-100 --skip-if-larger --ext .png --force "$file" || echo "Skipped $file (already optimized or can't improve)"
    done


