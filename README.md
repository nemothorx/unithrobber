# A variety of unicode throbbers / animations

This is a shell script, relying on sleepenh(1) for timing accuracy and
animation smoothness. 

I use characters from many places in unicode, local font support is out of my control. 

Smooth animation not guaranteed, especially over slow or laggy networks. 

## ALARM SIGNAL mode

If $1 is "ALARM" then it trades internal clock (and smoothness) for external control. 
eg: in one window run `throbber.sh ALARM tally`
and in a second on the same host, run
`for n in {1..42} ; do killall -s ALRM throbber.sh ; sleep $((RANDOM%3+0.5)) ; done ; killall throbber.sh`

All throbbers can be run in "ALARM" mode, however some conceptually suit better
(eg: tally) than others (eg: kitt)
