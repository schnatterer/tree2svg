#!/usr/bin/env bash

FULL_PATH="${1:-$PWD}"
FOLDER_NAME="$(basename "$FULL_PATH")"
LINE_COLOR="${LINE_COLOR:-'#777'}" # black or #777 in bright mode, white for dark mode
ADDITIONAL_ARGS="${ADDITIONAL_ARGS:-}" 
INTERACTIVE=${INTERACTIVE:-'false'}

TMP_DIR=$(mktemp -d)
deleteTmpDir() {
    rm -rf  "$TMP_DIR"
}
trap deleteTmpDir EXIT

set -o nounset -o pipefail -o errexit


# Create tree and remove trailing count/report as there seems to be no option for it
erd --color=force \
  --suppress-size \
  --icons \
  --dir-order=last \
  --layout=inverted \
  --sort=name \
  --hidden \
  --no-progress \
  --no-config \
  ${ADDITIONAL_ARGS} \
  "$FULL_PATH" | \
    head -n -1 > "$TMP_DIR/$FOLDER_NAME.tree"

if [[ $INTERACTIVE == 'true' ]]; then
  vipe < "$TMP_DIR/$FOLDER_NAME.tree" > "$TMP_DIR/$FOLDER_NAME.tree.tmp"
  mv "$TMP_DIR/$FOLDER_NAME.tree.tmp" "$TMP_DIR/$FOLDER_NAME.tree"
fi 

# Convert to HTML
# Replace all spaces with @ because html2svg seems not to be able these
# Include Twemoji to render emojis as SVGs
# Include Font-Awesome, so the FA glyphs are rendered as SVGs
# Add Git icon for root of the tree
# Ignore gitkeep files
# TODO find an easier way to handle nerd fonts instead of replacing icons
aha -f "$TMP_DIR/$FOLDER_NAME.tree" | \
    sed '/\.gitkeep/d' | \
    sed 's|color:blue|color:#23A3DD|g' | \
    sed "s|color:purple|color:$LINE_COLOR|g" |
    sed -e '/<pre>/,/<\/pre>/ s/ /@/g' |\
    sed 's||⚙|g' |\
    sed 's||📁|g' |\
    sed 's||<i class="fas fa-unlock"></i>|g' |\
    sed 's||<i class="fas fa-file"></i>|g' |\
    sed 's|謹|<i class="fas fa-code"></i>|g' |\
    sed 's||<i class="fab fa-git"></i>|g' |\
    sed 's||<i class="fas fa-terminal"></i>|g' |\
    sed 's||<i class="fas fa-key"></i>|g' |\
    sed 's|󰗀|<i class="fas fa-code"></i>|g' |\
    sed 's|󰜡|<i class="fas fa-code"></i>|g' |\
    sed 's||<i class="fab fa-html5"></i>|g' |\
    sed 's||<i class="fab fa-markdown" style="color:grey;"></i>|g' |\
    sed 's||🐋|g' |\
    sed 's||{}|g' |\
    sed 's|span@style|span style|g' | \
    sed -e "s/<head>/<head><style type=\"text\/css\">body { color: $LINE_COLOR }<\/style>\n/g" | \
    sed 's/<\/body>/<script src="https:\/\/unpkg.com\/twemoji@latest\/dist\/twemoji.min.js" crossorigin="anonymous"><\/script>\n<script>twemoji.parse(document.body, { folder: \x27svg\x27, ext: \x27.svg\x27 } )<\/script>\n<\/body>/g' | \
    sed 's/<head>/<head><style type="text\/css">img.emoji { height: 1em; width: 1em; margin: 0 .05em 0 .1em; vertical-align: -0.1em;}<\/style>\n/g' | \
    sed 's/<\/body>/<script src="https:\/\/cdnjs.cloudflare.com\/ajax\/libs\/font-awesome\/5.15.4\/js\/all.min.js"><\/script>\n<\/body>/g' | \
    sed 's/<head>/<head><link rel="stylesheet" href="https:\/\/cdnjs.cloudflare.com\/ajax\/libs\/font-awesome\/5.15.4\/css\/all.min.css"\/>\n/g' | \
    sed '/<pre>/,/<\/pre>/ s/@<span style="font-weight:bold;color:#23A3DD;">📁/@<span style="font-weight:bold;color:#23A3DD;"><i class="fab fa-git-alt fa-lg"><\/i>/g' \
    > "$TMP_DIR/$FOLDER_NAME.html"

# Convert to SVG and output to stdout
docker run --rm -v"$TMP_DIR":/in fathyb/html2svg:1.0.0 "file:///in/$FOLDER_NAME.html" |\
  sed '/<rect fill="white".*/d' |\
  sed 's/@/\xC2\xA0/g'
