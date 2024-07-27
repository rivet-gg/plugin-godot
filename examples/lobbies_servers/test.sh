#!/bin/sh

# curl -X POST -d '{}' 'https://sandbox-back-vlk--staging.backend.nathan16.gameinc.io/modules/lobbies/scripts/reset/call'

# curl -X POST -d '{ "version": "default", "tags": {}, "players": [{}] }' 'https://sandbox-back-vlk--staging.backend.nathan16.gameinc.io/modules/lobbies/scripts/find/call'

echo 'Find:'
# curl -X POST -d '{ "version": "233c0b7c-4c77-4464-baca-1fbf5589645b", "regions": ["atl"], "tags": {}, "players": [{}], "createConfig": { "region": "atl", "tags": {}, "maxPlayers": 32, "maxPlayersDirect": 32 }, "noWait": true }' 'https://sandbox-back-vlk--staging.backend.nathan16.gameinc.io/modules/lobbies/scripts/find_or_create/call'
curl -X POST -d '{ "version": "233c0b7c-4c77-4464-baca-1fbf5589645b", "regions": ["atl"], "tags": {"bump":"b"}, "players": [{}], "createConfig": { "region": "atl", "tags": {"bump":"b"}, "maxPlayers": 32, "maxPlayersDirect": 32 } }' 'https://sandbox-back-vlk--staging.backend.nathan16.gameinc.io/modules/lobbies/scripts/find_or_create/call'
echo

echo 'List:'
curl -X POST -d '{ "version": "233c0b7c-4c77-4464-baca-1fbf5589645b" }' 'https://sandbox-back-vlk--staging.backend.nathan16.gameinc.io/modules/lobbies/scripts/list/call'
echo

# curl -X POST "https://sandbox-back-vlk--staging.backend.nathan16.gameinc.io/modules/auth/scripts/send_email_verification/call" \
#   -H "Content-Type: application/json" \
#   -d '{
#     "email": "test@rivet.gg"
#   }'

