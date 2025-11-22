#!/bin/bash
set -e

# Script to process all emails from the mail/ folder
# Generates one .oft file per subfolder

MAIL_DIR="/app/mail"
OUTPUT_DIR="/app/output"
TEMP_DIR="/app/temp"

# Create directories if they don't exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

echo "============================================"
echo "🚀 Batch Email Processor"
echo "============================================"
echo ""

# Counter for processed emails
total=0
successful=0
failed=0

# Iterate over all subfolders in mail/
for folder in "$MAIL_DIR"/*/ ; do
    # Get folder name without path
    folder_name=$(basename "$folder")

    echo "----------------------------------------"
    echo "📧 Processing: $folder_name"
    echo "----------------------------------------"

    total=$((total + 1))

    # Temporary and final file names
    temp_eml="$TEMP_DIR/${folder_name}.eml"
    final_oft="$OUTPUT_DIR/${folder_name}.oft"

    # STEP 1: Generate EML with Python
    echo "📝 Step 1/2: Generating EML..."
    if python3 /app/generate_eml.py "$folder" "$temp_eml"; then

        # STEP 2: Convert EML to OFT with .NET (using compiled Release DLL)
        echo "🔄 Step 2/2: Converting to OFT..."

        if dotnet /app/dotnet/ConversorOutlook.dll "$temp_eml" "$final_oft"; then
            echo "✅ Completed: $final_oft"
            successful=$((successful + 1))
        else
            echo "❌ Error in .NET conversion for $folder_name"
            failed=$((failed + 1))
        fi
    else
        echo "❌ Error generating EML for $folder_name"
        failed=$((failed + 1))
    fi

    echo ""
done

# Final summary
echo "============================================"
echo "📊 PROCESS SUMMARY"
echo "============================================"
echo "Total processed: $total"
echo "Successful: $successful ✅"
echo "Failed: $failed ❌"
echo ""
echo "Generated files in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
echo ""
echo "🎉 Process completed!"
