#!/bin/bash

# Check if the user provided a file as input
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

input_file="$1"
output_file="processed_$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found!"
    exit 1
fi

# Process each line of the input file
while IFS= read -r line; do
    echo "\"${line}.git\"" >> "$output_file"
done < "$input_file"

echo "Processing complete. Output saved in '$output_file'."
