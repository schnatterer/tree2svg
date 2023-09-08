#!/usr/bin/env bash

FULL_PATH="${1:-$PWD}"
FOLDER_NAME="$(basename "$FULL_PATH")"
LINE_COLOR="${2:-'#777'}" # black or #777 in bright mode, white for dark mode
ADDITIONAL_ARGS="${ADDITIONAL_ARGS:-}"
INTERACTIVE=${INTERACTIVE:-'false'}

TMP_DIR=$(mktemp -d)
deleteTmpDir() {
    rm -rf "$TMP_DIR"
}
trap deleteTmpDir EXIT

set -o nounset -o pipefail -o errexit

# -A Prints @ instead of NBSP (which html2svg cant handle)
# Note: tree -H would print as HTML. Clickable but not with bold folders
# Some errors in tree, no transparency, size too big
tree -C -A --noreport --dirsfirst $ADDITIONAL_ARGS "$FULL_PATH" > "$TMP_DIR/$FOLDER_NAME.tree"

if [[ $INTERACTIVE == 'true' ]]; then
  vipe < "$TMP_DIR/$FOLDER_NAME.tree" > "$TMP_DIR/$FOLDER_NAME.tree.tmp"
  mv "$TMP_DIR/$FOLDER_NAME.tree.tmp" "$TMP_DIR/$FOLDER_NAME.tree"
fi 

# Convert to HTML
aha -f "$TMP_DIR/$FOLDER_NAME.tree" | \
    sed "s|head>|head>\n<style>body {color: $LINE_COLOR}</style>|" | \
    sed 's|color:blue|color:#23A3DD|' \
    > "$TMP_DIR/$FOLDER_NAME.html"

# Convert to SVG and output to stdout
docker run --rm -v"$TMP_DIR":/in fathyb/html2svg:1.0.0 "file:///in/$FOLDER_NAME.html" |\
  sed '/<rect fill="white".*/d' |\
  sed 's/@/\xC2\xA0/g' 
# Replaces @ by ' '  or &nbsp; -> Avoids errors in tree created by htm2svg
# Removes huge <rect fill="white" width="1919" height="1079"/>