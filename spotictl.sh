#!/bin/bash
# ==========================================================
# spotictl.sh — v3.0.4-release
#
# A Bash script to control Spotify playback using the
# Spotify Web API. It features a caching mechanism for the
# access token to minimize API calls.
# ==========================================================

# --- YOUR CREDENTIALS ---
# These are your personal Spotify application credentials.
# You can get them from the Spotify Developer Dashboard.
CLIENT_ID="CLIENT ID"
CLIENT_SECRET="CLIENT SECRET"
REFRESH_TOKEN="REFRESH TOKEN"

# --- CACHE FILE ---
# Defines the location for storing the cached access token.
# Using /tmp ensures it's stored in a temporary, non-persistent location.
CACHE_FILE="/tmp/spotify_token.json"

# ==========================================================
# 1. Access Token Management (with Caching)
# ==========================================================

# ---
# get_new_token()
#
# Fetches a new access token from the Spotify API using the
# refresh token, then caches it to a file.
# ---
get_new_token() {
  local response access_token expires_in expires_at
  
  response=$(curl -s -X POST -u "${CLIENT_ID}:${CLIENT_SECRET}" \
    -d grant_type=refresh_token \
    -d refresh_token="$REFRESH_TOKEN" \
    https://accounts.spotify.com/api/token)

  access_token=$(echo "$response" | jq -r '.access_token')
  expires_in=$(echo "$response" | jq -r '.expires_in')

  if [[ "$access_token" == "null" || -z "$access_token" ]]; then
    echo "✗ Fatal Error: Could not retrieve a new access token." >&2
    exit 1
  fi

  expires_at=$(( $(date +%s) + expires_in - 60 ))
  
  echo "{\"access_token\": \"$access_token\", \"expires_at\": $expires_at}" > "$CACHE_FILE"
  
  echo "$access_token"
}

# ---
# get_access_token()
#
# Retrieves a valid access token. It first checks the cache file.
# If the file doesn't exist or the token is expired, it calls
# get_new_token(). Otherwise, it returns the cached token.
# ---
get_access_token() {
  if [[ ! -f "$CACHE_FILE" ]]; then
    get_new_token
    return
  fi

  local cached_token expires_at current_time
  cached_token=$(jq -r '.access_token' "$CACHE_FILE")
  expires_at=$(jq -r '.expires_at' "$CACHE_FILE")
  current_time=$(date +%s)

  if [[ "$current_time" -ge "$expires_at" ]]; then
    get_new_token
  else
    echo "$cached_token"
  fi
}

ACCESS_TOKEN=$(get_access_token)

if [[ "$ACCESS_TOKEN" == "null" || -z "$ACCESS_TOKEN" ]]; then
  echo "✗ Error: Failed to obtain a valid access token."
  exit 1
fi

# ==========================================================
# 2. Helper Functions
# ==========================================================

# ---
# get_device_id()
#
# Fetches the list of available Spotify devices and returns the ID
# of one of them. It prioritizes the currently active device. If no
# device is active, it defaults to the first device in the list.
# ---
get_device_id() {
  local devices active_device
  devices=$(curl -s -X GET "https://api.spotify.com/v1/me/player/devices" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
    
  active_device=$(echo "$devices" | jq -r '.devices[] | select(.is_active==true) | .id')
  
  if [[ -n "$active_device" && "$active_device" != "null" ]]; then
    echo "$active_device"
  else
    echo "$devices" | jq -r '.devices[0].id'
  fi
}

# ---
# status_report()
#
# Fetches the current playback state from the Spotify API
# and prints it as a formatted JSON object.
# ---
status_report() {
  local info
  info=$(curl -s -X GET "https://api.spotify.com/v1/me/player" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
  echo "$info" | jq '.'
}

# ==========================================================
# 3. Main Control Logic
# ==========================================================

device_id=$(get_device_id)

case "$1" in
  next)
    curl -s -X POST "https://api.spotify.com/v1/me/player/next?device_id=$device_id" \
      -H "Authorization: Bearer $ACCESS_TOKEN" >/dev/null
    echo "⏭  Skipping to next track."
    ;;

  prev)
    curl -s -X POST "https://api.spotify.com/v1/me/player/previous?device_id=$device_id" \
      -H "Authorization: Bearer $ACCESS_TOKEN" >/dev/null
    echo "⏮  Skipping to previous track."
    ;;

  pause)
    # pause/resume
    info=$(curl -s -X GET "https://api.spotify.com/v1/me/player" \
      -H "Authorization: Bearer $ACCESS_TOKEN")

    is_playing=$(echo "$info" | jq -r '.is_playing')
    device_id_from_info=$(echo "$info" | jq -r '.device.id')
    track_uri=$(echo "$info" | jq -r '.item.uri')
    progress_ms=$(echo "$info" | jq -r '.progress_ms')
    context_uri=$(echo "$info" | jq -r '.context.uri')

    if [[ "$is_playing" == "true" ]]; then
      curl -s -X PUT "https://api.spotify.com/v1/me/player/pause?device_id=$device_id_from_info" \
        -H "Authorization: Bearer $ACCESS_TOKEN" >/dev/null
      echo "⏸  Playback paused."

    else
      if [[ "$device_id_from_info" == "null" || -z "$device_id_from_info" ]]; then
        device_id=$(get_device_id)
      fi

      if [[ "$context_uri" != "null" && -n "$context_uri" ]]; then
        body="{\"position_ms\": $progress_ms}"
      else
        body="{\"uris\": [\"$track_uri\"], \"position_ms\": $progress_ms}"
      fi

      curl -s -X PUT "https://api.spotify.com/v1/me/player/play?device_id=$device_id" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$body" >/dev/null

      echo "▶  Playback resumed."
    fi
    ;;

  status)
    status_report
    ;;
  
  *)
    echo "Usage: $0 {next|prev|pause|status}"
    ;;
esac