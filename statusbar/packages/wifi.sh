#!/bin/bash

tempfile=$(cd $(dirname $0);cd ..;pwd)/temp
networkspeed=$(cd $(dirname $0);cd ..;pwd)/networkspeed

this=_wifi
icon_color="^c#000080^^b#3870560x88^"
text_color="^c#000080^^b#3870560x99^"
signal=$(echo "^s$this^" | sed 's/_//')

# Check if nmcli is available
[ ! "$(command -v nmcli)" ] && echo "command not found: nmcli" && exit 1

# 中英文适配
wifi_grep_keyword="已连接 到"
wifi_disconnected="未连接"
wifi_disconnected_notify="未连接到网络"
if [ "$LANG" != "zh_CN.UTF-8" ]; then
    wifi_grep_keyword="connected to"
    wifi_disconnected="disconnected"
    wifi_disconnected_notify="disconnected"
fi

# 获取 WiFi 信号强度
get_wifi_signal() {
    local signal_strength=$(nmcli dev wifi | grep '*' | awk '{print $8}')
    echo $signal_strength
}

# 根据信号强度选择图标
get_wifi_icon() {
    local signal_strength=$1
    if [ "$signal_strength" -ge 80 ]; then
        echo ""  # 强信号
    elif [ "$signal_strength" -ge 50 ]; then
        echo ""  # 中等信号
    else
        echo ""  # 弱信号
    fi
}

# 获取网速
# get_network_speed() {
#     # 获取当前活动的 WiFi 接口
#     interface=$(nmcli -t -f DEVICE,TYPE,STATE dev status | awk -F: '$2 == "wifi" && $3 == "connected" {print $1}')

#     # 检查接口是否存在
#     if [ ! -d "/sys/class/net/$interface" ]; then
#         echo "Interface $interface does not exist."
#         return 1
#     fi

#     # 获取当前的接收和发送字节数
#     rx_bytes_prev=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null)
#     tx_bytes_prev=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null)

#     # 等待1秒
#     sleep 1 &
#     wait $!

#     # 获取1秒后的接收和发送字节数
#     rx_bytes_curr=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null)
#     tx_bytes_curr=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null)

#     # 计算网速
#     rx_speed=$(( (rx_bytes_curr - rx_bytes_prev) / 1024 ))
#     tx_speed=$(( (tx_bytes_curr - tx_bytes_prev) / 1024 ))

#     # 输出网速
#     echo "↓${rx_speed}KB/s ↑${tx_speed}KB/s"
# }

# # 后台进程计算网速
# calculate_network_speed() {
#     while true; do
#         network_speed=$(get_network_speed)
#         echo "$network_speed" > $networkspeed
#         sleep 1
#     done
# }

update() {
    wifi_text=$(nmcli | grep "$wifi_grep_keyword" | awk -F "$wifi_grep_keyword" '{print $2}')
    [ "$wifi_text" = "" ] && wifi_text=$wifi_disconnected

    if [ "$wifi_text" != "$wifi_disconnected" ]; then
        signal_strength=$(get_wifi_signal)
        wifi_icon=$(get_wifi_icon $signal_strength)
        network_speed=$(cat $networkspeed)
    else
        wifi_icon="睊"  # 未连接时的图标
        network_speed="N/A"
    fi

    icon=" $wifi_icon "
    text="$network_speed "

    sed -i '/^export '$this'=.*$/d' $tempfile
    printf "export %s='%s%s%s%s%s'\n" $this "$signal" "$icon_color" "$icon" "$text_color" " " >> $tempfile
}

notify() {
    update
    notify-send -r 9527 "$wifi_icon Wifi" "\n$wifi_text"
}

call_nm() {
    pid1=$(ps aux | grep 'st -t statusutil' | grep -v grep | awk '{print $2}')
    pid2=$(ps aux | grep 'st -t statusutil_nm' | grep -v grep | awk '{print $2}')
    mx=$(xdotool getmouselocation --shell | grep X= | sed 's/X=//')
    my=$(xdotool getmouselocation --shell | grep Y= | sed 's/Y=//')
    kill $pid1 && kill $pid2 || st -t statusutil_nm -g 60x25+$((mx - 240))+$((my + 20)) -c FGN -C "#222D31@4" -e 'nmtui-connect'
}

click() {
    case "$1" in
        L) notify ;;
        R) call_nm ;;
    esac
}

case "$1" in
    click) click $2 ;;
    notify) notify ;;
    *) 
        # 启动后台进程计算网速
        # calculate_network_speed &
        update ;;
esac