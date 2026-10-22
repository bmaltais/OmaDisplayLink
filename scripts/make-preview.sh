#!/usr/bin/env bash
# Compose preview.png, the marketplace's picture of OmaDisplayLink, from the captures in screenshots/: the
# setup terminal, the card in four states and the bar icon states, on a dark gradient with a badge, the
# name and a tagline.
#
#   scripts/make-preview.sh [OUT]      (default: preview.png at the repo root)
#
# Needs ImageMagick. The crops below follow each capture's margins (a card is a 1px border at x=87,y=26 in
# a capture taken by scripts/dev with the card open), so retake the captures and revisit the numbers if the
# card's size changes.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
shots=$repo/screenshots
out=${1:-$repo/preview.png}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
font=/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf
[[ -f $font ]] || font=DejaVu-Sans-Bold

# The shadow makes each card's image bigger than the card; this is how far the card sits from the top left of
# that image, so a card can be placed by its own corner (measured for this blur and offset).
pad_x=45
pad_y=29
at() { echo "+$(($1 - pad_x))+$(($2 - pad_y))"; }

# card IN OUT CROP SCALE% RADIUS: crop, scale, round the corners and add a shadow.
card() {
  local in=$1 dest=$2 crop=$3 scale=$4 r=$5 w h
  magick "$in" -crop "$crop" +repage -resize "$scale%" "$work/c.png"
  w=$(magick identify -format %w "$work/c.png"); h=$(magick identify -format %h "$work/c.png")
  magick "$work/c.png" -alpha set \
    \( -size "${w}x${h}" xc:none -fill white -draw "roundrectangle 0,0 $((w - 1)),$((h - 1)) $r,$r" \) \
    -compose DstIn -composite "$work/r.png"
  magick "$work/r.png" \( +clone -background black -shadow 70x22+0+16 \) +swap -background none -layers merge +repage "$dest"
}

card "$shots/setup-steps.png"        "$work/steps.png"  780x540+0+0    88 10
card "$shots/card-not-installed.png" "$work/c-not.png"  340x277+87+26 100 8
card "$shots/card-attention.png"     "$work/c-attn.png" 340x312+87+26 100 8
card "$shots/card-working.png"       "$work/c-ok.png"   340x207+87+26 100 8
card "$shots/card-log-out.png"       "$work/c-out.png"  340x312+87+26 100 8
card "$shots/icon-states.png"        "$work/icons.png"  1000x112+0+0   66 8

# The badge above the name: a pill sized to its text.
magick -background none -fill '#cfe0ff' -font "$font" -pointsize 22 \
  label:"An Omarchy plugin" -trim +repage "$work/badge-text.png"
bw=$(( $(magick identify -format %w "$work/badge-text.png") + 40 ))
bh=$(( $(magick identify -format %h "$work/badge-text.png") + 20 ))
magick -size "${bw}x${bh}" xc:none -fill 'rgba(255,255,255,0.12)' -draw "roundrectangle 0,0 $((bw - 1)),$((bh - 1)) $((bh / 2)),$((bh / 2))" \
  -stroke 'rgba(160,190,255,0.5)' -strokewidth 1 -fill none -draw "roundrectangle 0,0 $((bw - 1)),$((bh - 1)) $((bh / 2)),$((bh / 2))" \
  "$work/badge-text.png" -gravity center -compose over -composite "$work/badge.png"

magick -size 1600x900 radial-gradient:'#16213f-#080a14' \
  \( -size 1200x1200 radial-gradient:'rgba(224,120,50,0.38)-rgba(224,120,50,0)' \) -geometry +820-520 -compose plus -composite \
  \( -size 1100x1100 radial-gradient:'rgba(70,120,230,0.42)-rgba(70,120,230,0)' \) -geometry -420+380 -compose plus -composite \
  -compose over \
  -font "$font" -fill white -pointsize 84 -annotate +72+168 "OmaDisplayLink" \
  -fill '#b9ccff' -pointsize 30 -annotate +78+222 "DisplayLink docks, set up from the bar" \
  "$work/badge.png" -geometry +76+36 -composite \
  "$work/steps.png"  -geometry "$(at 56 290)" -composite \
  "$work/icons.png"  -geometry "$(at 72 792)" -composite \
  "$work/c-not.png"  -geometry "$(at 830 70)" -composite \
  "$work/c-ok.png"   -geometry "$(at 830 410)" -composite \
  "$work/c-attn.png" -geometry "$(at 1210 150)" -composite \
  "$work/c-out.png"  -geometry "$(at 1210 510)" -composite \
  "$out"
echo "Wrote $out"
