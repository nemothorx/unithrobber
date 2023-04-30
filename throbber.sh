#!/bin/bash


trap ctrl_c INT

function ctrl_c() {
    echo ""
    tput cnorm      # restore cursor
    exit 0
}


tstamp=$(sleepenh 0)

delay=0.04  # 0.1 = 10fps. 0.0625=16fps, 0.0416667 = 24fps, 0.02 = 50fps

# ▁   ▂   ▃   ▄   ▅   ▆   ▇   █   ▉   ▊   ▋   ▌   ▍   ▎   ▏

# characters for left/right/up/down slides
leftblk[1]="█"
leftblk[2]="▉"
leftblk[3]="▊"
leftblk[4]="▋"
leftblk[5]="▌"
leftblk[6]="▍"
leftblk[7]="▎"
leftblk[8]="▏"

lowblk[1]="█"
lowblk[2]="▇"
lowblk[3]="▆"
lowblk[4]="▅"
lowblk[5]="▄"
lowblk[6]="▃"
lowblk[7]="▂"
lowblk[8]="▁"

# characters for a spinner around a central spot (c for corners)
# cspin[1]="▏"   # LEFT ONE EIGHTH BLOCK
cspin[2]="🭛"   # UPPER LEFT BLOCK DIAGONAL LOWER LEFT TO UPPER CENTRE
cspin[3]="🭙"   # UPPER LEFT BLOCK DIAGONAL LOWER MIDDLE LEFT TO UPPER CENTRE
cspin[4]="🭗"   # UPPER LEFT BLOCK DIAGONAL UPPER MIDDLE LEFT TO UPPER CENTRE
#cspin[4]="🭚"   # UPPER LEFT BLOCK DIAGONAL LOWER MIDDLE LEFT TO UPPER RIGHT
cspin[5]="🭘"   # UPPER LEFT BLOCK DIAGONAL UPPER MIDDLE LEFT TO UPPER RIGHT
cspin[6]="▔"   # UPPER ONE EIGHTH BLOCK
cspin[7]="🭣"   # UPPER RIGHT BLOCK DIAGONAL UPPER LEFT TO UPPER MIDDLE RIGHT
cspin[8]="🭢"   # UPPER RIGHT BLOCK DIAGONAL UPPER CENTRE TO UPPER MIDDLE RIGHT
#cspin[8]="🭥"   # UPPER RIGHT BLOCK DIAGONAL UPPER LEFT TO LOWER MIDDLE RIGHT
cspin[9]="🭤"   # UPPER RIGHT BLOCK DIAGONAL UPPER CENTRE TO LOWER MIDDLE RIGHT
cspin[10]="🭦"   # UPPER RIGHT BLOCK DIAGONAL UPPER CENTRE TO LOWER RIGHT
cspin[11]="▕"   # RIGHT ONE EIGHTH BLOCK
cspin[12]="🭋"   # LOWER RIGHT BLOCK DIAGONAL LOWER CENTRE TO UPPER RIGHT
cspin[13]="🭉"   # LOWER RIGHT BLOCK DIAGONAL LOWER CENTRE TO UPPER MIDDLE RIGHT
cspin[14]="🭇"   # LOWER RIGHT BLOCK DIAGONAL LOWER CENTRE TO LOWER MIDDLE RIGHT
#cspin[14]="🭊"   # LOWER RIGHT BLOCK DIAGONAL LOWER LEFT TO UPPER MIDDLE RIGHT
cspin[15]="🭈"   # LOWER RIGHT BLOCK DIAGONAL LOWER LEFT TO LOWER MIDDLE RIGHT
cspin[16]="▁"   # LOWER ONE EIGHTH BLOCK
cspin[17]="🬽"   # LOWER LEFT BLOCK DIAGONAL LOWER MIDDLE LEFT TO LOWER RIGHT
cspin[18]="🬼"   # LOWER LEFT BLOCK DIAGONAL LOWER MIDDLE LEFT TO LOWER CENTRE
#cspin[18]="🬿"   # LOWER LEFT BLOCK DIAGONAL UPPER MIDDLE LEFT TO LOWER RIGHT
cspin[19]="🬾"   # LOWER LEFT BLOCK DIAGONAL UPPER MIDDLE LEFT TO LOWER CENTRE
cspin[20]="🭀"   # LOWER LEFT BLOCK DIAGONAL UPPER LEFT TO LOWER CENTRE
  
