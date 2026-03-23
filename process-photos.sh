#!/bin/bash
# Converts product photos from wpw-photos/ to WebP format
# Organizes by tool number: media/products/TOOLNO/1.webp, 2.webp, ...

set -euo pipefail

INPUT_DIR="${1:-./wpw-photos}"
OUTPUT_DIR="${2:-./media/products}"
QUALITY="${3:-80}"

if [ ! -d "$INPUT_DIR" ]; then
  echo "Error: Input directory '$INPUT_DIR' not found"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

total=0
converted=0
skipped=0
errors=0

echo "Converting photos from $INPUT_DIR to WebP (quality=$QUALITY)..."
echo ""

for file in "$INPUT_DIR"/*; do
  [ -f "$file" ] || continue
  total=$((total + 1))

  basename=$(basename "$file")
  ext="${basename##*.}"
  name="${basename%.*}"

  # Skip non-image files
  ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  case "$ext_lower" in
    jpg|jpeg|png|webp) ;;
    nef|ds_store)
      skipped=$((skipped + 1))
      continue
      ;;
    *)
      skipped=$((skipped + 1))
      continue
      ;;
  esac

  # Extract tool_no and variant number from filename
  # Pattern: TOOLNO.jpg or TOOLNO_N.jpg (where N is a number)
  if [[ "$name" =~ ^(.+)_([0-9]+)$ ]]; then
    tool_no="${BASH_REMATCH[1]}"
    variant="${BASH_REMATCH[2]}"
  else
    tool_no="$name"
    variant="1"
  fi

  # Skip files with spaces or special chars in tool_no (edge cases)
  if [[ "$tool_no" =~ [\ \(\)] ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  # Normalize tool_no to uppercase
  tool_no=$(echo "$tool_no" | tr '[:lower:]' '[:upper:]')

  # Create output directory for this tool
  tool_dir="$OUTPUT_DIR/$tool_no"
  mkdir -p "$tool_dir"

  out_file="$tool_dir/${variant}.webp"

  # Skip if already converted
  if [ -f "$out_file" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  # Convert to WebP
  if cwebp -q "$QUALITY" -quiet "$file" -o "$out_file" 2>/dev/null; then
    converted=$((converted + 1))
  else
    errors=$((errors + 1))
  fi

  # Progress every 100 files
  if [ $((total % 100)) -eq 0 ]; then
    echo "  Processed $total files..."
  fi
done

echo ""
echo "Done!"
echo "  Total files:  $total"
echo "  Converted:    $converted"
echo "  Skipped:      $skipped"
echo "  Errors:       $errors"
echo "  Output:       $OUTPUT_DIR"

# Count unique tool numbers
tool_count=$(ls -d "$OUTPUT_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
image_count=$(find "$OUTPUT_DIR" -name "*.webp" | wc -l | tr -d ' ')
echo "  Tool numbers: $tool_count"
echo "  WebP images:  $image_count"
