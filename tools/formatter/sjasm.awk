# SjASMPlus formatting rules.
function trim(s) {
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    return s
}

function split_comment(s,    i, ch, quote, escaped) {
    comment = ""
    quote = ""
    escaped = 0
    for (i = 1; i <= length(s); i++) {
        ch = substr(s, i, 1)
        if (escaped) {
            escaped = 0
        } else if (ch == "\\" && quote != "") {
            escaped = 1
        } else if (quote != "" && ch == quote) {
            quote = ""
        } else if (quote == "" && (ch == "\"" || ch == "'")) {
            quote = ch
        } else if (quote == "" && ch == ";") {
            comment = trim(substr(s, i))
            return trim(substr(s, 1, i - 1))
        }
    }
    return trim(s)
}

function normalize_hex(s,    i, j, ch, quote, escaped, prev, nextchar, digits, out) {
    out = ""
    quote = ""
    escaped = 0
    for (i = 1; i <= length(s); i++) {
        ch = substr(s, i, 1)
        if (escaped) {
            escaped = 0
        } else if (ch == "\\" && quote != "") {
            escaped = 1
        } else if (quote != "" && ch == quote) {
            quote = ""
        } else if (quote == "" && (ch == "\"" || ch == "'")) {
            quote = ch
        }
        if (ch == "#" && quote == "") {
            prev = (i > 1 ? substr(s, i - 1, 1) : "")
            j = i + 1
            while (j <= length(s) && substr(s, j, 1) ~ /^[0-9a-fA-F]$/)
                j++
            nextchar = (j <= length(s) ? substr(s, j, 1) : "")
            digits = substr(s, i + 1, j - i - 1)
            if (digits != "" && prev !~ /^[[:alnum:]_]$/ && nextchar !~ /^[[:alnum:]_]$/) {
                out = out "0x" digits
                i = j - 1
                continue
            }
        }
        out = out ch
    }
    return out
}

function indent_statement() {
    return "        "
}

function format_asm_line(raw,    code, name, rest, directive, operands, label, local) {
    code = split_comment(raw)
    if (code == "") return (comment != "" ? comment : "")

    if (match(code, /^[.@$A-Za-z_][[:alnum:]_.@$]*/)) {
        name = substr(code, 1, RLENGTH)
        rest = trim(substr(code, RLENGTH + 1))
        sub(/^:[ \t]*/, "", rest)
        if (match(tolower(rest), /^(equ|eval)[ \t]+/)) {
            directive = tolower(substr(rest, 1, RLENGTH - 1))
            operands = normalize_hex(trim(substr(rest, RLENGTH + 1)))
            code = sprintf("%-20s %s %s", name, directive, operands)
            return code (comment != "" ? " " comment : "")
        }
        if (match(tolower(rest), /^(db|defb|dw|defw|dd|defd|ds|defs|incbin|binary)([ \t]+|$)/)) {
            directive = tolower(substr(rest, 1, RLENGTH))
            operands = substr(rest, RLENGTH + 1)
            code = name " " directive operands
            return code (comment != "" ? " " comment : "")
        }
    }

    code = normalize_hex(code)
    if (code ~ /^[ \t]*\.[A-Za-z_][[:alnum:]_.@$]*[ \t]*$/) {
        sub(/^[ \t]*/, "", code)
        sub(/[ \t]*$/, "", code)
    } else if (match(code, /^[ \t]*[.@$A-Za-z_][[:alnum:]_.@$]*:/)) {
        label = substr(code, RSTART, RLENGTH)
        sub(/^[ \t]*/, "", label)
        sub(/[ \t]*$/, "", label)
        rest = trim(substr(code, RSTART + RLENGTH))
        code = label (rest != "" ? " " rest : "")
    } else if (code ~ /^[ \t]*[A-Za-z_.$@][[:alnum:]_.@$]*[ \t]*$/) {
        label = trim(code)
        if (tolower(label) !~ /^(ccf|cpl|daa|di|ei|exx|halt|ldd|lddr|ldi|ldir|neg|nop|otdr|otir|outd|outi|reti|retn|rlca|rla|rrca|rra|rrd|rld|scf|ret|else|endif|endr|endm)$/)
            code = label
        else
            code = indent_statement() trim(code)
    } else {
        code = indent_statement() trim(code)
    }
    return code (comment != "" ? " " comment : "")
}

{
    lines[NR] = $0
}

END {
    pending_blank = 0
    for (i = 1; i <= NR; i++) {
        raw = lines[i]
        sub(/[ \t]+$/, "", raw)
        if (raw ~ /^[ \t]*$/) {
            pending_blank++
            continue
        }
        while (pending_blank > 0) {
            print ""
            pending_blank--
        }
        if (raw ~ /^[ \t]*;/) {
            print raw
            continue
        }
        comment = ""
        code = split_comment(raw)
        if (code ~ /^[.@$A-Za-z_][[:alnum:]_.@$]*[ \t]*:?[ \t]*$/ && i < NR) {
            saved = comment
            next_comment = ""
            next_code = split_comment(lines[i + 1])
            next_comment = comment
            if (match(tolower(next_code), /^[ \t]*(equ|eval)[ \t]+/)) {
                name = code
                sub(/^[ \t]*/, "", name)
                sub(/[ \t]*$/, "", name)
                sub(/:[ \t]*$/, "", name)
                expr = trim(substr(next_code, RLENGTH + 1))
                expr_comment = (next_comment != "" ? next_comment : saved)
                formatted = format_asm_line(name " equ " expr)
                i++
                if (expr_comment != "") formatted = formatted " " expr_comment
                print formatted
                continue
            }
            comment = saved
        }
        print format_asm_line(raw)
    }
}
