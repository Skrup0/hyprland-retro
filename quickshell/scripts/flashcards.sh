#!/usr/bin/env bash
notes=~/Documents/notes
new_per_day=100
max_reviews=1000

start=$(date -d "$(date -d '4 hours ago' +%F) 04:00" +%s)
today=$(date -u -d @$start +%FT%TZ)
now=$(date -u +%FT%TZ)

grep -rh '^|' "$notes" --include='*.org' |
awk -F'|' -v now="$now" -v today="$today" -v new_per_day=$new_per_day -v max_reviews=$max_reviews '
    { time = $3; gsub(/ /, "", time) }
    time !~ /Z$/ { rows = 0; next }
    $2 !~ /\*/   { if (++rows == 2) first = time; last = time; next }
    {
        total++
        if (rows == 1) { if (time < now) new++ }
        else {
            if (first >= today) learned++
            if (last >= today) rated++
            if (time < now) { if (last >= today) relearning++; else due++ }
        }
        rows = 0
    }
    END {
        left = max_reviews - rated
        allowed = new_per_day - learned
        if (allowed > left - due - relearning) allowed = left - due - relearning
        if (allowed > new) allowed = new
        if (allowed < 0) allowed = 0
        if (due > left) due = left > 0 ? left : 0
        printf "{\"review\": %d, \"total\": %d}\n", due + relearning + allowed, total
    }'
