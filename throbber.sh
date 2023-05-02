#!/bin/bash


trap ctrl_c INT

function ctrl_c() {
    echo ""
    tput cnorm      # restore cursor
    exit 0
}


tstamp=$(sleepenh 0)

delay=0.04  # 0.1 = 10fps. 0.0625=16fps, 0.0416667 = 24fps, 0.02 = 50fps

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

# ascii prop
declare -a aprop=( "\\" "|" "/" "-" )
# unicode prop
declare -a uprop=( "╲" "│" "╱" "─" )

# scanner effect arrays
declare -a hscan=( "▏" "🭰" "🭱" "🭲" "🭳" "🭴" "🭵" "▕" )
declare -a vscan=( "▔" "🭶" "🭷" "🭸" "🭹" "🭺" "🭻" "▁" )

# dancer
declare -a dancer=( "🯅 " "🯆 " "🯅 " "🯇 " "🯅 " "🯈 " )

# segmented display
declare -a segmented=( "🯰 " "🯱 " "🯲 " "🯳 " "🯴 " "🯵 " "🯶 " "🯷 " "🯸 " "🯹 " )

# tally marks
declare -a tally=( "𝍩 " "𝍪 " "𝍫 " "𝍬 " "𝍸 " )


# kitt colours (reds) and brightnesses (brightest to dimmest and black)
declare -a red=( "$(tput setaf 196)" "$(tput setaf 01)" "$(tput setaf 88)" "$(tput setaf 52)" "$(tput setaf 0)" )
declare -a brightness=( "█" "▓" "▒" "░" " " )
# kitt/cylon illumination matrix ("0" is the "lit bulb" with short leading light leakage, and long fading tail
kitt1R="1 0 3 4 4 4 4 4" # travelling right
kitt2R="2 1 0 3 4 4 4 4"
kitt3R="3 2 1 0 3 4 4 4"
kitt4R="4 3 2 1 0 3 4 4"
kitt5R="4 4 3 2 1 0 3 4"
kitt6R="4 4 4 3 2 1 0 3"
kitt7R="4 4 4 4 3 2 1 0" # rightmost bulb
kitt6L="4 4 4 4 4 3 0 1" # travelling left
kitt5L="4 4 4 4 3 0 1 2"
kitt4L="4 4 4 3 0 1 2 3"
kitt3L="4 4 3 0 1 2 3 4"
kitt2L="4 3 0 1 2 3 4 4"
kitt1L="3 0 1 2 3 4 4 4"
kitt0L="0 1 2 3 4 4 4 4" # leftmost bulb

#dot/circle like characters
# ◌
# ⊙ 
# ⨀ 
# ・
# ꞏ
# ･
# Ꜿ
# ꜿ
# 𐄁
# ○
# ◯ 
# ⭘
# ⭗
# ￮
# 🞅       1F785   MEDIUM BOLD WHITE CIRCLE
# 🞆       1F786   BOLD WHITE CIRCLE
# 🞇       1F787   HEAVY WHITE CIRCLE
# 🞈       1F788   VERY HEAVY WHITE CIRCLE
# 🞉       1F789   EXTREMELY HEAVY WHITE CIRCLE
# 🞊       1F78A   WHITE CIRCLE CONTAINING BLACK SMALL CIRCLE
#

columns=$(tput cols)
inverse=$(tput rev)
reset=$(tput sgr0)
backone=$(tput cub 1)
backtwo=$(tput cub 2)
backthree=$(tput cub 3)
sc=$(tput sc)
rc=$(tput rc)
el=$(tput el)

tput civis      # hide cursor

echo -n "$sc"


### marquee

