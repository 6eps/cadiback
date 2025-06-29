#!/bin/bash

# Check for input directory argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <input_dir>"
    exit 1
fi

# Directory containing the input files
INPUT_DIR="$1"
# Output directory for logs
LOG_DIR="./logs"
# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

ALL_TIMES_FILE="$LOG_DIR/all_times.csv"
if [ ! -f "$ALL_TIMES_FILE" ]; then
    echo "filename,normal_time,normal_backbones,no_temp_time,no_temp_backbones" > "$ALL_TIMES_FILE"
fi

# Loop through all .cnf.xz files in the input directory
for file in "$INPUT_DIR"/*.cnf.xz; do
    # Get the base filename without extension
    base_name=$(basename "$file" .cnf.xz)

    # Skip if already processed (filename exists in CSV)
    if grep -q "^${base_name}," "$ALL_TIMES_FILE"; then
        echo "[$base_name] Already processed. Skipping."
        continue
    fi

    echo "[$base_name] Running cadiback (normal)..."
    timeout 3600 ./cadiback "$file" > "$LOG_DIR/${base_name}.log" 2> "$LOG_DIR/${base_name}.err"
    normal_time=$(awk '/c total process time since initialization:/ {print $(NF-1)}' "$LOG_DIR/${base_name}.log")
    normal_backbones=$(awk '/c[[:space:]]+found[[:space:]]+[0-9]+[[:space:]]+backbones/ {for(i=1;i<=NF;i++) if($i=="found") print $(i+1)}' "$LOG_DIR/${base_name}.log")
    echo "[$base_name] cadiback (normal) done. Time: $normal_time, Backbones: $normal_backbones"

    echo "[$base_name] Running cadiback (--no-temp)..."
    timeout 3600 ./cadiback --no-temp "$file" > "$LOG_DIR/${base_name}_no_temp.log" 2>> "$LOG_DIR/${base_name}_no_temp.err"
    no_temp_time=$(awk '/c total process time since initialization:/ {print $(NF-1)}' "$LOG_DIR/${base_name}_no_temp.log")
    no_temp_backbones=$(awk '/c[[:space:]]+found[[:space:]]+[0-9]+[[:space:]]+backbones/ {for(i=1;i<=NF;i++) if($i=="found") print $(i+1)}' "$LOG_DIR/${base_name}_no_temp.log")
    echo "[$base_name] cadiback (--no-temp) done. Time: $no_temp_time, Backbones: $no_temp_backbones"

    echo "${base_name},${normal_time},${normal_backbones},${no_temp_time},${no_temp_backbones}" >> "$ALL_TIMES_FILE"
    echo "[$base_name] Results saved."
done