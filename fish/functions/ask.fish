function ask --description 'One-off question to Claude, read-only, no session'
    if test (count $argv) -eq 0
        echo 'ask: <question>   — try the ? abbreviation' >&2
        return 2
    end

    # --disallowedTools is what makes this read-only; --allowedTools only
    # auto-approves. --verbose is required or stream-json prints nothing.
    claude -p --safe-mode --no-session-persistence --strict-mcp-config \
        --disable-slash-commands --model sonnet --effort low \
        --output-format stream-json --include-partial-messages --verbose \
        --allowedTools WebSearch WebFetch \
        --disallowedTools Bash Write Edit NotebookEdit Read Glob Grep Task \
        --system-prompt 'Answer directly and concisely: a few sentences, no preamble, no follow-up offers. Search the web when the answer depends on current or recent information, and cite the sources when you do. Reply in the language of the question.' \
        -- "$argv" \
        | jq --unbuffered -j 'select(.type == "stream_event" and .event.delta.type == "text_delta") | .event.delta.text'

    # $pipestatus, not $status: jq exits 0 after printing nothing when claude dies.
    set -l rc $pipestatus[1]
    echo
    test $rc -ne 0; and echo "ask: claude exited $rc" >&2
    return $rc
end
