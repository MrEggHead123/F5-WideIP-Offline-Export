cat << 'EOF' > generate_wideip_report.sh
#!/bin/bash

# Define the output file with a full path and timestamp for unique names
OUTPUT_FILE="/config/offline_wideips_report_$(date +%Y%m%d%H%M%S).csv"

# Clear existing file and write the CSV header
echo "WideIP_Name,Status,Total_Requests,WideIP_Type" > "$OUTPUT_FILE"

# Get ALL Wide IP details at once and process them with a single awk instance.
# This is the most significant optimization, avoiding repeated tmsh show calls.
tmsh list gtm wideip full | \
# First sed replaces NBSP, second sed replaces multiple spaces with single, tr trims leading/trailing spaces
sed 's/\xc2\xa0/ /g' | sed 's/[ ][ ]*/ /g' | sed 's/^[ ]*//;s/[ ]*$//' | \
awk '
BEGIN {
    # Initialize variables
    current_name = "";
    current_type = "";
    current_status = "";
    current_total_requests = 0;

    # Define arrays for mapping statuses if needed (though not strictly used for filtering \'offline\')
    # status_map["Availability : offline"] = "offline";
}

# Match the start of a new Wide IP definition
/^gtm wideip / {
    # If we had a previous Wide IP being processed and it was offline, print it
    if (current_name != "" && current_status ~ /offline/) {
        print current_name "," current_status "," current_total_requests "," current_type;
    }

    # Reset for the new Wide IP
    current_type = $3; # e.g., \'a\', \'cname\'
    current_name = $4; # The Wide IP name
    current_status = "";
    current_total_requests = 0;
}

# Match the Availability status line
/^Availability :/ {
    # Extract the status string (everything after the colon)
    # Using substr to get from the 17th character (after "Availability : ") to the end
    # Then re-apply gsub to ensure no extra leading/trailing spaces from its own field
    current_status = substr($0, 17);
    gsub(/^[ ]*|[ ]*$/, "", current_status);
}

# Match the Total requests line
/^Total / {
    # Extract the last field, which should be the total requests count
    current_total_requests = $NF;
    # Ensure it is a number
    if (current_total_requests !~ /^[0-9]+$/) {
        current_total_requests = 0;
    }
}

END {
    # Process the last Wide IP after the file ends
    if (current_name != "" && current_status ~ /offline/) {
        print current_name "," current_status "," current_total_requests "," current_type;
    }
}' >> "$OUTPUT_FILE"

echo "Output saved to $OUTPUT_FILE"
EOF
