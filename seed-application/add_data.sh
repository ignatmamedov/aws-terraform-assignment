#!/usr/bin/env bash

# Description:
#  This script reads a Markdown table from the specified file and looks for pairs of rows:
#    1) A row with key = "target" and a numeric percentage (like "45%").
#    2) The next row with key = "goal" and a description.
#  It builds a JSON payload for each valid pair and POSTs it to the configured endpoint.
#
# Environment Variables:
#  - GOALS_ENDPOINT: The URL to POST data to (defaults to "http://localhost:8000/api/goals").

readonly DEFAULT_ENDPOINT="http://localhost:8000/api/goals"
readonly ENDPOINT="${GOALS_ENDPOINT:-$DEFAULT_ENDPOINT}"
readonly TARGET_KEY="target"
readonly GOAL_KEY="goal"
readonly HEADER_KEY="Key"
# Regex to match the separator row in the Markdown table. @Credits to ChatGPT
readonly SEPARATOR_REGEX='^[[:space:]]*\|[-[:space:]]+\|'

# Trim whitespace.
# @Credits to ChatGPT for regex
trim() {
  sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Validate that the percentage has the form "NN%" with NN numeric.
# Returns the numeric portion or an empty string if invalid.
# Args:
#   $1 = raw percentage value (e.g "50%")
validate_percentage() {
  local rawValue="$1"
  local numValue

  # Remove % sign and any extra whitespace, @Credits to ChatGPT
  numValue=$(echo "$rawValue" | sed 's/%//g' | xargs)
  if [[ "$numValue" =~ ^[0-9]+$ ]]; then
    echo "$numValue"
  else
    echo ""
  fi
}

# Send a JSON payload to the endpoint.
# Args:
#   $1 = JSON payload
post_goal() {
  local payload="$1"

  # Write response body to a temp file;
  local tmpfile
  # capture HTTP code in $response_code
  local response_code
  tmpfile=$(mktemp)

  response_code=$(curl -s -o "$tmpfile" -w "%{http_code}" \
                  -X POST "$ENDPOINT" \
                  -H "Content-Type: application/json" \
                  -d "$payload")

  local response_body
  response_body=$(cat "$tmpfile")
  rm -f "$tmpfile"

  if [[ "$response_code" == "200" || "$response_code" == "201" ]]; then
    echo "Successfully posted: $payload"
  else
    echo "Error posting goal! HTTP $response_code"
    echo "Response body: $response_body"
  fi
}

# Check usage
# if less than 1 argument is provided, print usage and exit
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <data_file>"
  exit 1
fi

# Check provided file for existence and readability
DATA_FILE="$1"
if [ ! -f "$DATA_FILE" ]; then
  echo "Error: File '$DATA_FILE' does not exist."
  exit 1
fi
if [ ! -r "$DATA_FILE" ]; then
  echo "Error: File '$DATA_FILE' is not readable."
  exit 1
fi

echo "Using endpoint: $ENDPOINT"
echo "Reading data from: $DATA_FILE"
echo

# holds a valid percentage if we just read a "target" row
current_target_percentage=""
line_number=0
goal_count=0

# Read file line-by-line
while IFS= read -r rawValue_line; do
  (( line_number++ ))
  # Trim whitespace for each line
  rawValue_line="$(echo "$rawValue_line" | trim)"

  # Skip empty lines
  if [[ -z "$rawValue_line" ]]; then
    continue
  fi

  # Skip lines not starting with '|'
  if [[ ! "$rawValue_line" =~ ^\| ]]; then
    continue
  fi

  # Skip header row (key / value)  or separator row (----)
  if echo "$rawValue_line" | grep -qi "$HEADER_KEY"; then
    continue
  fi
  if [[ "$rawValue_line" =~ $SEPARATOR_REGEX ]]; then
    continue
  fi

  # Format: | key | value (something) |
  # We'll parse by splitting on '|'.
  # The -r option prevents backslashes from being interpreted as escape characters
  # and the -a option assigns the split tokens to the array parts. @credits to chatGPT
  IFS='|' read -ra parts <<< "$rawValue_line"
  # parts[0] is empty (because line starts with '|')
  # parts[1] => key
  # parts[2] => value
  # parts[3] => might be empty if line ends with '|'

  # Trim key and value
  local_key="$(echo "${parts[1]:-}" | trim)"
  local_val="$(echo "${parts[2]:-}" | trim)"

  # If we read a "target" row
  if [[ "$local_key" == "$TARGET_KEY" ]]; then
    # Validate the percentage
    valid_percentage="$(validate_percentage "$local_val")"
    if [[ -z "$valid_percentage" ]]; then
      echo "Line $line_number: Skipping invalid percentage value '$local_val'."
      # clear any pending target
      current_target_percentage=""
      continue
    fi

    # Store it so next "goal" row can pair with it
    current_target_percentage="$valid_percentage"
    continue
  fi

  # If we read a "goal" row and we have a pending target
  if [[ "$local_key" == "$GOAL_KEY" && -n "$current_target_percentage" ]]; then
    (( goal_count++ ))
    # Generate the JSON payload
    payload=$(printf '{"name":"%s","targetPercentage":%s}' "$local_val" "$current_target_percentage")

    # Post the goal
    post_goal "$payload"
    # Reset the stored target
    current_target_percentage=""
    continue
  fi

  # Otherwise, this row is invalid or out-of-place
  echo "Line $line_number: Skipping row. Key='$local_key' (expected '$TARGET_KEY' or '$GOAL_KEY'), or no pending target to pair with."
done < "$DATA_FILE"

echo
echo "Finished processing. Goals posted: $goal_count."
