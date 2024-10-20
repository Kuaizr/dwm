#!/bin/bash

tempfile=$(cd $(dirname $0);cd ..;pwd)/temp

this=_bluetooth
icon_color="^c#000080^^b#3870560x88^"
text_color="^c#000080^^b#3870560x99^"
signal=$(echo "^s$this^" | sed 's/_//')

# check
[ ! "$(command -v bluetoothctl)" ] && echo command not found: bluetoothctl && exit

# 中英文适配
bt_connected="已连接"
bt_disconnected="未连接"
bt_disconnected_notify="未连接到蓝牙设备"
if [ "$LANG" != "zh_CN.UTF-8" ]; then
    bt_connected="connected"
    bt_disconnected="disconnected"
    bt_disconnected_notify="disconnected"
fi

# 获取蓝牙设备电量
get_battery_level() {
    local device_mac=$1
    local battery_level=$(bluetoothctl info $device_mac | grep "Battery Percentage" | awk '{print $3}' | tr -d '()%')
    
    # 检查是否带有 0x 前缀
    if [[ $battery_level == 0x* ]]; then
        # 将十六进制转换为十进制
        battery_level=$((16#${battery_level#0x}))
    fi

    echo $battery_level
}


update() {
    bt_icon=""
    bt_status=$(bluetoothctl info | grep "Connected: yes" | wc -l)
    if [ "$bt_status" -eq 1 ]; then
        # 获取已连接设备的 MAC 地址
        device_mac=$(bluetoothctl info | grep "Device" | awk '{print $2}')
        # 获取设备电量
        battery_level=$(get_battery_level $device_mac)
        if [ -z "$battery_level" ]; then
            bt_text=""
        else
            bt_text=" $battery_level%"
        fi
    else
        bt_text=""  # 使用一个特殊的蓝牙图标表示未连接
    fi

    icon=" $bt_icon "
    text="$bt_text "

    sed -i '/^export '$this'=.*$/d' $tempfile
    printf "export %s='%s%s%s%s%s'\n" $this "$signal" "$icon_color" "$icon" "$text_color" "$text" >> $tempfile
}

notify() {
    update
    notify-send -r 9527 "$bt_icon Bluetooth" "\n$bt_text"
}

call_bt() {
    pid1=`ps aux | grep 'st -t statusutil' | grep -v grep | awk '{print $2}'`
    pid2=`ps aux | grep 'st -t statusutil_bluetooth' | grep -v grep | awk '{print $2}'`
    mx=`xdotool getmouselocation --shell | grep X= | sed 's/X=//'`
    my=`xdotool getmouselocation --shell | grep Y= | sed 's/Y=//'`
    kill $pid1 && kill $pid2 || st -t statusutil_bluetooth -g 60x25+$((mx - 240))+$((my + 20)) -c FGN -C "#222D31@4" -e 'bluetuith'
}

click() {
    case "$1" in
        L) notify ;;
        R) call_bt ;;
    esac
}

case "$1" in
    click) click $2 ;;
    notify) notify ;;
    *) update ;;
esac