#!/bin/bash

# Input and output file paths
INPUT_FILE="/home/shivansh/Downloads/chats/whatsapp.txt"  # Update with actual chat file location
OUTPUT_FILE="/home/shivansh/Downloads/output.jsonl"

# Expanded regex to remove all URLs (Spotify, Hauntrex, NewMe, etc.)
URL_PATTERN="(https?://)?(www[.])?(youtube[.]com|youtu[.]be|instagram[.]com|facebook[.]com|twitter[.]com|linkedin[.]com|google[.]com|t[.]co|bit[.]ly|goo[.]gl|reddit[.]com|tiktok[.]com|discord[.]gg|twitch[.]tv|pinterest[.]com|spotify[.]com|hauntrex[.]com|newme[.]com|soundcloud[.]com|snapchat[.]com|telegram[.]me|threads[.]net|medium[.]com|quora[.]com|tumblr[.]com|onlyfans[.]com|patreon[.]com|kickstarter[.]com|indiegogo[.]com|weibo[.]com|wechat[.]com|strava[.]com|bandcamp[.]com|curiouscat[.]com|substack[.]com|paypal[.]me|ko-fi[.]com|buymeacoffee[.]com|venmo[.]com|cashapp[.]com)[^ ]*"

# Ensure input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: Input file '$INPUT_FILE' not found!"
    exit 1
fi

# Process WhatsApp chat and remove URLs and media placeholders
echo "🔄 Processing WhatsApp chat..."
awk -v url_pattern="$URL_PATTERN" '
{
    gsub(url_pattern, "");  # Remove social media links
    gsub(/https?:\/\/[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,})+([^\s]*)?/, ""); # Remove any remaining URLs
    gsub(/<Media omitted>|<image omitted>|<video omitted>|<audio omitted>/, ""); # Remove media placeholders
    print $0;
}' "$INPUT_FILE" > cleaned_chat.txt

# Convert cleaned chat to JSONL format
echo "🔄 Converting to fine-tune format..."
awk '
BEGIN {
    FS=" - "; OFS="\n";
    print "["; first=1;
}
{
    if ($2 ~ /: /) {
        split($2, msg, ": ");
        sender = msg[1];
        message = msg[2];

        # Skip media placeholder messages
        if (message ~ /<Media omitted>|<image omitted>|<video omitted>|<audio omitted>/) {
            next;
        }

        # Skip "null" messages
        if (message == "null" || message ~ /^[[:space:]]*$/) {
            next;
        }

        if (!first) print ",";
        print "{ \"instruction\": \"Respond to " sender "\", \"input\": \"" message "\", \"output\": \"\" }";
        first=0;
    }
}
END {
    print "]";
}' cleaned_chat.txt > "$OUTPUT_FILE"

# Clean up temporary file
rm cleaned_chat.txt

echo "✅ Fine-tuning data saved to $OUTPUT_FILE"

