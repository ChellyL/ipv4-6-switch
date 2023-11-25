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

    red "OS info: ${osInfo}, ${osRelease}, ${osReleaseVersion}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osSystemShell}, ${osSystemPackage}, ${osSystemMdPath}"
}


virt_check(){
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

versionCompare () {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

versionCompareWithOp () {
    versionCompare $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]; then
        return 1
    else
        return 0
    fi
}

function showLinuxKernelInfoNoDisplay(){

    isKernelSupportBBRVersion="4.9"

    if versionCompareWithOp "${isKernelSupportBBRVersion}" "${osKernelVersionShort}" ">"; then
        echo
    else 
        osKernelBBRStatus="BBR"
    fi

    if [[ ${osKernelVersionFull} == *bbrplus* ]]; then
        osKernelBBRStatus="BBR Plus"
    elif [[ ${osKernelVersionFull} == *xanmod* ]]; then
        osKernelBBRStatus="BBR 和 BBR2"
    fi

	net_congestion_control=`cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}'`
	net_qdisc=`cat /proc/sys/net/core/default_qdisc | awk '{print $1}'`
	net_ecn=`cat /proc/sys/net/ipv4/tcp_ecn | awk '{print $1}'`

    if [[ ${osKernelVersionBackup} == *4.14.129* ]]; then
        isBBRTcpEnabled=$(lsmod | grep "bbr" | awk '{print $1}')
        isBBRPlusTcpEnabled=$(lsmod | grep "bbrplus" | awk '{print $1}')
        isBBR2TcpEnabled=$(lsmod | grep "bbr2" | awk '{print $1}')
    else
        isBBRTcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbr" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
        isBBRPlusTcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbrplus" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
        isBBR2TcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbr2" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
    fi

    if [[ ${net_ecn} == "1" ]]; then
        systemECNStatusText="已开启"      
    elif [[ ${net_ecn} == "0" ]]; then
        systemECNStatusText="已关闭"   
    elif [[ ${net_ecn} == "2" ]]; then
        systemECNStatusText="只对入站请求开启(默认值)"       
    else
        systemECNStatusText="" 
    fi

    if [[ ${net_congestion_control} == "bbr" ]]; then
        
        if [[ ${isBBRTcpEnabled} == *"bbr"* ]]; then
            systemBBRRunningStatus="bbr"
            systemBBRRunningStatusText="BBR 已启动成功"            
        else 
            systemBBRRunningStatusText="BBR 启动失败"
        fi

    elif [[ ${net_congestion_control} == "bbrplus" ]]; then

        if [[ ${isBBRPlusTcpEnabled} == *"bbrplus"* ]]; then
            systemBBRRunningStatus="bbrplus"
            systemBBRRunningStatusText="BBR Plus 已启动成功"            
        else 
            systemBBRRunningStatusText="BBR Plus 启动失败"
        fi

    elif [[ ${net_congestion_control} == "bbr2" ]]; then

        if [[ ${isBBR2TcpEnabled} == *"bbr2"* ]]; then
            systemBBRRunningStatus="bbr2"
            systemBBRRunningStatusText="BBR2 已启动成功"            
        else 
            systemBBRRunningStatusText="BBR2 启动失败"
        fi
                
    else 
        systemBBRRunningStatusText="未启动加速模块"
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
        yellow " VPS服务器已成功设置为 IPv4 优先访问网络"

    else

        green " ================================================== "
        yellow " 请为服务器设置 IPv4 还是 IPv6 优先访问: "
        echo
	blue " 选择优先使用 IPv6 访问网络（选项2）,可能会出现无法访问某些不支持IPv6网站的情况"
        blue " 若使用V2ray,可在V2ray配置中设置IPv6分流,以解锁Netflix限制和避免弹出Google人机验证"
        blue " 由于trojan 或 trojan-go 无法配置IPv6分流, 使用这种协议者可尝试 开启优先IPv6访问"
	yellow " 若取消操作，将执行选择3，恢复系统默认设置"
	echo
        echo -e " ${Green_font_prefix}1.${Font_color_suffix} 优先 IPv4 访问网络 (用于 给只有 IPv6 的 VPS主机添加 IPv4 网络支持，请保证你的服务器具备IPv4地址)"
        echo -e " ${Green_font_prefix}2.${Font_color_suffix} 优先 IPv6 访问网络 (用于 解锁 Netflix 限制 和避免弹出 Google reCAPTCHA 人机验证，请保证你的服务器具备IPv4地址)"
        echo -e " ${Green_font_prefix}3.${Font_color_suffix} 删除 IPv4 或 IPv6 优先访问的设置, 还原为系统默认配置，若取消操作将还原为系统默认设置"
        echo
        read -p "请选择 IPv4 还是 IPv6 优先访问? 直接回车默认选1, 请输入[1/2/3]:" isPreferIPv4Input
        isPreferIPv4Input=${isPreferIPv4Input:-1}

        if [[ ${isPreferIPv4Input} == [2] ]]; then

            # 设置 IPv6 优先
            echo "label 2002::/16   2" >> /etc/gai.conf

            echo
            yellow " 已成功设置为 IPv6 优先访问网络 "
        elif [[ ${isPreferIPv4Input} == [3] ]]; then

            echo
            yellow " 已删除 IPv4 或 IPv6 优先访问设置, 还原为系统默认配置 "  
        else
            # 设置 IPv4 优先
            echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
            
            echo
            green " 已成功设置为 IPv4 优先访问网络 "    
        fi

        green " ================================================== "
        echo
        yellow " 检测本机访问网络优先级" 
	yellow " 如显示IPv4地址，则为 IPv4优先访问；如为IPv6地址，则为 IPv6优先访问"
        echo  
        curl ip.p3terx.com
        echo
        green " ================================================== "

    fi
    echo

}


function installWarp(){
    green " ************************************************ "
    echo
    blue " 将使用fscarmen的Cloudflare Warp脚本进行安装，脚本详细使用方法见https://gitlab.com/fscarmen/warp"
    # blue " 仅建议只有IPv4或IPv6的vps使用此脚本增加另一地址，Warp安装成功后建议再次运行此脚本，"
    # blue " 选择4 永久开启，为Warp设置开机自启，以免设置ipv6分流后，重启vps时Warp未启动而导致无法访问部分IPv6网站等问题"
    blue " 若想再次运行此脚本，请输入 bash menu.sh"
    echo
    green " ************************************************ "
    sleep 4s
    echo
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
}


function updatekernel(){
    green " ************************************************ "
    echo
    blue " 使用ylx2016的Linux-NetSpeed脚本进行安装，原脚本Github地址为https://github.com/ylx2016/Linux-NetSpeed"
    blue " 如果你的内核没有升级至5.0以上，则无法安装warp，故建议先升级内核至5.0以上"
    blue " 选1 安装BBR原本内核，即可升级至最新内核"
    blue " 若安装Warp后仍无法检测出IPv6或安装失败，可尝试使用此脚本，开启IPv6"
    echo
    green " ************************************************ "
    sleep 4s
    wget -O tcp.sh "https://git.io/coolspeeda" && chmod +x tcp.sh && ./tcp.sh
}


function mediacheck(){
    green " ************************************************ "
    echo
    blue " 使用 lmc999 的 RegionRestrictionCheck 脚本进行安装，原脚本Github地址为https://github.com/lmc999/RegionRestrictionCheck"
    # blue " 如果你的内核没有升级至5.0以上，则无法安装warp，故建议先升级内核至5.0以上"
    # blue " 选1 安装BBR原本内核，即可升级至最新内核"
    # blue " 若安装Warp后仍无法检测出IPv6或安装失败，可尝试使用此脚本，开启IPv6"
    echo
    green " ************************************************ "
    sleep 2s
    apt install curl
    bash <(curl -L -s check.unlock.media)
}


function start_menu(){
    clear
    
    if [[ $1 == "first" ]] ; then
        getLinuxOSRelease
    fi
    showLinuxKernelInfoNoDisplay

    green " =================================================="
    echo " 魔改自 jinwyp 的 Linux 内核 一键安装脚本 | 系统支持：centos7+ / debian10+ / ubuntu16.04+"
    echo " 原脚本详见 https://github.com/jinwyp/one_click_script "
    echo " 本脚本主要功能是设置vps服务器优先使用IPv4或IPv6访问网络，另附带升级内核、安装Warp的功能 "
    red " 在生产环境中请谨慎使用此脚本, 请提前做好备份；升级内核或更改网络设置可能会导致部分VPS无法启动或访问网络 "
    green " =================================================="
     if [[ -z ${osKernelBBRStatus} ]]; then
        echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Red_font_prefix}未安装 ${Font_color_suffix} BBR 或 BBR Plus 加速内核 "
    else
        if [ ${systemBBRRunningStatus} = "no" ]; then
            echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}已安装 ${Font_color_suffix} ${osKernelBBRStatus} 加速内核, ${Red_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        else
            echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}已安装 ${Font_color_suffix} ${osKernelBBRStatus} 加速内核, ${Green_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        fi
        
	fi
	echo -e " 当前拥塞控制算法: ${Green_font_prefix}${net_congestion_control}${Font_color_suffix}    ECN: ${Green_font_prefix}${systemECNStatusText}${Font_color_suffix}   当前队列算法: ${Green_font_prefix}${net_qdisc}${Font_color_suffix} "
	
	green " ************************************************ "
    echo
    yellow " 本机 IPv4 地址："
    curl -4 ip.p3terx.com
    local_isp4=$(curl $useNIC -s -4 --max-time 10 --user-agent "${UA_Browser}" "https://api.ip.sb/geoip/${local_ipv4}" | grep organization | cut -f4 -d '"')
    yellow " 您的网络为: ${local_isp4}"
    echo
    yellow " 本机 IPv6 地址："
    curl -6 ip.p3terx.com
    local_isp6=$(curl $useNIC -s -6 --max-time 10 --user-agent "${UA_Browser}" "https://api.ip.sb/geoip/${local_ipv6}" | grep organization | cut -f4 -d '"')
    yellow " 您的网络为: ${local_isp6} "
    echo
    yellow " 检测本机 IPv4 或 IPv6 访问网络优先级："
    yellow " 如显示IPv4地址，则为 IPv4优先访问；如为IPv6地址，则为 IPv6优先访问"
    curl ip.p3terx.com
    echo
    green " ************************************************ "
    echo
    echo -e " ${Green_font_prefix}1.${Font_color_suffix}  升级内核至5.0以上；开启IPv6"
    echo -e " ${Green_font_prefix}2.${Font_color_suffix}  安装Cloudflare Warp. 若vps仅有IPv4或IPv6地址，可安装Warp，增加另一IP，但内核须为5.0及以上"
    echo -e " ${Green_font_prefix}3.${Font_color_suffix}  设置服务器优先使用 IPv4 或 IPv6 访问网络"
    echo -e " ${Green_font_prefix}4.${Font_color_suffix}  流媒体检测"
    echo
    green " ************************************************ "
    echo -e " ${Green_font_prefix}0.${Font_color_suffix}  退出脚本"
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
	4 )
 	   mediacheck
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
