#!/bin/bash

# unicode animation toys. 
# usage: run `$0 --help` 

# exit nicely 
trap ctrl_c INT
function ctrl_c() {
    echo ""
    tput sgr0
    tput cnorm      # restore cursor
    case $exithint in
        fromfull) tput cup $(tput lines) $(tput cols) ; echo ;;
    esac
    exit 0
}

# setup our baseline chronology
tstamp=$(sleepenh 0)

# default delay. 0.04 is a smooth-enough 25fps
# individual throbbers may set their own delay to suit
delay=0.04 


############ character arrays

# characters for left/right/up/down slides
declare -a leftblk=( "█" "▉" "▊" "▋" "▌" "▍" "▎" "▏")
declare -a lowblk=( "█" "▇" "▆" "▅" "▄" "▃" "▂" "▁" )

# characters for a spinner around a central spot (c for corners)
declare -a cspin=("▏" "🭛" "🭙" "🭗" "🭘" "▔" "🭣" "🭢" "🭤" "🭦" "▕" "🭋" "🭉" "🭇" "🭈" "▁" "🬽" "🬼" "🬾" "🭀" )
  
# braille dot numbers are
# 14
# 25
# 36
# 78
# braille spinner (3dot version)
declare -a bspin=("⠙" "⠸" "⢰" "⣠" "⣄" "⡆" "⠇" "⠋")
# braille race (spinner with two opposing dots)
declare -a brace=("⢁" "⡈" "⠔" "⠢")
# braille2 race (spinner with two opposing pair of dots)
declare -a b2race=("⣉" "⡜" "⠶" "⢣" )
# braille 1dot gravity spinner. 8 frames top row, 4 frames next, 2 next and 1 frame at bottom. 
# gravity dot pattern: 4 4 4 4 4 4 4 4 5 5 5 5 6 6 8 7 3 3 2 2 2 2 1 1 1 1 1 1 1 1
declare -a b1gravity=(
"⠈" "⠈" "⠈" "⠈" "⠈" "⠈" "⠈" "⠈"
"⠐" "⠐" "⠐" "⠐"
"⠠" "⠠"
"⢀"
"⡀" 
"⠄" "⠄" 
"⠂" "⠂" "⠂" "⠂"
"⠁" "⠁" "⠁" "⠁" "⠁" "⠁" "⠁" "⠁" )
# braille 2dot gravity spinner. Same spin logic as 1dot, but with a second dot 15 frames later. Shorter array though!
declare -a b2gravity=("⡈" "⠌" "⠌" "⠊" "⠊" "⠊" "⠊" "⠉" "⠑" "⠑" "⠑" "⠑" "⠡" "⠡" "⢁" )
# braille 3dot gravity spinner. same logic again, 3 dots evenly spaced. even shorter array
#4 4 4 4 4 4 4 4 5 5   5 5 6 6 8 7 3 3 2 2   2 2 1 1 1 1 1 1 1 1
#5 5 6 6 8 7 3 3 2 2   2 2 1 1 1 1 1 1 1 1   4 4 4 4 4 4 4 4 5 5
#2 2 1 1 1 1 1 1 1 1   4 4 4 4 4 4 4 4 5 5   5 5 6 6 8 7 3 3 2 2
declare -a b3gravity=("⠚" "⠚" "⠩" "⠩" "⢉" "⡉" "⠍" "⠍" "⠓" "⠓" )
# same pattern, but across double width to give a better "circle" 
declare -a b3gravitywide=("⠂⠑" "⠂⠑ " "⠈⠡" "⠈⠡" "⠈⡁" "⢈⠁" "⠌⠁" "⠌⠁" "⠊⠐" "⠊⠐" )

# ascii and unicode prop
declare -a aprop=( "\\" "|" "/" "-" )
declare -a uprop=( "╲" "│" "╱" "─"  )
# ascii and unicode wiggler
declare -a awiggle=( "\\" "|" "/" "|" )
declare -a uwiggle=( "╲" "│" "╱" "│"  )