do_marquee() {
    message="$@"
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

### loop character array - simply step through an array of single characters
# basically implements the various "spin", "prop" etc throbbers
### spinner - rotation around a center
do_spin() {
    # TODO: consider setting delay as a param? 
    # ...or maybe only ever have it once here, and set it manually prior to calling do_spin when it needs to be something else

    # defaults for values and loop count
    arraysize=${#spin[@]}
    # seq is not optimal, but readable (can't do {0..$arraysize} expansion in bash)
    vals=$(seq 0 $((arraysize-1))) # default: going clockwise
    [ "$1" == "anticw" ] && vals=$(seq $((arraysize-1)) -1 0)
    loops=${2:-1} # default: loop once

    for loop in $(seq 1 $loops) ; do 
        for cnt in $vals ; do
            [ $arraysize -le 12 ] && tstamp=$(sleepenh $tstamp $delay) # slower on low frame count arrays
            [ $arraysize -le 6 ] && tstamp=$(sleepenh $tstamp $delay) # even slower
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${rc}${spin[$cnt]}"
        done
    done
}


# kitt/cylon scanner
do_kitt() {
    # TODO: test on a white-bg terminal. May be worth forcing black bg
    for keybulb in kitt{1..7}R kitt{6..0}L; do
        declare -n kittstate=$keybulb
        # kitt looks best at about this speed (where delay=0.04)
        tstamp=$(sleepenh $tstamp $delay) 
        tstamp=$(sleepenh $tstamp $delay) 
        tstamp=$(sleepenh $tstamp $delay) 
        echo -n "$rc"
        for l in $kittstate ; do # l for lit-up state? 
            echo -n "${red[$l]}${brightness[$l]}${brightness[$l]}${brightness[$l]}"
        done
        echo -n "${el}"
    done
}

##################################################### main
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
    marquee) # Block slides smoothly across an entire line then stops. # If $2/etc then it becomes a plane banner with those args as banner text
        shift
        do_marquee "$*"
        ;;
    borderspin) # Parts of the border rotates forever aound an empty middle. 1 space
        declare -n spin=cspin
        while true ; do
            do_spin 
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
    braillespin) # Three rots rotate around an empty middle. 1 char
        declare -n spin=bspin
        while true ; do
            do_spin
        done
        ;;
    braillerace) # Two dots circling each other (1space)
        declare -n spin=brace
        while true ; do
            do_spin
        done
        ;;
    braille2race) # Two sets of two dots circling each other (1space)
        declare -n spin=b2race
        while true ; do
            do_spin
        done
        ;;
    braillesnake) # (TODO) A "snake" game in a 2x4 braille grid (1 space)
        # Start with it as a 1dot snake, it finds and eats a prize, becomes 2dot, etc, till 2x4 is full
        # note: have to plan the whole game?
        true
        ;;
    gravityspin) # (TODO) Microsoft style: speeds up going down, slows at top
        # implement with a custom character array of braille and do_spin?
        true
        ;;
    kitt|cylon) # K.I.T.T/cylon scanner. Loops forever. 1 line by default. # Optional fullscreen $2 arg: full
        # original for reference: https://www.youtube.com/watch?v=usui7ECHPNQ (5m20)
        #   * 8 elements
        #   * brightens over ~3 frames
        #   * dims over ~12 frames (previous 4 elements
        #   * tiny light leakage into next?

        # if we get a "full" param, we clear the screen and kitt at 3/4 the way down
        [ "$2" == "full" ] && clear && tput cud $(($(tput lines)*3/4))
        # the scanner is 8 lights, each is 3charwide, so 24wide total
        # this cuf centers it
        tput cuf $(( ($(tput cols)/2)-12 )) 
        echo -n "${sc}"
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
    asciiprop|prop) # Traditional ascii "propellor" spinner using -\|/
        declare -n spin=aprop
        while true ; do
            do_spin 
            tstamp=$(sleepenh $tstamp $delay) 
        done
        ;;
    uniprop) # Unicode version of the ascii propellor
        declare -n spin=uprop
        while true ; do
            do_spin
            tstamp=$(sleepenh $tstamp $delay) 
        done
        ;;
    scanner) # single character scanner
        while true ; do
            declare -n spin=hscan
            do_spin cw 1
            do_spin anticw 1
            declare -n spin=vscan
            do_spin cw 1
            do_spin anticw 1
        done
        ;;
    dancer) # dancing stick figure
        declare -n spin=dancer
        echo -n "$sc"
        while true ; do
            do_spin 
        done
        ;;
    tally) # Tally marker counting. Slowly grows across the line. # 0.5s/tally, 2.5s/ block - or 100seconds/80char term width
        declare -n spin=tally
        echo -n "$sc"
        delay=0.16666 # do_spin will triply this timing, so each mark is 0.5 seconds
        while true ; do
            do_spin 1
            echo -n "$sc"
        done
        ;;
    countdown) # countdown from 9 to 0 (then exit - no looping)
        declare -n spin=segmented
        echo -n "$sc"
        delay=0.5 # array of 10 means do_spin will double-delay
        do_spin anticw 1
        ;;
    --help) # This help. You're reading it. 
        echo "
A variety of unicode \"throbber\" style toys
ie, background-activity-indicators which animate within a small space. 

Most loop forever and can be ended cleanly with ^c

\$1 indicates the type of throbber. Any further params are throbber-specific. 

\$1 options are:"

#        egrep "^    [a-z0-9|-]*\).*# " $0 | sed -e 's/)//' | column -t -s'#'
        egrep "^    [a-z0-9|-]*\).*# " $0 | grep -v TODO | sed -e 's/^    /  /g ; s/)// ; s/#/\n        /g'
        tput cnorm
        exit 0
        ;;
    *) # Unrecognised or unspecified options trigger the marquee with a message hinting to try --help
        # marquee with help message info
        do_marquee "Run \"$0 --help\" for options"
        ;;
esac

tput cnorm

