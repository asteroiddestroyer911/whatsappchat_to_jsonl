#!/bin/bash

# Predefined file paths
INPUT_FILE="/home/shivansh/Downloads/chats/whatsapp.txt"  # Update this path if needed
OUTPUT_FILE="/home/shivansh/Downloads/output.jsonl"  # Output JSONL file

# Your username in the chat (Update this if needed)
YOUR_USERNAME="Shivansh Rathore"

# Initialize the output file
> "$OUTPUT_FILE"

# Previous speaker tracking
previous_speaker=""
previous_message=""

# Check if the input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "❌ Error: Input file '$INPUT_FILE' not found!"
    exit 1
fi

echo "🔄 Processing WhatsApp chat..."

# Read and process each line of the input file
while IFS= read -r line; do
    # Debugging: Print each line to check if it's being read
    echo "Processing: $line"

    # Extract speaker and message using updated regex
    if [[ "$line" =~ ^([0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}),?\ ([0-9]{1,2}:[0-9]{2}(\s| )?[aApP][mM])\ -\ ([^:]+):\ (.*)$ ]]; then
        timestamp="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
        speaker="${BASH_REMATCH[4]}"
        message="${BASH_REMATCH[5]}"

        # Debugging: Print extracted values
        echo "✅ Matched format: Speaker: $speaker, Message: $message"

        # Skip empty messages and ignored phrases
        if [[ -z "$message" || "$message" == "null" || "$message" == "You deleted this message" || "$message" =~ "<Media omitted>" || "$message" =~ "<This message was edited>" ]]; then
            echo "🚫 Skipping: Empty or deleted message"
            continue
        fi

        # Remove URLs from messages
        message=$(echo "$message" | sed -E 's#https?://[a-zA-Z0-9./?=_-]+##g')

        # Handle message pairing (previous message → response)
        if [[ "$previous_speaker" != "$speaker" && -n "$previous_speaker" ]]; then
            if [[ "$speaker" == "$YOUR_USERNAME" ]]; then
                # Debugging: Print the input-output pair
                echo "✅ Pairing: Input from $previous_speaker → Output from $speaker"

                # Write JSONL format: "{input: other user's message, output: your message}"
                echo "{\"instruction\": \"Respond to $previous_speaker\", \"input\": \"$previous_message\", \"output\": \"$message\"}" >> "$OUTPUT_FILE"
            fi
        fi

        # Update previous speaker and message
        previous_speaker="$speaker"
        previous_message="$message"
    else
        echo "⚠️ Warning: Line format did not match regex → $line"
    fi
done < "$INPUT_FILE"

echo "✅ Conversion complete! Data saved to $OUTPUT_FILE."

# Debugging: Check if JSONL file has data
if [[ ! -s "$OUTPUT_FILE" ]]; then
    echo "❌ Error: The output file is empty! Check the debug logs above."
else
    echo "✅ Successfully generated fine-tuning data!"
fi

