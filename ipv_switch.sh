export LC_ALL=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    sudoCmd="sudo"
else
    sudoCmd=""
fi

uninstall() {
    ${sudoCmd} $(which rm) -rf $1
    printf "File or Folder Deleted: %s\n" $1
}


# fonts color
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}

Green_font_prefix="\033[32m" 
Red_font_prefix="\033[31m" 
Green_background_prefix="\033[42;37m" 
Red_background_prefix="\033[41;37m" 
Font_color_suffix="\033[0m"



osInfo=""
osRelease=""
osReleaseVersion=""
osReleaseVersionNo=""
osReleaseVersionCodeName="CodeName"
osSystemPackage=""
osSystemMdPath=""
osSystemShell="bash"

osKernelVersionFull=$(uname -r)
osKernelVersionBackup=$(uname -r | awk -F "-" '{print $1}')
osKernelVersionShort=$(uname -r | cut -d- -f1 | awk -F "." '{print $1"."$2}')
osKernelBBRStatus=""
systemBBRRunningStatus="no"
systemBBRRunningStatusText=""


function preferIPV4(){

    if [[ -f "/etc/gai.conf" ]]; then
        sed -i '/^precedence \:\:ffff\:0\:0/d' /etc/gai.conf
        sed -i '/^label 2002\:\:\/16/d' /etc/gai.conf
    fi

    # -z 为空
    if [[ -z $1 ]]; then
        
        echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

        echo
        green " VPS服务器已成功设置为 IPv4 优先访问网络"

    else

        green " ================================================== "
        yellow " 请为服务器设置 IPv4 还是 IPv6 优先访问: "
        echo
        green " 1 优先 IPv4 访问网络 (用于 给只有 IPv6 的 VPS主机添加 IPv4 网络支持，请保证你的服务器具备IPv4地址)"
        green " 2 优先 IPv6 访问网络 (用于 解锁 Netflix 限制 和避免弹出 Google reCAPTCHA 人机验证，请保证你的服务器具备IPv4地址)"
        green " 3 删除 IPv4 或 IPv6 优先访问的设置, 还原为系统默认配置"
        echo
        red " 注意: 选2后 优先使用 IPv6 访问网络 可能造成无法访问某些不支持IPv6的网站! "
        red " 注意: 解锁Netflix限制和避免弹出Google人机验证 一般不需要选择2设置IPv6优先访问, 可以在V2ray的配置中单独设置对Netfile和Google使用IPv6访问 "
        red " 注意: 由于 trojan 或 trojan-go 不支持配置 使用IPv6优先访问Netfile和Google, 可以选择2 开启服务器优先IPv6访问, 解决 trojan-go 解锁Netfile和Google人机验证问题"
        echo
        read -p "请选择 IPv4 还是 IPv6 优先访问? 直接回车默认选1, 请输入[1/2/3]:" isPreferIPv4Input
        isPreferIPv4Input=${isPreferIPv4Input:-1}

        if [[ ${isPreferIPv4Input} == [2] ]]; then

            # 设置 IPv6 优先
            echo "label 2002::/16   2" >> /etc/gai.conf

            echo
            green " VPS服务器已成功设置为 IPv6 优先访问网络 "
        elif [[ ${isPreferIPv4Input} == [3] ]]; then

            echo
            green " VPS服务器 已删除 IPv4 或 IPv6 优先访问的设置, 还原为系统默认配置 "  
        else
            # 设置 IPv4 优先
            echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
            
            echo
            green " VPS服务器已成功设置为 IPv4 优先访问网络 "    
        fi

        green " ================================================== "
        echo
        yellow " 验证 IPv4 或 IPv6 访问网络优先级测试, 命令: curl ip.p3terx.com " 
        echo  
        curl ip.p3terx.com
        echo
        green " 上面信息显示 如果是IPv4地址 则VPS服务器已设置为 IPv4优先访问. 如果是IPv6地址则已设置为 IPv6优先访问 "   
        green " ================================================== "

    fi
    echo

}

function installWarp(){
    echo "将使用missuo的CloudflareWarp脚本，脚本地址详见https://github.com/missuo/CloudflareWarp"
    bash <(wget -O warp.sh https://cdn.jsdelivr.net/gh/missuo/CloudflareWarp/warp.sh && bash warp.sh)
    # wget -O warp.sh https://cdn.jsdelivr.net/gh/missuo/CloudflareWarp/warp.sh && bash warp.sh
}

function updatekernel(){
    echo "如果你的内核没有升级至5.0以上，warp将安装失败，故建议先升级内核至5.0以上"
    echo "按1 选择安装BBR原本内核即可升级至最新内核"
    bash <(wget -O tcp.sh "https://git.io/coolspeeda" && chmod +x tcp.sh && ./tcp.sh)
}


function start_menu(){
    clear

    green " =================================================="
    green " 魔改自 jinwyp 大佬的 Linux 内核 一键安装脚本 | 系统支持：centos7+ / debian10+ / ubuntu16.04+"
    green " 原脚本详见 https://github.com/jinwyp/one_click_script"
    green " 本脚本旨在为你的vps服务器设置优先使用ipv4或ipv6访问网络 "
    red " *在任何生产环境中请谨慎使用此脚本, 升级内核有风险, 请做好备份！在某些VPS会导致无法启动! "
    green " =================================================="
    echo
    yellow " 检测本机 IPv4 或 IPv6 访问网络优先级测试, 命令: curl ip.p3terx.com " 
    echo  
    curl ip.p3terx.com
    echo
    green " 上面信息显示 如果是IPv4地址 则VPS服务器为 IPv4优先访问. 如果是IPv6地址则为 IPv6优先访问 "   
    echo " ************************************************ "

    echo
    echo
    green " 1. 升级内核至5.0以上"
    green " 2. 安装warp"
    green " 3. 设置 VPS服务器 IPv4 还是 IPv6 网络优先访问"
    echo
    green " =================================================="
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )updatekernel
        ;;
        
        2 )
           installWarp
        ;;
        
        3 )
           preferIPV4 "redo"
        ;;

        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字 !"
            sleep 2s
            start_menu
        ;;
    esac
}


start_menu "first"
