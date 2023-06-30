#!/bin/bash

# unicode animation toys. 
# usage: run `$0 --help` 

# exit cleanly. perhaps with stats
trap cleanxit 1 2 3 6 15  # aka: HUP INT QUIT ABRT TERM
cleanxit() {
    echo "$reset"
    tput cnorm      # restore cursor
    case $exithint in
        fromfull) tput cup $(($(tput lines)-2)) $(tput cols) ;;
        count) echo " $count " >&2 ;;
        hours*) # when we were displaying hours on a clock
            # exithint here is "hours fps frames-per-displayed-hour
            # TODO: fix for when we have $ALARM set - because no set fps that way
            subhints=${exithint#* }
            fps=${subhints% *}
            fph=${subhints#* }
            durationsec=$(echo "scale=1;(${count}-1)/${fps}" | bc)
            displayedhours=$(echo "scale=1;(${count}-1)/${fph}" | bc)
            if [ -n "$ALARM" ] ; then
                echo " $count ticks ($displayedhours \"hours\" elapsed on display)" >&2
            else
                echo " $durationsec seconds ($displayedhours \"hours\" elapsed on display)" >&2
            fi
            ;;
    esac
    exit 0
}

# using the SIGALRM signal for "increment throbber only on a signal" - this allows for our tick to be external
trap do_tick SIGALRM
do_tick() {
    # jobs -p | xargs -r kill # this feels like a nice way to kill the backgrounds, but in practice it gets noisy if the ticks are too quick (eg, every 0.005 seconds. tested with "tally"
    # additionally, if SIGALRM arrives whilst we're inside do_tick, then do_tick just runs again and the ALRM doesn't move on, so it's in our best interest to make this functional as minimal as possible
    # Sometimes something glitches (race condition maybe?) and a literal "Alarm clock" is printed to the terminal, creating visual noise and a newline. I don't know what makes this happen, but it happens more often at shorter delays, but has been observed at rates as low as 0.5 seconds between SIGALRMs. 
    true
}

# setup our baseline chronology
tstamp=$(sleepenh 0)

# default delay. 0.04 is a smooth-enough 25fps
# individual throbbers may set their own delay to suit
delay=0.04 

# sometimes we count how many times we did a thing. 
# ...it may be frames, or loops. depends on the throbber
count=0

# for do_stepchar, these allow multiple characters to become a block
# default number of characters to display at a time 
# and lines at a time
chars=1
lineshint=1

do_delay() {
    if [ -n "$ALARM" ] ; then
        # external control - we tick on a remote SIGALRM only
        while true ; do
            sleep 2 & # one of these gets left behind on every ALRM
                        # ... so we want it big enough to not fork excessively
                        # ... but small enough to expire on it's own quickly
                        # 2 seconds is my compromise of choice
            wait || break   # wait till sleep finishes naturally, or break if we TRAP that alarm (SIGALRM)
        done
    else
        # we're running on our internal tick
        tstamp=$(sleepenh $tstamp $delay)
    fi
}

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
# all possible braille dot patterns (255 of them), in unicode order
declare -a braille=( 
"⠁" "⠂" "⠃" "⠄" "⠅" "⠆" "⠇" "⠈" "⠉" "⠊" "⠋" "⠌" "⠍" "⠎" "⠏" "⠐" "⠑" "⠒" "⠓" "⠔"
"⠕" "⠖" "⠗" "⠘" "⠙" "⠚" "⠛" "⠜" "⠝" "⠞" "⠟" "⠠" "⠡" "⠢" "⠣" "⠤" "⠥" "⠦" "⠧" "⠨"
"⠩" "⠪" "⠫" "⠬" "⠭" "⠮" "⠯" "⠰" "⠱" "⠲" "⠳" "⠴" "⠵" "⠶" "⠷" "⠸" "⠹" "⠺" "⠻" "⠼"
"⠽" "⠾" "⠿" "⡀" "⡁" "⡂" "⡃" "⡄" "⡅" "⡆" "⡇" "⡈" "⡉" "⡊" "⡋" "⡌" "⡍" "⡎" "⡏" "⡐"
"⡑" "⡒" "⡓" "⡔" "⡕" "⡖" "⡗" "⡘" "⡙" "⡚" "⡛" "⡜" "⡝" "⡞" "⡟" "⡠" "⡡" "⡢" "⡣" "⡤"
"⡥" "⡦" "⡧" "⡨" "⡩" "⡪" "⡫" "⡬" "⡭" "⡮" "⡯" "⡰" "⡱" "⡲" "⡳" "⡴" "⡵" "⡶" "⡷" "⡸"
"⡹" "⡺" "⡻" "⡼" "⡽" "⡾" "⡿" "⢀" "⢁" "⢂" "⢃" "⢄" "⢅" "⢆" "⢇" "⢈" "⢉" "⢊" "⢋" "⢌"
"⢍" "⢎" "⢏" "⢐" "⢑" "⢒" "⢓" "⢔" "⢕" "⢖" "⢗" "⢘" "⢙" "⢚" "⢛" "⢜" "⢝" "⢞" "⢟" "⢠"
"⢡" "⢢" "⢣" "⢤" "⢥" "⢦" "⢧" "⢨" "⢩" "⢪" "⢫" "⢬" "⢭" "⢮" "⢯" "⢰" "⢱" "⢲" "⢳" "⢴"
"⢵" "⢶" "⢷" "⢸" "⢹" "⢺" "⢻" "⢼" "⢽" "⢾" "⢿" "⣀" "⣁" "⣂" "⣃" "⣄" "⣅" "⣆" "⣇" "⣈"
"⣉" "⣊" "⣋" "⣌" "⣍" "⣎" "⣏" "⣐" "⣑" "⣒" "⣓" "⣔" "⣕" "⣖" "⣗" "⣘" "⣙" "⣚" "⣛" "⣜"
"⣝" "⣞" "⣟" "⣠" "⣡" "⣢" "⣣" "⣤" "⣥" "⣦" "⣧" "⣨" "⣩" "⣪" "⣫" "⣬" "⣭" "⣮" "⣯" "⣰"
"⣱" "⣲" "⣳" "⣴" "⣵" "⣶" "⣷" "⣸" "⣹" "⣺" "⣻" "⣼" "⣽" "⣾" "⣿")


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
declare -a dancer=( "🯅 " "🯆 " "🯅 " "🯇 " "🯈 " ) # 4 dance moves. we repeat the most neutral because it looks better

# segmented display
declare -a segmented=( "🯰 " "🯱 " "🯲 " "🯳 " "🯴 " "🯵 " "🯶 " "🯷 " "🯸 " "🯹 " )

# tally marks
# note: I'm using the "logically correct" glyphs for counting rod numerals for
# 1-4 even though they dont match the look correctly, unless they do for you.
# Who even knows. See the unicode-tally-rant.md file for more details.
declare -a tally=( "𝍠 " "𝍡 " "𝍢 " "𝍣 " "𝍸 " )
# Ideographic tally marks are complete and consistent in my testing
declare -a ideographic=( "𝍲 " "𝍳 " "𝍴 " "𝍵 " "𝍶 " )

# dice
declare -a d6=("⚀" "⚁" "⚂" "⚃" "⚄" "⚅")

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
# ⌾       233E    APL FUNCTIONAL SYMBOL CIRCLE JOT
# ⍟       235F    APL FUNCTIONAL SYMBOL CIRCLE STAR
# ￮       FFEE    HALFWIDTH WHITE CIRCLE
# ⚬       26AC    MEDIUM SMALL WHITE CIRCLE
# ⊙       2299    CIRCLED DOT OPERATOR
# ⊚       229A    CIRCLED RING OPERATOR
# ❍       274D    SHADOWED WHITE CIRCLE
# ○       25CB    WHITE CIRCLE
# ◌       25CC    DOTTED CIRCLE
# ⦾       29BE    CIRCLED WHITE BULLET
# ⏣       23E3    BENZENE RING WITH CIRCLE
# ⓞ       24DE    CIRCLED LATIN SMALL LETTER O
#
# Ⓞ       24C4    CIRCLED LATIN CAPITAL LETTER O
# ・    30FBKATAKANA MIDDLE DOT
# ⦿       29BF    CIRCLED BULLET
# ⨀       2A00    N-ARY CIRCLED DOT OPERATOR
# 🔾       1F53E   LOWER RIGHT SHADOWED WHITE CIRCLE
# 🔿       1F53F   UPPER RIGHT SHADOWED WHITE CIRCLE
# ⭗       2B57    HEAVY CIRCLE WITH CIRCLE INSIDE
# ⭘       2B58    HEAVY CIRCLE
# 🞅       1F785   MEDIUM BOLD WHITE CIRCLE
# 🞆       1F786   BOLD WHITE CIRCLE
# 🞇       1F787   HEAVY WHITE CIRCLE
# 🞈       1F788   VERY HEAVY WHITE CIRCLE
# 🞉       1F789   EXTREMELY HEAVY WHITE CIRCLE
# 🞊       1F78A   WHITE CIRCLE CONTAINING BLACK SMALL CIRCLE
# ◯       25EF    LARGE CIRCLE
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
# Ꜿ       A73E    LATIN CAPITAL LETTER REVERSED C WITH DOT
# ꜿ       A73F    LATIN SMALL LETTER REVERSED C WITH DOT
# ꞏ       A78F    LATIN LETTER SINOLOGICAL DOT
# ･       FF65    HALFWIDTH KATAKANA MIDDLE DOT
# 𐄁       10101   AEGEAN WORD SEPARATOR DOT
# 


# clock faces. half-hour ticks is the resolution available via unicode
clockfaces_all=( "🕛" "🕧"  "🕐" "🕜" "🕑" "🕝" "🕒" "🕞" "🕓" "🕟" "🕔" "🕠" "🕕" "🕡" "🕖" "🕢" "🕗" "🕣" "🕘" "🕤" "🕙" "🕥" "🕚" "🕦" )
# clock faces - top of the hour only
clockfaces_hours=( "🕛"  "🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚"  )

# moon faces. unicode order is northern-hemisphere style
moonfaces=( "🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘")


# cache some tput outputs 
columns=$(tput cols)
inverse=$(tput rev)
reset=$(tput sgr0)
backone=$(tput cub 1)
backtwo=$(tput cub 2)
backthree=$(tput cub 3)
downone=$(tput cud 1)
uptwo=$(tput cuu 2)
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
            do_delay
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
            do_delay
            echo -n "${backone}${leftblk[$cnt]}"
        done
        echo -n "$inverse"
        for cnt in $vals ; do
            do_delay
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
            do_delay
            echo -n "${backone}${lowblk[$cnt]}"
        done
        echo -n "$reset"
        for cnt in $vals ; do
            do_delay
            echo -n "${backone}${lowblk[$cnt]}"
        done
    done
}

