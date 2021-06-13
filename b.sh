export LC_ALL=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    sudoCmd="sudo"
else
    sudoCmd=""
fi


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

# 检测系统版本号
getLinuxOSVersion(){
    if [[ -s /etc/redhat-release ]]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/issue)
    fi

    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        osInfo=$NAME
        osReleaseVersionNo=$VERSION_ID

        if [ -n $VERSION_CODENAME ]; then
            osReleaseVersionCodeName=$VERSION_CODENAME
        fi
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        osInfo=$(lsb_release -si)
        osReleaseVersionNo=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        osInfo=$DISTRIB_ID
        
        osReleaseVersionNo=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        osInfo=Debian
        osReleaseVersion=$(cat /etc/debian_version)
        osReleaseVersionNo=$(sed 's/\..*//' /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        osInfo=$(uname -s)
        osReleaseVersionNo=$(uname -r)
    fi
}


# 检测系统发行版代号
function getLinuxOSRelease(){
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /etc/issue | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /proc/version | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    fi

    getLinuxOSVersion
    virt_check

    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    echo "OS info: ${osInfo}, ${osRelease}, ${osReleaseVersion}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osSystemShell}, ${osSystemPackage}, ${osSystemMdPath}"
}


virt_check(){
	# if hash ifconfig 2>/dev/null; then
		# eth=$(ifconfig)
	# fi

	virtualx=$(dmesg) 2>/dev/null

    if  [ $(which dmidecode) ]; then
		sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
		sys_product=$(dmidecode -s system-product-name) 2>/dev/null
		sys_ver=$(dmidecode -s system-version) 2>/dev/null
	else
		sys_manu=""
		sys_product=""
		sys_ver=""
	fi
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *QEMU* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated母鸡"
	fi
}





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
    red "将使用missuo的CloudflareWarp脚本，脚本地址详见https://github.com/missuo/CloudflareWarp"
    echo
    echo "*************************"
    echo
    wget -N --no-check-certificate "https://raw.githubusercontent.com/missuo/CloudflareWarp/main/warp.sh" && chmod +x warp.sh && ./warp.sh
}

function updatekernel(){
    echo "如果你的内核没有升级至5.0以上，warp将安装失败，故建议先升级内核至5.0以上"
    echo "按1 选择安装BBR原本内核即可升级至最新内核"
	echo
    echo "*************************"
    wget -O tcpx.sh "https://git.io/JYxKU" && chmod +x tcpx.sh && ./tcpx.sh
}


function start_menu(){
    clear
    
    if [[ $1 == "first" ]] ; then
        getLinuxOSRelease
        installSoftDownload
    fi
    showLinuxKernelInfoNoDisplay


    green " =================================================="
    green " 魔改自 jinwyp 大佬的 Linux 内核 一键安装脚本 | 系统支持：centos7+ / debian10+ / ubuntu16.04+"
    green " 原脚本详见 https://github.com/jinwyp/one_click_script"
    green " 本脚本旨在为你的vps服务器设置优先使用ipv4或ipv6访问网络 "
    red " *在任何生产环境中请谨慎使用此脚本, 升级内核有风险, 请做好备份！在某些VPS会导致无法启动! "
    green " =================================================="
     if [[ -z ${osKernelBBRStatus} ]]; then
        echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Red_font_prefix}未安装 BBR 或 BBR Plus ${Font_color_suffix} 加速内核, 请先安装4.9以上内核 "
    else
        if [ ${systemBBRRunningStatus} = "no" ]; then
            echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}已安装 ${osKernelBBRStatus}${Font_color_suffix} 加速内核, ${Red_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        else
            echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}已安装 ${osKernelBBRStatus}${Font_color_suffix} 加速内核, ${Green_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        fi
        
		
    fi  
    echo -e " 当前拥塞控制算法: ${Green_font_prefix}${net_congestion_control}${Font_color_suffix}    ECN: ${Green_font_prefix}${systemECNStatusText}${Font_color_suffix}   当前队列算法: ${Green_font_prefix}${net_qdisc}${Font_color_suffix} "

    echo
    yellow " 检测本机 IPv4 " 
    echo  
    curl ipv4.ip.sb
	echo
    yellow " 检测本机	IPv6 " 
    echo  
    curl ipv6.ip.sb
	echo
    yellow " 检测本机 IPv4 或 IPv6 访问网络优先级测试" 
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
