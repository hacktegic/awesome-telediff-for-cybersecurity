#!/bin/bash
# monitor-graphql-types.sh: Notify on changes to GraphQL type names via introspection

# Usage: ./monitor-graphql-types.sh https://example.com/graphql your_channel

ENDPOINT="$1"
CHANNEL="$2"

if [[ -z "$ENDPOINT" || -z "$CHANNEL" ]]; then
    echo "Usage: $0 <graphql_endpoint_url> <telediff_channel>"
    exit 1
fi

CACHE_DIR="$HOME/.local/share/telediff/graphql_types"
mkdir -p "$CACHE_DIR"

# Use a hash of the endpoint for file uniqueness
HASH=$(echo -n "$ENDPOINT" | sha1sum | awk '{print $1}')
OUTFILE="$CACHE_DIR/types_${HASH}.txt"

# Query for all type names, normalize, and notify on change
curl -skL "$ENDPOINT" \
  -X POST -H 'Content-Type: application/json' \
  --data '{"query":"{__schema{types{name}}}"}' \
| jq -r '.data.__schema.types[].name' | sort \
| telediff notify --channel "$CHANNEL" --attach --title "GraphQL types changed: $ENDPOINT" --no-path-in-body --file "$OUTFILE"
