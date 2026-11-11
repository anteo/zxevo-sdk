# Conservative z88dk z80asm formatter: change leading indentation only.
# Do not parse operands/comments: AF', quoted semicolons, suffix hex literals,
# local @labels and expressions must survive byte for byte.
{
    code = $0
    sub(/^[ \t]+/, "", code)
    if (code == "") {
        print ""
    } else if (code ~ /^;/) {
        print $0
    } else if (code ~ /^[.@$A-Za-z_][[:alnum:]_.@$]*:/ ||
               toupper(code) ~ /^(SECTION|PUBLIC|EXTERN|GLOBAL|INCLUDE|DEFC|IF|IFDEF|IFNDEF|ELSE|ENDIF|END)([ \t]|$)/ ||
               tolower(code) ~ /^[.@$a-z_][[:alnum:]_.@$]*[ \t]+(equ|defc)[ \t]/) {
        print code
    } else {
        print "        " code
    }
}