# wiggling worm I learnt about from Screwtape
declare -a worm=("-" ">" ")" "|" "(" "<" "-" "<" "(" "|" ")" ">" )

# scanner effect arrays
declare -a hscan=( "▏" "🭰" "🭱" "🭲" "🭳" "🭴" "🭵" "▕" )
declare -a vscan=( "▔" "🭶" "🭷" "🭸" "🭹" "🭺" "🭻" "▁" )

# dancer
declare -a dancer=( "🯅 " "🯆 " "🯅 " "🯇 " "🯅 " "🯈 " )

# segmented display
declare -a segmented=( "🯰 " "🯱 " "🯲 " "🯳 " "🯴 " "🯵 " "🯶 " "🯷 " "🯸 " "🯹 " )

# tally marks
# note: I'm using the "logically correct" glyphs for counting rod numerals for
# 1-4 even though they dont match the look correctly, unless they do for you.
# Who even knows. See the unicode-tally-rant.md file for more details.
declare -a tally=( "𝍠 " "𝍡 " "𝍢 " "𝍤 " "𝍸 " )
# Ideographic tally marks are complete and consistent in my testing
declare -a ideographic=( "𝍲 " "𝍳 " "𝍴 " "𝍵 " "𝍶 " )


# kitt colours (reds) and brightnesses (brightest to dimmest and black)
declare -a red=( "$(tput setaf 196)" "$(tput setaf 160)" "$(tput setaf 88)" "$(tput setaf 52)" "$(tput setaf 16)" )
# array of bulb brightnesses. 0 is lit, 1,2,3 is less lit and 4 is off
declare -a brightness=( "█" "▓" "▒" "░" " " ) 
# illumination matrix - short leading light leakage (3), and long fading tail (1 2 3).  
kitt1R="1 0 3 4 4 4 4 4" # travelling right from position 1
kitt2R="2 1 0 3 4 4 4 4"
kitt3R="3 2 1 0 3 4 4 4"
kitt4R="4 3 2 1 0 3 4 4"
kitt5R="4 4 3 2 1 0 3 4"
kitt6R="4 4 4 3 2 1 0 3"
kitt7R="4 4 4 4 3 2 1 0" # rightmost bulb at position 7
kitt6L="4 4 4 4 4 3 0 1" # travelling left from position 6
kitt5L="4 4 4 4 3 0 1 2"
kitt4L="4 4 4 3 0 1 2 3"
kitt3L="4 4 3 0 1 2 3 4"
kitt2L="4 3 0 1 2 3 4 4"
kitt1L="3 0 1 2 3 4 4 4"
kitt0L="0 1 2 3 4 4 4 4" # leftmost bulb at position 0