### step through an array of single characters
# basically implements the various generic throb/spin/prop etc throbbers
# it has a few options to allow for variations in usage
# if $chars is set then it prints that many characters before restoring cursor
do_stepchar() {
    # $1 = "rev" to reverse direction. "rnd" to randomise order
    #       (default/any other string: forward) 
    # $2 = [0-9]* - a number to denote how many loops (default: 1)
        # both arguments are optional

    # defaults for values and loop count
    arraysize=${#spin[@]}
    # seq doesn't feel optimal, but I can't do {0..$variable} expansion in bash)
    vals=$(seq 0 $((arraysize-1))) # default: going clockwise
    case $1 in 
        rev) vals=$(seq $((arraysize-1)) -1 0) ;;
        rnd) vals=$(shuf -i 0-$((arraysize-1)) ) ;;
    esac
    loops=${2:-1} # default: loop once

    for loop in $(seq 1 $loops) ; do 
        for cnt in $vals ; do
            if [ $((count%chars)) -eq 0 ] ; then
                # if we've COUNTed a full loop of CHARS, then delay
                ( [ -n "$ALARM" ] || [ $count -gt 0 ] ) && do_delay
                echo -n "${rc}"
            elif [ $((count%(chars/lineshint))) -eq 0 ] ; then
                # if we've COUNTed a line-width, then go down and back
                # for another line in the block
                # TODO: change this method so it will work with WIDE unicode characters too (eg, dancers). 
                # (rc, then calculate how many lines down, yeah?
                # echo -n "${downone}$(tput cub $charstmp)"
