#!/bin/bash
# Markdownファイルからbase64画像を抽出して別ファイルに保存
# doclingが埋め込んだbase64画像を削除してMarkdownをクリーンにする
#
# Usage: bash extract_images_from_md.sh <MD_FILE>
# Example: bash extract_images_from_md.sh "/tmp/doc.md"
# Output: 画像は /tmp/doc_images/ に保存、元のMDファイルは上書き

set -e

if [ $# -lt 1 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <MD_FILE>" >&2
    exit 1
fi

MD_FILE="$1"

if [ ! -f "$MD_FILE" ]; then
    echo "Error: Markdown file not found: $MD_FILE" >&2
    exit 1
fi

# Extract basename for images directory
PDF_BASENAME=$(basename "$MD_FILE" .md)
IMAGES_DIR=$(dirname "$MD_FILE")/${PDF_BASENAME}_images

echo "Extracting images from: $MD_FILE" >&2
echo "Images will be saved to: $IMAGES_DIR" >&2

python3 << 'EOF'
import re
import base64
import os
import sys

# Input/output paths
md_file = sys.argv[1]
pdf_basename = os.path.basename(md_file).replace('.md', '')
images_dir = os.path.join(os.path.dirname(md_file), f'{pdf_basename}_images')
os.makedirs(images_dir, exist_ok=True)

# Read Markdown content
try:
    with open(md_file, 'r', encoding='utf-8') as f:
        content = f.read()
except Exception as e:
    print(f'Error reading Markdown file: {e}', file=sys.stderr)
    sys.exit(1)

# Pattern to match base64-encoded images in Markdown
# Matches: ![alt](data:image/png;base64,iVBORw0KG...)
image_pattern = r'!\[([^\]]*)\]\(data:image/([^;]+);base64,([^)]+)\)'

image_count = 0
page_num = 1

def extract_image(match):
    global image_count, page_num

    alt_text = match.group(1)
    image_format = match.group(2)  # png, jpeg, etc.
    base64_data = match.group(3)

    # Determine page number from preceding content
    preceding_text = content[:match.start()]
    page_markers = re.findall(r'##\s*Page\s*(\d+)', preceding_text, re.IGNORECASE)
    if page_markers:
        page_num = int(page_markers[-1])

    # Generate filename
    image_count += 1
    filename = f'page_{page_num:03d}_image_{image_count:03d}.{image_format}'
    filepath = os.path.join(images_dir, filename)

    # Decode and save image
    try:
        image_data = base64.b64decode(base64_data)
        with open(filepath, 'wb') as img_file:
            img_file.write(image_data)
        print(f'Extracted: {filename} ({len(image_data)} bytes)', file=sys.stderr)
        return ''  # Remove image from Markdown
    except Exception as e:
        print(f'Error extracting image: {e}', file=sys.stderr)
        return match.group(0)  # Keep original if extraction fails

# Replace all base64 images
cleaned_content = re.sub(image_pattern, extract_image, content)

# Write cleaned Markdown
try:
    with open(md_file, 'w', encoding='utf-8') as f:
        f.write(cleaned_content)
    print(f'Total images extracted: {image_count}', file=sys.stderr)
    print(f'Images saved to: {images_dir}', file=sys.stderr)
    print(f'Cleaned Markdown size: {len(cleaned_content)} bytes (was {len(content)} bytes)', file=sys.stderr)
except Exception as e:
    print(f'Error writing cleaned Markdown: {e}', file=sys.stderr)
    sys.exit(1)
EOF "$MD_FILE"

echo "Image extraction complete" >&2