#dot/circle like characters
# ⊙       2299    CIRCLED DOT OPERATOR
# ⊚       229A    CIRCLED RING OPERATOR
# ⌾       233E    APL FUNCTIONAL SYMBOL CIRCLE JOT
# ⍟       235F    APL FUNCTIONAL SYMBOL CIRCLE STAR
# ⏣       23E3    BENZENE RING WITH CIRCLE
# ⓞ       24DE    CIRCLED LATIN SMALL LETTER O
# Ⓞ       24C4    CIRCLED LATIN CAPITAL LETTER O
# ○       25CB    WHITE CIRCLE
# ◌       25CC    DOTTED CIRCLE
# ◯       25EF    LARGE CIRCLE
# ⚬       26AC    MEDIUM SMALL WHITE CIRCLE
# ❍       274D    SHADOWED WHITE CIRCLE
# ⦾       29BE    CIRCLED WHITE BULLET
# ⦿       29BF    CIRCLED BULLET
# ⨀       2A00    N-ARY CIRCLED DOT OPERATOR
# ⭗       2B57    HEAVY CIRCLE WITH CIRCLE INSIDE
# ⭘       2B58    HEAVY CIRCLE
# ￮       FFEE    HALFWIDTH WHITE CIRCLE
# 🔾       1F53E   LOWER RIGHT SHADOWED WHITE CIRCLE
# 🔿       1F53F   UPPER RIGHT SHADOWED WHITE CIRCLE
# 🞅       1F785   MEDIUM BOLD WHITE CIRCLE
# 🞆       1F786   BOLD WHITE CIRCLE
# 🞇       1F787   HEAVY WHITE CIRCLE
# 🞈       1F788   VERY HEAVY WHITE CIRCLE
# 🞉       1F789   EXTREMELY HEAVY WHITE CIRCLE
# 🞊       1F78A   WHITE CIRCLE CONTAINING BLACK SMALL CIRCLE
# 
# ·       00B7    MIDDLE DOT
# ͼ       037C    GREEK SMALL DOTTED LUNATE SIGMA SYMBOL
# ͽ       037D    GREEK SMALL REVERSED DOTTED LUNATE SIGMA SYMBOL
# Ͼ       03FE    GREEK CAPITAL DOTTED LUNATE SIGMA SYMBOL
# Ͽ       03FF    GREEK CAPITAL REVERSED DOTTED LUNATE SIGMA SYMBOL
# ൎ       0D4E    MALAYALAM LETTER DOT REPH
# ᐧ       1427    CANADIAN SYLLABICS FINAL MIDDLE DOT
# ⸱       2E31    WORD SEPARATOR MIDDLE DOT
# ⸳       2E33    RAISED DOT
# ・    30FBKATAKANA MIDDLE DOT
# Ꜿ       A73E    LATIN CAPITAL LETTER REVERSED C WITH DOT
# ꜿ       A73F    LATIN SMALL LETTER REVERSED C WITH DOT
# ꞏ       A78F    LATIN LETTER SINOLOGICAL DOT
# ･       FF65    HALFWIDTH KATAKANA MIDDLE DOT
# 𐄁       10101   AEGEAN WORD SEPARATOR DOT
# 


# clock faces. half-hour ticks is the resolution available via unicode
clockfaces_all=("🕐" "🕜" "🕑" "🕝" "🕒" "🕞" "🕓" "🕟" "🕔" "🕠" "🕕" "🕡" "🕖" "🕢" "🕗" "🕣" "🕘" "🕤" "🕙" "🕥" "🕚" "🕦" "🕛" "🕧" )
# clock faces - top of the hour only
clockfaces_hours=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛" )

# moon faces. unicode order is northern-hemisphere style
moonfaces=( "🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘")


# cache some tput outputs 
columns=$(tput cols)
inverse=$(tput rev)
reset=$(tput sgr0)
backone=$(tput cub 1)
backtwo=$(tput cub 2)
backthree=$(tput cub 3)
sc=$(tput sc)
rc=$(tput rc)
el=$(tput el)

########################################## functions

### marquee

