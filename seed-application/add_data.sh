#!/usr/bin/env bash
source ../.env

# Description:
#  This script reads a Markdown table from the specified file and looks for pairs of rows:
#    1) A row with key = "target" and a numeric percentage (like "45%").
#    2) The next row with key = "goal" and a description.
#  It builds a JSON payload for each valid pair and POSTs it to the configured endpoint.
#
# Environment Variables:
#  - GOALS_ENDPOINT: The URL to POST data to (defaults to "http://localhost:8080/api/goals").

# Attempt to load ../.env, but ignore if missing
source ../.env 2>/dev/null || true

readonly DEFAULT_ENDPOINT="http://localhost:8080/api/goals"
readonly ENDPOINT="${GOALS_ENDPOINT:-$DEFAULT_ENDPOINT}"

readonly TARGET_KEY="target"
readonly GOAL_KEY="goal"
readonly HEADER_KEY="Key"
# Regex to match the separator row in the Markdown table (like "| --- | --- |").
readonly SEPARATOR_REGEX='^[[:space:]]*\|[-[:space:]]+\|'

################################################################################
# Trim leading and trailing whitespace.
trim() {
  sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

################################################################################
# Escape backslashes and double quotes so that strings won't break JSON syntax.
escape_json_string() {
  local s="$1"
  # Escape backslashes
  s="${s//\\/\\\\}"
  # Escape double quotes
  s="${s//\"/\\\"}"
  # (Optional) Escape other control chars if needed
  echo "$s"
}

################################################################################
# Validate that the percentage has the form "NN%" with NN numeric,
# returning just the numeric portion (e.g. 45), or empty string if invalid.
#   Arg 1: raw percentage value (e.g. "50%")
validate_percentage() {
  local rawValue="$1"
  local numValue

  # Remove % sign and any extra whitespace
  numValue=$(echo "$rawValue" | sed 's/%//g' | xargs)
  if [[ "$numValue" =~ ^[0-9]+$ ]]; then
    echo "$numValue"
  else
    echo ""
  fi
}

################################################################################
# POST a JSON payload to the endpoint.
#   Arg 1: JSON payload string
post_goal() {
  local payload="$1"
  local tmpfile
  tmpfile=$(mktemp)

  # Capture the HTTP status code
  local response_code
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

################################################################################
# Main script logic
################################################################################

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <data_file>"
  exit 1
fi

DATA_FILE="$1"

# Check file existence and readability
if [[ ! -f "$DATA_FILE" ]]; then
  echo "Error: File '$DATA_FILE' does not exist."
  exit 1
fi
if [[ ! -r "$DATA_FILE" ]]; then
  echo "Error: File '$DATA_FILE' is not readable."
  exit 1
fi

echo "Using endpoint: $ENDPOINT"
echo "Reading data from: $DATA_FILE"
echo

current_target_percentage=""
line_number=0
goal_count=0

# Read the file line by line
while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  (( line_number++ ))

  # Trim away leading/trailing whitespace
  raw_line="$(echo "$raw_line" | trim)"

  # Skip empty lines
  if [[ -z "$raw_line" ]]; then
    continue
  fi

  # Skip lines that do not start with '|'
  if [[ ! "$raw_line" =~ ^\| ]]; then
    continue
  fi

  # Skip header row (has "Key") or separator row (like "| --- |")
  if echo "$raw_line" | grep -qi "$HEADER_KEY"; then
    continue
  fi
  if [[ "$raw_line" =~ $SEPARATOR_REGEX ]]; then
    continue
  fi

  # Remove leading '|' and trailing '|', if any
  local_line="$(echo "$raw_line" | sed 's/^|//;s/|$//')"
  # Now we have something like: " target     |  45%      "

  # Split on '|'
  IFS='|' read -r raw_key raw_val <<< "$local_line"

  # Trim them
  key="$(echo "${raw_key:-}" | trim)"
  val="$(echo "${raw_val:-}" | trim)"

  # If we read a "target" row, parse the percentage
  if [[ "$key" == "$TARGET_KEY" ]]; then
    valid_percentage="$(validate_percentage "$val")"
    if [[ -z "$valid_percentage" ]]; then
      echo "Line $line_number: Skipping invalid percentage value '$val'."
      current_target_percentage=""
      continue
    fi
    current_target_percentage="$valid_percentage"
    continue
  fi

  # If we read a "goal" row AND we have a pending target
  if [[ "$key" == "$GOAL_KEY" && -n "$current_target_percentage" ]]; then
    (( goal_count++ ))

    # Escape the description
    safe_val="$(escape_json_string "$val")"
    # Build JSON
    payload=$(printf '{"name":"%s","targetPercentage":%s}' "$safe_val" "$current_target_percentage")

    post_goal "$payload"

    # Reset target
    current_target_percentage=""
    continue
  fi

  # Otherwise, skip it
  echo "Line $line_number: Skipping row. Key='$key' (expected '$TARGET_KEY' or '$GOAL_KEY'), or no pending target."
done < "$DATA_FILE"

echo
echo "Finished processing. Goals processed: $goal_count."
