#!/bin/bash

# Usage: telediff-crtsh.sh <domain> <telediff_channel>

SEARCH_TERM="$1"
TELEDIFF_CHANNEL="$2"
TMPFILE=$(mktemp)

psql -h crt.sh -p 5432 -U guest certwatch -Atc "
SELECT DISTINCT NAME_VALUE
FROM certificate_and_identities
WHERE plainto_tsquery('certwatch', '$SEARCH_TERM') @@ identities(CERTIFICATE)
  AND NAME_VALUE ILIKE ('%' || '$SEARCH_TERM' || '%')
  AND coalesce(x509_notAfter(CERTIFICATE), 'infinity'::timestamp) >= date_trunc('year', now() AT TIME ZONE 'UTC')
  AND x509_notAfter(CERTIFICATE) >= now() AT TIME ZONE 'UTC'
LIMIT 10000;
" | sort -u > "$TMPFILE"

if [ $? -eq 0 ]; then
  telediff notify --attach -c "$TELEDIFF_CHANNEL" --body-prepend "crt.sh identities list changed for $1
" --no-path-in-body -f ~/.local/share/telediff/$1-crtsh.txt < "$TMPFILE"
else
  echo "psql query failed, not calling telediff."
fi

rm -f "$TMPFILE"
