# IPv4/6 Switch
设置VPS服务器优先使用IPv4或IPv6访问网络的脚本

## 简介
本脚本魔改自 [jinwyp(JinWYP)](https://github.com/jinwyp) 的 [one_click_script](https://github.com/jinwyp/one_click_script) 一键安装内核的脚本

主要作用是为你的vps服务器设置优先使用IPv6或IPvv4访问网络

脚本运行后将会检测你的vps服务的IPv4和IPv6地址，并检测你的vps优先使用哪个地址访问网络

由于部分vps仅有IPv4或IPv6地址，因此也附带了[missuo(Vincent Young)](https://github.com/missuo)的[Cloudflare Warp](https://github.com/missuo/CloudflareWarp)脚本及[ylx2016(dr)](https://github.com/ylx2016)的[Linux-NetSpeed](https://github.com/ylx2016/Linux-NetSpeed)脚本

可使用这两个脚本将你的vps内核升级至5.0以上，并安装warp，为没有IPv4的IPv6 服务器增加 IPv4，或为没有IPv6的 IPv4 服务器增加IPv6

通过IPv6访问Google或Netflix，可有效解决IP被Google标识后老是弹出人机验证（不能100%解决）及Netflix仅可看自制剧的问题

## 使用
在使用之前你可能需要安装wget以及curl：

Cent OS：
```
yum -y install wget
yum install curl
```
Debian / Ubuntu：
```
apt -y install wget
apt install curl
```

主要支持 Linux X86_64 系统，ARM构架慎用Warp功能
```
wget -O ipv_switch.sh https://raw.githubusercontent.com/ChellyL/ipv4-6-switch/main/ipv_switch.sh && bash ipv_switch.sh
```
若需要再次使用本脚本，运行以下命令即可：
```
bash ipv_switch.sh
```

若想在运行 Cloudflare Warp 或 Linux-NetSpeed 后再次运行脚本，除了使用 bash ipv_switch.sh 之外，也可单独运行这两个脚本（如网络访问出现问题时）：

Cloudflare Warp
```
warp.sh
```
Linux-NetSpeed
```
tcp.sh
```
## 注意事项
安装时有相关选项说明作为参考，建议选择前先看说明，脚本运行之初会自动检测你的ip地址及系统内核等情况

若你的vps已经有了IPv4和IPv6两个地址，需要设置其中某一项优先访问网络，选择3即可

若仅有其中一个地址则，推荐使用Cloudflare Warp脚本安装Warp，增加另一地址，再进行相关操作

由于安装Warp需内核为5.0及以上，故建议先升级内核再安装Warp。如果服务器默认没有开启IPv6，也可使用升级内核脚本开启IPv6

## 参考&感谢
jinwyp(JinWYP)及其脚本one_click_script https://github.com/jinwyp/one_click_script

missuo(Vincent Young)及其脚本Cloudflare Warp https://github.com/missuo/CloudflareWarp

ylx2016(dr)及其脚本Linux-NetSpeed https://github.com/ylx2016/Linux-NetSpeed

## 界面截图
![截图](https://github.com/ChellyL/ipv4-6-switch/blob/main/screenshot.png)