do_marquee() {
    message="$@"
    # TODO: make the plane/cloud a user-settable option
    if [ -n "$message" ] ; then
        lead=" 🛩  "  # goes ahead of the message
        tail=" ☁  "  # trails behind the message
        message=" $message" # leading space makes the way it ends look centered
    fi
    stopat=$((columns-${#tail}-${#message}-${#lead})) 

    tput cub 100    # TODO: detect character position and account for it in $pos rather than this kludge to aim for leftmost
    pos=2 # starting position. honestly not quite sure why this has to be non-zero :/
    while [ $pos -lt $stopat ] ; do
        echo -n "${rc} ${sc}"
        for cnt in {7..0} ; do
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${rc}${tail}${inverse}${leftblk[$cnt]}${message}${reset}${leftblk[$cnt]}${lead}"
        done
        pos=$((pos+1))
    done
}

# TODO: on the l/r and u/d block moving, consider a third param (prob $2) to indicate moving in, or moving out. The current implementation is a moving in THEN a moving out, 

### block: left/right. $1 for direction, $2 for number of loops
do_blk_lr() {
    # defaults for values and loop count
    vals=$(echo {7..0}) # default: going right
    [ "$1" == "left" ] && vals=$(echo {0..7})
    loops=${2:-1} # default: loop once

    for loops in {1..$loops} ; do 
        echo -n "$reset"
        for cnt in $vals ; do
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${backone}${leftblk[$cnt]}"
        done
        echo -n "$inverse"
        for cnt in $vals ; do
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${backone}${leftblk[$cnt]}"
        done
    done
}

### block: up/down. $1 for direction, $2 for number of loops
do_blk_ud() {
    # defaults for values and loop count
    vals=$(echo {0..7}) # default: going down
    [ "$1" == "up" ] && vals=$(echo {7..0})
    loops=${2:-1} # default: loop once
    
    loops=${2:-1}
    for loops in {1..$loops} ; do 
        echo -n "$inverse"
        for cnt in $vals ; do
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${backone}${lowblk[$cnt]}"
        done
        echo -n "$reset"
        for cnt in $vals ; do
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${backone}${lowblk[$cnt]}"
        done
    done
}

### step through an array of single characters
# basically implements the various generic throb/spin/prop etc throbbers
# it has a few options to allow it to be used cleverly for other needs too
do_stepchar() {
    # $1 = "rev" to reverse direction. (default/any other string: forward) 
    # $2 = [0-9]* - a number to denote how many loops (default: 1)
        # both arguments are optional

    # defaults for values and loop count
    arraysize=${#spin[@]}
    # seq doesn't feel optimal, but I can't do {0..$variable} expansion in bash)
    vals=$(seq 0 $((arraysize-1))) # default: going clockwise
    [ "$1" == "rev" ] && vals=$(seq $((arraysize-1)) -1 0)
    loops=${2:-1} # default: loop once

    for loop in $(seq 1 $loops) ; do 
        for cnt in $vals ; do
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${rc}${spin[$cnt]}"
        done
    done
}


# kitt/cylon scanner
do_kitt() {
    for keybulb in kitt{1..7}R kitt{6..0}L; do
        declare -n kittstate=$keybulb
        tstamp=$(sleepenh $tstamp $delay) 
        echo -n "$rc"
        for l in $kittstate ; do # l for lit-up state? 
            echo -n "${red[$l]}${brightness[$l]}${brightness[$l]}${brightness[$l]}"
        done
        echo -n "${el}"
    done
}

##################################################### main

# start the run by hiding the cursor and saving position
tput civis
echo -n "$sc"

# choose our display mode - $1 in a case statement. 
#
# these are not in order of implementation.
# They may in the future be put into some vague order of logical progression/grouping though
case $1 in
    cross) # Block slides smoothly across, then smoothly down. Forever
        # across and down in a single character space, forever
        while true ; do
            do_blk_lr right 1
            do_blk_ud down 1
        done
        ;;
    marquee) # Block slides smoothly across an entire line then stops. # If $2/etc then it becomes a plane banner with those args as text # Bug: Does not end cleanly if $2 has wide unicode
        shift
        do_marquee "$*"
        ;;
    borderspin) # Parts of the border rotates forever aound an empty middle. 1 space
        declare -n spin=cspin
        while true ; do
            do_stepchar 
        done
        ;;
    movingblock) # (TODO) A block slides smoothly around a 2x2 space
        while true ; do
            do_blk_lr right 1
            do_blk_ud down 1
            do_blk_lr left 1
            do_blk_ud up 1
        done
        ;;
    braillespin) # Three dots rotate around an empty middle. 1 char
        declare -n spin=bspin
        while true ; do
            do_stepchar
        done
        ;;
    braillerace) # Two dots circling each other (1space)
        declare -n spin=brace
        while true ; do
            do_stepchar
        done
        ;;
    braille2race) # Two sets of two dots circling each other (1space)
        declare -n spin=b2race
        while true ; do
            do_stepchar
        done
        ;;
    braillesnake) # (TODO) A "snake" game in a 2x4 braille grid (1 space)
        # Start with it as a 1dot snake, it finds and eats a prize, becomes 2dot, etc, till 2x4 is full
        # note: have to plan the whole game?
        true
        ;;
    gravity1dot) # MS/Win style: speeds up going down, slows at top. 1dot version
        declare -n spin=b1gravity
        while true ; do
            do_stepchar
        done
        ;;
    gravity2dot) # MS/Win style: speeds up going down, slows at top. 2dot version
        declare -n spin=b2gravity
        while true ; do
            do_stepchar
        done
        ;;
    gravity3dot) # MS/Win style: speeds up going down, slows at top. 3dot version
        declare -n spin=b3gravity
        while true ; do
            do_stepchar
        done
        ;;
    gravity3dotwide) # MS/Win style: speeds up going down, slows at top. 3dot wide version
        declare -n spin=b3gravitywide
        while true ; do
            do_stepchar
        done
        ;;
    kitt|cylon) # K.I.T.T/cylon scanner on black bg. Loops forever. 1 line by default. # $2 as "full" for fullscreen
        # orig reference: https://www.youtube.com/watch?v=usui7ECHPNQ (5m20)
        #   * 8 elements
        #   * brightens over ~3 frames
        #   * dims over ~12 frames (previous 4 elements
        #   * tiny light leakage into next?

        # if we get a "full" param, we clear the screen and kitt at 3/4 the way down
        tput setab 16 # set a black background
        if [ "$2" == "full" ] ; then
            tput cup 0 0 # move to top of the screen
            tput ed # clear screen (does ed mean "erase display"?)
            tput cud $(($(tput lines)*3/4)) # move to 3/4 of the way down
            exithint="fromfull" # hint to the ctrl_c function
        else
            tput el     # erase line (makes it black as per setab 7)
        fi
        # the scanner is 8 lights, each is 3 charwide, so 24 charwide total
        # this cuf centers it
        tput cuf $(( ($(tput cols)/2)-12 )) 
        echo -n "${sc}"
        delay=0.142857 # 7fps means it makes one scan L-R or R-L per second
        delay=0.0714285 # 14fps means it makes one full scan L-R-L loop per sec
        delay=0.112857 # aiming to get super close to the reference video speed (31.6 LRL in 20 seconads)
        delay=0.107142 # 9 1/3 fps means a L-R-L loop in 1.5 seconds is a nice round number whilst still very close to the reference videoa
        while true ; do
            do_kitt 1   # each do_kitt is a 14bulb loop (inner 6 bulbs once each going left/right, outermost bulbs once each on the bounce)
        done
        ;;
    dot) # (TODO) A growing and shrinking solid dot (1space)

        true
        ;;
    tunnel) # (TODO) like dot, but zooms into it, looping. (1space)
        true
        ;;
    asciiprop|prop|uniprop|asciiwiggle|wiggle|uniwiggle) # Traditional "propeller" spinner using -\|/ # "wiggle" version reverses rather than rotates # uniprop/uniwiggle for unicode character version
        case $1 in
            uniwiggle) declare -n spin=uwiggle ;;
            asciiwiggle|wiggle) declare -n spin=awiggle ;;
            uniprop) declare -n spin=uprop ;;
            asciiprop|prop|*) declare -n spin=aprop ;;
        esac
        delay=0.25 # complate spin per second 
        while true ; do
            do_stepchar 
        done
        ;;
    scanner) # single character scanner
        delay=0.125 # 8fps = 1second L-R or T-B. 4 seconds for a full loop
        while true ; do
            declare -n spin=hscan
            do_stepchar fw 1
            do_stepchar rev 1
            declare -n spin=vscan
            do_stepchar fw 1
            do_stepchar rev 1
        done
        ;;
    dancer) # dancing stick figure
        delay=0.3333 # 3fps looks about right. 2 seconds for a full danceloop
        declare -n spin=dancer
        echo -n "$sc"
        while true ; do
            do_stepchar 
        done
        ;;
    tally|ideographic) # Tally marker counting. Slowly grows across the line. # 0.5s/stroke, 2.5s/tally block - or 100seconds/80char term width. # $2 to set a count target then stop # Doesn't look right? Blame unicode consortium for lack of options. 
        # TODO: a neat idea would be have this increment only on SIGINFO, so it could tick forward via an external call. Probably need a dedicated do_tally function though?
        # TODO: esp in relation to the previous - have it output the total in numerals when it finishes
        declare -n spin=tally
        [ $1 == "ideographic" ] && declare -n spin=ideographic
        charwidth=${#spin[0]}
        COLUMNS=$(tput cols)
        newlineat=$((COLUMNS/charwidth))
        [ -n "$2" ] && stopat=$2
        echo -n "$sc"
        delay=0.5 # 1 tally mark per 0.5 seconds
        while true ; do
            do_stepchar 
            charcount=$((charcount+1))
            tallycount=$((tallycount+5))
            [ $charcount -ge $newlineat ] && echo "" && charcount=0
            echo -n "$sc"
            [ -n "$stopat" ] && [ $((tallycount/5)) -ge $((stopat/5)) ] && break
        done
        # this is a microcosm of the main do_stepchar loop to finish up 
        for finalise in $(seq 0 $((stopat-tallycount-1))) ; do
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${rc}${spin[$finalise]}"
        done
        tstamp=$(sleepenh $tstamp $delay) 
        echo ""
        ;;
    countdown) # countdown from 9 to 0 (then exit - no looping)
        declare -n spin=segmented
        echo -n "$sc"
        delay=0.5 # array of 10 means do_stepchar will double-delay
        do_stepchar rev 1
        ;;
    worm) # a wriggling worm. 1 space
        declare -n spin=worm
        delay=0.08333 # 12fps = 1 second for a full loop
        delay=0.16666 # 6fps = 1 second to flip once, another to return
        while true ; do
            do_stepchar 
        done
        ;;
    clockslow) # A clock ticks away the moments that make up a dull day
        declare -n spin=clockfaces_all
        delay=0.5 # one "hour" per second
        while true ; do
            do_stepchar
        done
        ;;
    clockfast) # A clock fritters and wastes the hours in an offhand way
        declare -n spin=clockfaces_hours
        delay=0.083333 # 12fps = 12 hours displayed per second
        while true ; do
            do_stepchar
        done
        ;;
    moon) # Phases of the moon. # $2 = "north" for anticlockwise/northern hemisphere phase sequence
        # array is in unicode order, which is also n.hemisphere view.
        # Default here is to reverse the direction as I think that 
        # looks better as a spinner (giving apparent left-to-right motion)
        # ...and also matches my s.hemisphere familiarity of moon phases 
        # https://www.abc.net.au/news/science/2018-01-24/beginners-guide-to-the-moon/9320770
        declare -n spin=moonfaces
        direction=rev
        [ "$2" == "north" ] && direction=forward
        delay=0.125 # 8fps = one second for a complete moon cycle
        while true ; do
            do_stepchar $direction 1
        done
        ;;
    --help) # This help. You're reading it. 
        echo "
A variety of unicode \"throbber\" style toys
ie, background-activity-indicators which animate within a small space. 

Most loop forever and can be ended cleanly with ^c

\$1 (required) indicates the type of throbber.
\$2 (optional) and any further params are throbber-specific

\$1 options are:"

#        egrep "^    [a-z0-9|-]*\).*# " $0 | sed -e 's/)//' | column -t -s'#'
        egrep "^    [a-z0-9|*-]*\).*# " $0 | grep -v TODO | sed -e 's/^    /  /g ; s/)// ; s/#/\n        /g'
        ;;
    *) # Unrecognised options trigger marquee output with a "--help"ful hint
        do_marquee "Run \"$0 --help\" for options"
        ;;
esac

tput cnorm

