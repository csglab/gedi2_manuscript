#!/bin/bash

# Path to your text file with URLs
LINK_FILE="download_urls.txt"

# Output directory
OUTDIR="Allen-brain-10X-V3"

# Create directory if not exists
mkdir -p "$OUTDIR"

# Loop over each line in the file
while IFS= read -r url; do
    # Skip empty lines
    [[ -z "$url" ]] && continue

    echo "Downloading: $url"
    wget -P "$OUTDIR" "$url"
done < "$LINK_FILE"

echo "Done!"