# braille spinner (3dot version)
# braille dot numbers are
# 14
# 25
# 36
# 78
bspin[1]="⠙"
bspin[2]="⠸"
bspin[3]="⢰"
bspin[4]="⣠"
bspin[5]="⣄"
bspin[6]="⡆"
bspin[7]="⠇"
bspin[8]="⠋"
# braille race (spinner with two opposing dots)
brace[1]="⢁"
brace[2]="⡈"
brace[3]="⠔"
brace[4]="⠢"
# braille2 race (spinner with two opposing pair of dots)
b2race[1]="⣉"
b2race[2]="⡜"
b2race[3]="⠶"
b2race[4]="⢣"

# ascii prop
aprop[1]="\\"
aprop[2]="|"
aprop[3]="/"
aprop[4]="-"
# unicode prop
uprop[1]="╲"
uprop[2]="│"
uprop[3]="╱"
uprop[4]="─"

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
sc=$(tput sc)
rc=$(tput rc)

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
        for cnt in {8..1} ; do
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
    vals=$(echo {8..1}) # default: going right
    [ "$1" == "left" ] && vals=$(echo {1..8})
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
    vals=$(echo {1..8}) # default: going down
    [ "$1" == "up" ] && vals=$(echo {8..1})
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

### spinner - rotation around a center
do_spin() {
    # defaults for values and loop count
    arraysize=${#spin[@]}
        # seq is not optimal, but readable (can't put $arraysize in {1..x} expansion in bash)
    vals=$(seq 1 $arraysize) # default: going clockwise
    [ "$1" == "anticw" ] && vals=$(seq $arraysize -1 1)
    loops=${2:-1} # default: loop once

    loops=${2:-1}
    for loops in {1..$loops} ; do 
        for cnt in $vals ; do
            [ $arraysize -lt 10 ] && tstamp=$(sleepenh $tstamp $delay) # slowdown only for low frame count qix (brailleqix)
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${backone}${spin[$cnt]}"
        done
    done
}

### prop - a propeller spinning
do_prop() {
    # defaults for values and loop count
    vals=$(echo {1..4}) # default: going clockwise
    [ "$1" == "anticw" ] && vals=$(echo {4..1})
    loops=${2:-1} # default: loop once
    
    loops=${2:-1}
    for loops in {1..$loops} ; do 
        # array sets "-" at the end.
        # extra delay here so remains on screen longer to balance it's smaller size
        tstamp=$(sleepenh $tstamp $delay) 
        for cnt in $vals ; do
            # prop is slowed from the default because it has so few frames
            tstamp=$(sleepenh $tstamp $delay) 
            tstamp=$(sleepenh $tstamp $delay) 
            echo -n "${backone}${prop[$cnt]}"
        done
    done
}

##################################################### main

case $1 in
    cross) # Block slides smoothly across, then smoothly down. Forever
        # across and down in a single character space, forever
        while true ; do
            do_blk_lr right 1
            do_blk_ud down 1
        done
        ;;
    marquee) # Block slides smoothly across an entire line then stops. If $2/etc then it becomes a plane banner with those arg as text
        shift
        do_marquee "$*"
        ;;
    spin) # Rotate forever aound an empty middle. 1 space
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
    braillesnake) # (TODO) A "snake" game in a 2x3 braille grid (1 space)
        # Start with it as a 1dot snake, it finds and eats a prize, becomes 2dot, etc, till 3x2 is full
        # note: have to plan the whole game
        true
        ;;
    kitt) # (TODO) K.I.T.T scanner. Loops forever
        true
        ;;
    dot) # (TODO) A growing and shrinking solid dot (1space)
        true
        ;;
    tunnel) # (TODO) like dot, but zooms into it, looping. (1space)
        true
        ;;
    asciiprop|prop) # Traditional ascii "propellor" spinner using -\|/
        declare -n prop=aprop
        while true ; do
            do_prop cw 1
        done
        ;;
    uniprop) # Unicode version of the ascii propellor
        declare -n prop=uprop
        while true ; do
            do_prop cw 1
        done
        ;;
    --help) # This help. You're reading it. 
        echo "
A variety of unicode toys - mainly \"throbbers\" which animate within
a very small space. Looping throbbbers end cleanly with ^c

\$1 indicates the type of throbber. Any further params are throbber-specific. 

\$1 options are:"

        egrep "^    [a-z0-9|-]*\).*# " $0 | sed -e 's/)//' | column -t -s'#'
        tput cnorm
        exit 0
        ;;
    *) # Unrecognised or unspecified options trigger the marquee with a message hinting to try --help
        # marquee with help message info
        do_marquee "Run \"$0 --help\" for options"
        ;;
esac

tput cnorm

