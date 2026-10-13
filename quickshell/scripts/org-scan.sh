#!/usr/bin/env bash
files=(~/.emacs.d/todos.org ~/Documents/notes)

tasks=$(grep -r -A1 -E '^\*+ (TODO|IN-PROGRESS|WAITING) ' "${files[@]}" --include='*.org' |
gawk 'BEGIN { OFS = "\t" }
    function flush() { if (file != "") print file, keyword, priority, tags, category, deadline, allday, heading }

    match($0, /^(.*\.org):\*+ ([A-Z-]+) +(\[#(.)\] +)?(.*)$/, h) {
        flush()
        file = h[1]; keyword = h[2]; priority = h[4]; heading = h[5]; tags = ""; deadline = ""; allday = 0
        if (match(heading, /[ \t]+:([^ ]+):[ \t]*$/, t)) { tags = t[1]; heading = substr(heading, 1, RSTART - 1) }
        sub(/[ \t]+$/, "", heading)
        category = file; sub(/.*\//, "", category); sub(/\.org$/, "", category); sub(/^[0-9]+-/, "", category)
        next
    }
    match($0, /DEADLINE: *<([0-9]+)-([0-9]+)-([0-9]+)[^>]*>/, d) {
        allday = !match(d[0], / ([0-9]+):([0-9]+)/, t)
        deadline = mktime(d[1] " " d[2] " " d[3] " " t[1] + 0 " " t[2] + 0 " 0")
    }
    END { flush() }')

clocked=$(grep -rh 'CLOCK: \[.*=>' "${files[@]}" --include='*.org' |
    awk '{ split($NF, t, ":"); print substr($2, 2), t[1] * 60 + t[2] }')

jq -n --arg tasks "$tasks" --arg clocked "$clocked" --argjson cards "$(bash "$(dirname "$0")/flashcards.sh")" '
{tasks: [$tasks | splits("\n") | select(. != "") | split("\t")
         | {file: .[0], keyword: .[1], priority: .[2], tags: (.[3] | split(":")), category: .[4],
            deadline: (.[5] | tonumber? // null), deadlineAllDay: (.[6] == "1"), heading: .[7]}],
 clocked: (reduce ($clocked | splits("\n") | select(. != "") | split(" ")) as [$day, $minutes] ({};
             .[$day] += ($minutes | tonumber))),
 cards: $cards}'
