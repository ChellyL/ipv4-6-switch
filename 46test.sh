if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    sudoCmd="sudo"
else
    sudoCmd=""
fi

# fonts color
red(){
    echo -e "\033[31m$1\033[0m"
}
green(){
    echo -e "\033[32m$1\033[0m"
}
yellow(){
    echo -e "\033[33m$1\033[0m"
}
blue(){
    echo -e "\033[36m$1\033[0m"
}

echo
yellow " 本机 IPv4 地址："
curl ipv4.ip.sb
echo
yellow " 本机 IPv6 地址："
curl ipv6.ip.sb
echo
yellow " 检测本机 IPv4 或 IPv6 访问网络优先级："
yellow " 如显示IPv4地址，则为 IPv4优先访问；如为IPv6地址，则为 IPv6优先访问"
curl ip.p3terx.com
echo
