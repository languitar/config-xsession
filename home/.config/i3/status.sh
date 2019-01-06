#!/bin/bash

BATC=/sys/class/power_supply/BAT0/capacity
BATS=/sys/class/power_supply/BAT0/status

inner_sep=4

partitions=${partitions:-"/ /tmp ${HOME}"}

volume() {
    amixer get Master | sed -n 's/^.*\[\([0-9]\+\).*$/\1/p' | head -n 1
}

cpu() {
    wait=4
    # top -b -n${wait} | grep "Cpu(s)" | tail -n 1 | awk '{printf("%i%", ($2 + $4))}'
    { cat /proc/stat; sleep "$wait"; cat /proc/stat; } | awk '/^cpu / {usr=$2-usr; nice=$3-nice; sys=$4-sys; idle=$5-idle; iow=$6-iow} /^cpu[0-9]+ / {count++} \
    END {total=usr+nice+sys+idle+iow; printf "%.0f\n", (total-idle)*100*count/2/total}'
}

cpuload() {
    cut -d ' ' -f 1-3 < /proc/loadavg
}

partition_usage() {
    df -h "$1" | tail -n 1 | tr -s ' ' | cut -d ' ' -f 5 | cut -d '%' -f 1
}

memused() {
    # different free versions have different outputs
    if free | grep 'buffers/cache' > /dev/null
    then
        free | head -n 3 | tail -n 2 | tr -s ' ' | tr -s '\n' ' ' | awk 'FNR == 1 {printf("%d", 100*$10/$2)}'
    else
        free | grep Mem | awk 'FNR == 1 {printf("%d", 100*$3/$2)}'
    fi
}

swapused() {
    free | grep 'Swap:' | awk 'FNR == 1 {if ($2 > 0) { printf("%i", ($3/$2)*100) } else {print "N/A"}}'
}

keyboard_layout() {
    setxkbmap -query | grep layout | tr -s ' ' | cut -d ' ' -f 2
}

nowplaying() {
    cur=`mpc current`
    # this line allow to choose whether the output will scroll or not
    test "$1" = "scroll" && PARSER='skroll -n20 -d0.5 -r' || PARSER='cat'
    test -n "$cur" && $PARSER <<< $cur || echo "- stopped -"
}

# printing blocks

block_task() {
    buf="${buf} {\"name\": \"task_icon\", \"full_text\": \"\", \"separator\": false},"
    _task_overdue=$(task +OVERDUE count)
    if [ "${_task_overdue}" -gt "0" ]; then
        _task_overdue_urgent=", \"urgent\": true"
    else
        _task_overdue_urgent=""
    fi
    buf="${buf} {\"name\": \"task_overdue\", \"full_text\": \"${_task_overdue}\", \"separator\": false, \"separator_block_width\": ${inner_sep} ${_task_overdue_urgent}},"
    _task_pending=$(task status:pending -OVERDUE count)
    buf="${buf} {\"name\": \"task_pending\", \"full_text\": \"${_task_pending}\", \"separator\": false, \"separator_block_width\": ${inner_sep}},"
    _task_active=$(task +ACTIVE count)
    buf="${buf} {\"name\": \"task_active\", \"full_text\": \"${_task_active} \"},"
}

block_cpu() {
    _cpu=$(cpu)
    if [ "${_cpu}" -gt "600" ]; then
        _cpu_urgent=", \"urgent\": true"
    else
        _cpu_urgent=""
    fi
    buf="${buf} {\"name\": \"cpu_icon\", \"full_text\": \" \", \"separator\": false, \"separator_block_width\": 0${_cpu_urgent}},"
    buf="${buf} {\"name\": \"cpu\", \"full_text\": \"${_cpu}%\", \"min_width\": \"800%\", \"align\": \"right\"${_cpu_urgent}},"
}

block_load() {
    load=$(cpuload)
    buf="${buf} {\"name\": \"load_icon\", \"full_text\": \" \", \"separator\": false, \"separator_block_width\": 0},"
    buf="${buf} {\"name\": \"load\", \"full_text\": \"${load}\", \"short_text\": \"$(echo "${load}" | awk '{printf "%.1f %.1f %.1f\n", $1, $2, $3}')\"},"
}

block_memory() {
    _memory=$(memused)
    if [ "${_memory}" -gt "80" ]; then
        _memory_urgent=", \"urgent\": true"
    else
        _memory_urgent=""
    fi
    buf="${buf} {\"name\": \"memory_icon\", \"full_text\": \" \", \"separator\": false, \"separator_block_width\": 0${_memory_urgent}},"
    buf="${buf} {\"name\": \"memory\", \"full_text\": \"${_memory}%\", \"min_width\": \"100%\", \"align\": \"right\"${_memory_urgent}},"
}

