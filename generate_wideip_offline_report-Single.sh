cat << 'EOF' > generate_wideip_report.sh
#!/bin/bash

# Define the output file with a full path and timestamp for unique names
OUTPUT_FILE="/config/offline_wideips_report_$(date +%Y%m%d%H%M%S).csv"

# Clear existing file and write the CSV header
echo "WideIP_Name,Status,Total_Requests,WideIP_Type" > "$OUTPUT_FILE"

# Get a clean list of all Wide IP names AND their types.
WIDEIP_LIST=$(tmsh list gtm wideip | awk '/gtm wideip/ {print $3" "$4}')

# Loop through each identified Wide IP type and name
while read -r WIP_TYPE WIP_NAME; do
    # Get the detailed information for the current Wide IP, including its type.
    RAW_TMSH_OUTPUT=$(tmsh show gtm wideip "$WIP_TYPE" "$WIP_NAME" 2>/dev/null)

    # Apply sanitization line by line:
    # Step 1: Replace non-breaking spaces (NBSP) with regular spaces.
    # Step 2: Squeeze multiple regular spaces into single spaces.
    # Step 3: Trim leading/trailing regular spaces from EACH LINE.
    CLEAN_TMSH_OUTPUT=$(echo "$RAW_TMSH_OUTPUT" | \
                        sed 's/\xc2\xa0/ /g' | \
                        sed 's/[ ][ ]*/ /g' | \
                        sed 's/^[ ]*//;s/[ ]*$//')

    # Now, grep for the lines. They are still on separate lines.
    RELEVANT_LINES=$(echo "$CLEAN_TMSH_OUTPUT" | grep -E "^Availability :|^Total ")

    # Extract the 'Availability' status.
    STATUS=$(echo "$RELEVANT_LINES" | awk -F':' '/^Availability :/ {print $2}')

    # Extract the 'Total' requests.
    TOTAL_REQUESTS=$(echo "$RELEVANT_LINES" | awk '/^Total / {print $NF}')

    # If Total_Requests field is empty or non-numeric, default it to 0.
    if ! [[ "$TOTAL_REQUESTS" =~ ^[0-9]+$ ]]; then
        TOTAL_REQUESTS=0
    fi

    # Ensure STATUS variable itself is properly trimmed before comparison.
    STATUS_TRIMMED=$(echo "$STATUS" | sed 's/^[ ]*//;s/[ ]*$//')

    # Condition: Check if the Wide IP's Availability status contains "offline".
    if [[ "$STATUS_TRIMMED" == *offline* ]]; then
        # If the condition is met, append the Wide IP's details to the CSV file.
        echo "$WIP_NAME,$STATUS_TRIMMED,$TOTAL_REQUESTS,$WIP_TYPE" >> "$OUTPUT_FILE"
    fi
done <<< "$WIDEIP_LIST"

# Inform the user where the report is saved.
echo "Output saved to $OUTPUT_FILE"
EOF