#                echo -n "$rc$(tput cuu 1 )$count $chars $lineshint $rc"
                echo -n "$rc"
                tput cud $(( (count%chars)/(chars/lineshint) ))
            fi
            echo -n "${spin[$cnt]}"
            count=$((count+1))
        done
    done
}


# kitt/cylon scanner
do_kitt() {
    for keybulb in kitt{1..7}R kitt{6..0}L; do
        declare -n kittstate=$keybulb
        do_delay
        echo -n "$rc"
        for l in $kittstate ; do # l for lit-up state
            echo -n "${red[$l]}${brightness[$l]}${brightness[$l]}${brightness[$l]}"
        done
        echo -n "${el}" # clear the rest of the line
    done
}

# a tally/counting thing - Slowly grows across the line. 
do_tally() {
#    delay=0.05   # faster for debugging
    exithint=count
    charwidth=${#spin[0]}
    COLUMNS=$(tput cols)
    newlineat=$((COLUMNS-1))
    tallysize=${#spin[@]}
#    echo "DEBUG: charwidth: $charwidth, COLUMNS: $COLUMNS, newlineat: $newlineat, tallysize: $tallysize, gapevery: $gapevery"
    echo -n "$sc"
    while true ; do
        [ -n "$stopat" ] && [ $((tallycount/tallysize)) -ge $((stopat/tallysize)) ] && break
        do_stepchar 
        colsused=$((colsused+charwidth)) # keep track of characters used /line
        tallycount=$((tallycount+tallysize))
        charcount=$((charcount+1))
        if [ $((charcount%gapevery)) -eq 0 ] ; then
            if [ $((colsused+gapevery)) -ge $newlineat ] ; then
                echo "" 
                colsused=0
            else
                colsused=$((colsused+1))
#                echo -n "${colsused:0:1}"
                echo -n " "
            fi
        fi
        echo -n "$sc"
    done
    # this is a microcosm of the main do_stepchar loop to finish up 
    for finalise in $(seq 0 $((stopat-tallycount-1))) ; do
        do_delay
        echo -n "${rc}${spin[$finalise]}"
    done
    [ -n "$ALARM" ] || tstamp=$(sleepenh $tstamp $delay)
    echo ""
}


do_cm5() {
# based off the cm-5 "random and pleasing" LED panel mode (rev. 3)
# ...no, that's a lie. It's based off a gif off one of those. 
# ...and also some C, which starts like this
#   /* written by iskunk (Daniel Richard G.)
#      http://www.housedillon.com/?p=1272 (check the Wayback Machine)
#      emulates CM-5's 'random and pleasing' LED panel mode (rev. 3)
#      FILE IS IN THE PUBLIC DOMAIN */
# ...and which I didn't note where I found it online, and then ignored it's code anyway

# What this does is fill each line with random braille characters, and then
# alternating lines move left and right
#
# HOW:
# each line is stored as a line of characters, then an addition is added at the appropriate end, and redraw

    delay=0.075
    tput setaf 196  # a red
    LINES=$(tput lines)
    blockheight=${1:-1}  # how many lines to move together in a block
    totheight=$(( ((LINES-2)/blockheight)*blockheight ))
    topoffset=$(( (LINES-totheight)/2))

    COLUMNS=$(tput cols)
    width=$((COLUMNS/3))
    blankline=$(for c in $(seq 1 $width) ; do echo -n ' ' ; done)
    arraysize=$((${#braille[@]}))

    down1="$(tput cud 1)"
    backall="$(tput cub $COLUMNS)"
    fwdsome="$(tput cuf $(( (COLUMNS-width)/2 )))"
    moveit="${down1}${backall}${fwdsome}"

    # template block
    for linenum in $(seq 0 $((totheight-1)) ); do
       lineout[$linenum]="$blankline"
    done

    clear
    tput cup $topoffset $((width+1))
    tput sc
    tput setaf 160

    while true ; do
        echo -n "$rc"
        for linenum in $( seq 0 $((totheight-1)) ) ; do
            case $(( ($linenum/$blockheight)%2 )) in
                0)  ## even = move right
                    lineout[$linenum]="$(echo -n "${braille[$((RANDOM%arraysize))]}${lineout[$linenum]:0:$((width-1))}")"
                    echo -n "${lineout[$linenum]}${moveit}"
                    ;;
                1)  ## odd = move left
                    lineout[$linenum]="$(echo -n "${lineout[$linenum]:1:$((width))}${braille[$((RANDOM%arraysize))]}")" 
                    echo -n "${lineout[$linenum]}$moveit"
                    ;;
            esac
        done
        do_delay
    done
}


##################################################### main

# start the run by hiding the cursor and saving position
tput civis
echo -n "$sc"

# Check if the first arg is "ALARM" and treat it special
# ie: are we operating on our own clock, or on an external signal?
if [ "$1" == "ALARM" ] ; then
    ALARM=true
    shift
fi

# now choose our display mode - $1 in a case statement. 
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
    braille|cm-2) # Step through all braille dot patterns in unicode order # $2 = "rev" to reverse, "rnd" to randomise. Anything else = default order # $3 = "full" for a fullscreen mode # "cm-2" is a shortcut to "rnd full" and additionally turns it red
        declare -n spin=braille
        delay=0.333
        order=${2:-fwd}
        [ $1 == "cm-2" ] && order="rnd" # override $order for cm-2 mode
        if ( [ "$1" == "cm-2" ] || [ "$3" == "full" ] ) ; then
            # honestly, this is stretching the limit of what's sensible to do in a shell script, rather than ncurses, or libcaca, etc.
            # anyway... define a block we want to fill - lineshint x charstmp
            lineshint=$(( $(tput lines)/2 )) # multiple lines - half the terminal height
            charstmp=$(( lineshint*2 ))  # twice as many chars as lines is approx square
            # and check from the other direction to ensure adequate border
            if [ $charstmp -gt $(( $(tput cols)*3/5 )) ] ; then
                charstmp=$(( $(tput cols)*3/5 ))
                lineshint=$(( charstmp/2 ))
            fi
            [ "$1" != "cm-2" ] && lineshint=$((lineshint/3)) && charstmp=$((charstmp*2)) # change propostions if not cm-2. TODO: make this more comprehensive like the above is
            tput setab 16 # set a black background
            tput cup 0 0 # move to top of the screen
            tput ed # clear screen (I mean, "erase display" I guess?)
            # starting position is calculated to give a centered square
            tput cud $(( ($(tput lines)-lineshint)/2 )) # calculated start row
            tput cuf $(( ($(tput cols)/2)-$((charstmp/2)) )) # start column
            # colours. 178 seems yellow bulb colour (PDP-12). 196 for red LED (Connection Machine). 166 for amber terminal. 40 for green terminal 
            [ $1 == "cm-2" ] && colcode=196 || colcode=178 # default to 178, go 196 only for the connection machine mode
            tput setaf $colcode 
            chars=$((charstmp*lineshint)) # chars is per-line chars * lines
            positionhint="centered" # for the do_stepchar function
            exithint="fromfull" # hint to the ctrl_c function
            echo -n "$sc"   # save our spot and get going
        fi
        while true ; do
            do_stepchar $order
        done
        ;;
    cm-5) # a pretty CM-5 visualisation # $2 specifies how many lines to move together (default 1)
        exithint=fromfull
        linestogether=${2:-1}
        do_cm5 $linestogether
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
    kitt|cylon) # K.I.T.T/cylon scanner on black bg. Loops forever. 1 line by default. # $2 = "full" for fullscreen mode
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
        delay=0.112857 # reference video speed (31.6 L-R-L in 20 seconads)
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
    dancer) # dancing stick figure # $2 = how many dancers. This will center them. Limited to $columns/2-1
        delay=0.3333 # 3fps looks about right. 2 seconds for a full danceloop
        declare -n spin=dancer
        chars=${2:-1}     # how many dancers. default to 1
        if [ "$chars" -gt 1 ] ; then
            maxdancers=$(( $(tput cols)/2-1 ))
            [ "$chars" -gt $maxdancers ] && chars=$maxdancers
            tput cuf $(( ($(tput cols)/2)-$chars )) # center the output. each dancer is 2char wide so $((chars/2*2)) cancels out
            positionhint=centered
            order=rnd
            delay=0.2   # faster looks better when we're multiple+random
        fi
        echo -n "$sc"
        while true ; do
            do_stepchar $order
        done
        ;;
    tally|ideographic) # Tally marker counting. Slowly grows across the line in pairs. # 0.5s/stroke, 2.5s/tally block, 5s/pair-of-10 # $2 to set a count target then stop. # Without a target, it counts till ^c then reports how many it counted # Doesn't look right? Blame unicode consortium for lack of options. 
        declare -n spin=tally
        [ $1 == "ideographic" ] && declare -n spin=ideographic
        [ -n "$2" ] && stopat=$2
        delay=0.5 # 1 tally mark per 0.5 seconds
        gapevery=2  # 
        do_tally    # $delay, $stopat and $gapevery - as defined here, are used
        ;;
    dice) # Show dice faces 1 to 6 then back again. Repeat # $2="tally" for a pseudo duodecimal tally system # 3sec/dice, 6sec/dozen count # $2="roll" to stop after a few moments with a result. 
        declare -n spin=d6
        delay=0.5 # 1 dot per half second. 3 seconds per dice. 
        case $2 in
            roll)
                delay=0.08333 # 6 faces in 0.5 seconds
                do_stepchar rnd 3 # 3 loops of the array
                echo -e "\n$((cnt+1))" # echo the numeric result too
                ;;
            tally)
                delay=0.5 
                [ -n "$3" ] && stopat=$3
                gapevery=2
                do_tally
                ;;
            *)
                while true ; do
                    do_stepchar fwd 1
                    do_stepchar rev 1
                done
                ;;
        esac
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
        exithint="hours 2 2"    # hint, fps, frames per "hour" display
        declare -n spin=clockfaces_all
        delay=0.5 # one "hour" per second (2 frames/"hour")
        while true ; do
            do_stepchar
        done
        ;;
    clockfast) # A clock fritters and wastes the hours in an offhand way
        exithint="hours 12 1"
        declare -n spin=clockfaces_hours
        delay=0.083333 # 12fps = 12 hours displayed per second (1 frame/"hour")
        while true ; do
            do_stepchar
        done
        ;;
    moon) # Phases of the moon. # $2 = "north" for anticlockwise/northern hemisphere phase sequence
        # array is in unicode order, which is also n.hemisphere view.
        # Default here is to reverse the direction as I think that 
        # [a] looks better as a spinner (giving apparent left-to-right motion)
        # [b] and also matches my s.hemisphere familiarity of moon phases 
        #     https://www.abc.net.au/news/science/2018-01-24/beginners-guide-to-the-moon/9320770
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
Some provide exit statistics to stderr

By default there is a $delay second delay between frames.
Some toys set a different value. 

If \"ALARM\" is given as ARG1 then the delay is controlled by external SIGALRM 
    (ALARM mode does not alter anything else, including self-ending after
    a threshold is reached (eg: marquee, tally <num>, countdown) 
        example usage  : $0 ALARM tally 
        then seperately: killall -s ALRM $0

\$1 (required) indicates the type of throbber.
\$2 (optional) and any further params are throbber-specific

\$1 options are:"

#        egrep "^    [a-z0-9|-]*\).*# " $0 | sed -e 's/)//' | column -t -s'#'
        egrep "^    [a-z0-9|*-]*\) # " $0 | grep -v TODO | sed -e 's/^    /  /g ; s/)// ; s/# /\n   - /g'
        ;;
    *) # Unrecognised options triggers marquee output with a "--help"ful hint
        do_marquee "Run \"$0 --help\" for options"
        ;;
esac

tput cnorm