block_swap() {
    _swap=$(swapused)
    if [ "${_swap}" == "N/A" ] || [ "$(echo "${_swap}" | sed 's/%//')" -gt "80" ]; then
        _swap_urgent=", \"color\": \"${urgent_urgent}\""
    else
        _swap_urgent=""
    fi
    buf="${buf} {\"name\": \"swap_icon\", \"full_text\": \" \", \"separator\": false, \"separator_block_width\": 0${_swap_urgent}},"
    buf="${buf} {\"name\": \"swap\", \"full_text\": \"${_swap}%\", \"min_width\": \"100%\", \"align\": \"right\"${_swap_urgent}},"
}

block_partitions() {
    buf="${buf} {\"name\": \"disk_icon\", \"full_text\": \"\", \"separator\": false},"
    last=$(echo "${partitions}" | awk '{ print $NF }')
    for partition in $partitions
    do
        _part=$(partition_usage "${partition}")
        if [ "${_part}" -gt "85" ]
        then
            _part_urgent=", \"urgent\": true"
        else
            _part_urgent=""
        fi
        if [ "${partition}" == "${last}" ]
        then
            _part_sep=", \"separator\": true"
        else
            _part_sep=", \"separator\": false, \"separator_block_width\": ${inner_sep}"
        fi
        # \"full_text\": \"$(printf "%s %04s" ${partition} ${_part})\"
        buf="${buf} {\"name\": \"disk_icon\", \"instance\": \"${partition}\", \"full_text\": \"$(echo "${partition}" | sed 's#\(/.\)[a-zA-Z_]*#\1#g') \", \"separator\": false, \"separator_block_width\": 0${_part_urgent}},"
        buf="${buf} {\"name\": \"disk\", \"instance\": \"${partition}\", \"full_text\": \"${_part}%\", \"min_width\": \"100%\", \"align\": \"right\"${_part_sep}${_part_urgent}},"
    done
}

block_volume() {
    buf="${buf} {\"name\": \"volume_icon\", \"full_text\": \" \", \"separator\": false,\"separator_block_width\": 0},"
    buf="${buf} {\"name\": \"volume\", \"full_text\": \"$(volume)%\", \"min_width\": \"100%\", \"align\": \"right\"},"
}

block_battery() {
    symbol=$(case "$(cat ${BATS})" in
        ("Full") echo "" ;;
        ("Charging") echo "" ;;
        ("Discharging") echo "" ;;
        (*) echo "" ;;
    esac)

    charge=$(cat "$BATC")
    if [ "${charge}" -lt "15" ]; then
        _part_urgent=", \"urgent\": true"
    else
        _part_urgent=""
    fi
    buf="${buf} {\"name\": \"battery_icon\", \"full_text\": \"${symbol} \", \"separator\": false,\"separator_block_width\": 0, \"max_width\": \" \"${_part_urgent}},"
    buf="${buf} {\"name\": \"battery\", \"full_text\": \"${charge}%\", \"min_width\": \"100%\", \"align\": \"right\"${_part_urgent}},"
}

block_keyboard() {
    buf="${buf} {\"name\": \"keyboard_icon\", \"full_text\": \" \", \"separator\": false,\"separator_block_width\": 0},"
    buf="${buf} {\"name\": \"keyboard\", \"full_text\": \"$(keyboard_layout)\"},"
}

block_clock() {
    buf="${buf} {\"name\": \"clock_icon\", \"full_text\": \"⌚ \", \"separator\": false,\"separator_block_width\": 0},"
    buf="${buf} {\"name\": \"clock\", \"full_text\": \"$(date '+%Y-%m-%d %H:%M')\", \"short_text\": \"$(date '+%H:%M')\"}"
}

if [ -f ~/.config/i3/status_local.sh ]
then
    source ~/.config/i3/status_local.sh
fi

echo '{ "version": 1 }'
echo '['
echo '[]'

# This loop will fill a buffer with our infos, and output it to stdout.
while :;
do
    buf=",["

    block_task
    block_cpu
    block_load
    block_memory
    block_swap
    block_partitions
    block_volume
    if [ -f "$BATS" ]
    then
        block_battery
    fi
    block_keyboard
    block_clock

    buf="${buf} ]"

    echo "$buf"

    if grep -q Discharging "${BATS}"
    then
        sleep 15
    fi

done
