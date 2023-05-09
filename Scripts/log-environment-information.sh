#!/bin/bash

# Prints the public IP address of the host machine, and the result of resolving sandbox-realtime.ably.io. Useful information to have in a CI environment.

set -e

ip=$(curl -s https://api.ipify.org)
echo "Public IP address is: $ip"

echo "Output of \`dig sandbox-realtime.ably.io\`:"
dig sandbox-realtime.ably.io
