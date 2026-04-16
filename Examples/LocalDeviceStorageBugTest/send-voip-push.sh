#!/bin/bash
set -euo pipefail

# Fetches the latest VoIP device token from the Ably events channel,
# then sends a VoIP push notification to that device via APNs.
#
# Required environment variables:
#   APNS_AUTH_KEY_PATH  - path to your .p8 APNs auth key file
#   APNS_AUTH_KEY_ID    - the key ID (10-character string from App Store Connect)
#   APNS_TEAM_ID        - your Apple Developer team ID
#
# Optional:
#   APNS_HOST           - APNs host (default: api.sandbox.push.apple.com)

CHANNEL_NAME="LocalDeviceStorageBugTest-events"
BUNDLE_ID="com.ably.LocalDeviceStorageBugTest"
APNS_TOPIC="${BUNDLE_ID}.voip"

AUTH_KEY_PATH="${APNS_AUTH_KEY_PATH:?Set APNS_AUTH_KEY_PATH to your .p8 file}"
AUTH_KEY_ID="${APNS_AUTH_KEY_ID:?Set APNS_AUTH_KEY_ID to your key ID}"
TEAM_ID="${APNS_TEAM_ID:?Set APNS_TEAM_ID to your team ID}"
APNS_HOST="${APNS_HOST:-api.sandbox.push.apple.com}"

# Step 1: Fetch the latest voipToken from channel history
echo "Fetching latest voipToken from ${CHANNEL_NAME}..."

TOKEN=$(ably channels history "$CHANNEL_NAME" --json --limit 100 \
    | jq -r '.messages[] | select(.name == "voipToken") | .data.token' \
    | head -1)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "Error: no voipToken found in channel history" >&2
    exit 1
fi

echo "Found VoIP token: ${TOKEN}"

# Step 2: Generate an APNs JWT
JWT=$(python3 -c "
import json, time, base64, subprocess, sys

def base64url(data):
    if isinstance(data, str):
        data = data.encode()
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

def der_to_raw(der):
    \"\"\"Convert DER-encoded ECDSA signature to the raw r||s format that JWT requires.\"\"\"
    assert der[0] == 0x30
    pos = 2
    assert der[pos] == 0x02
    r_len = der[pos + 1]
    r = der[pos + 2 : pos + 2 + r_len]
    pos += 2 + r_len
    assert der[pos] == 0x02
    s_len = der[pos + 1]
    s = der[pos + 2 : pos + 2 + s_len]
    # Each component must be exactly 32 bytes for ES256
    r = r[-32:].rjust(32, b'\x00')
    s = s[-32:].rjust(32, b'\x00')
    return r + s

key_id = sys.argv[1]
team_id = sys.argv[2]
key_path = sys.argv[3]

header = base64url(json.dumps({'alg': 'ES256', 'kid': key_id}))
payload = base64url(json.dumps({'iss': team_id, 'iat': int(time.time())}))
signing_input = f'{header}.{payload}'.encode()

result = subprocess.run(
    ['openssl', 'dgst', '-sha256', '-sign', key_path],
    input=signing_input,
    capture_output=True,
    check=True,
)
signature = base64url(der_to_raw(result.stdout))

print(f'{header}.{payload}.{signature}')
" "$AUTH_KEY_ID" "$TEAM_ID" "$AUTH_KEY_PATH")

# Step 3: Send the VoIP push via APNs
echo "Sending VoIP push to ${APNS_HOST}..."

RESPONSE=$(curl --silent --show-error \
    --http2 \
    --header "authorization: bearer ${JWT}" \
    --header "apns-topic: ${APNS_TOPIC}" \
    --header "apns-push-type: voip" \
    --header "apns-priority: 10" \
    --data '{"aps":{}}' \
    --write-out "\n%{http_code}" \
    "https://${APNS_HOST}/3/device/${TOKEN}")

HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$RESPONSE" | tail -1)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "Push sent successfully."
else
    echo "APNs returned HTTP ${HTTP_STATUS}:" >&2
    echo "$HTTP_BODY" >&2
    exit 1
fi
