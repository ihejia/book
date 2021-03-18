#!/bin/bash
#==============================================================#
#   Description:  Unixbench script                             #
#   Author: ihejia <ehejia@qq.com>                             #
#   Intro:  https://book.258tiao.com/                          #
#==============================================================#
soft_dir=/opt/benchmark
driver_ver=455.23.04
# Check System
if [ -f /etc/redhat-release ]; then
    release="centos"
elif grep -Eqi "debian" /etc/issue; then
    release="debian"
elif grep -Eqi "ubuntu" /etc/issue; then
    release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
    release="centos"
elif grep -Eqi "debian" /proc/version; then
    release="debian"
elif grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
else
    release="" && echo 'Error: Your system is not supported to run it!' && exit 1
fi

echo "=================================================== "
echo "=======     this system ver $release !      ======= "
echo "=================================================== "

#Install necessary libaries
if [ "$release" = 'centos' ]; then
    sudo -s yum install -y epel*
    sudo -s yum install -y git net-tools openssh-server htop screenfetch dkms make automake gcc ntpdate nano lm-sensors
    sudo -s service sshd start
    echo "sync date"
    sudo -s ntpdate time.apple.com
    sudo -s hwclock -w
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nvidia-installer-disable-nouveau.conf &&echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
    sudo mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
    sudo dracut /boot/initramfs-$(uname -r).img $(uname -r)
else
    sudo -s apt update 
    sudo -s apt install -y git net-tools openssh-server htop screenfetch dkms make automake gcc ntpdate nano lm-sensors
    sudo -s service sshd start
    echo "sync date"
    sudo -s ntpdate time.apple.com
    sudo -s hwclock -w
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nvidia-installer-disable-nouveau.conf &&echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
    sudo -s update-initramfs -u
    sudo apt install -y nvidia-driver-460
fi
# sudo -s rm -rf ~/linux_setting

#创建安装目录
sudo -s mkdir -p $soft_dir
sudo -s chown -R $(whoami):$(whoami) $soft_dir
cd $soft_dir
rm -rf $soft_dir/2_install_conda.sh && wget --no-check-certificate -P $soft_dir https://tools.258tiao.com/script/2_install_conda.sh && chmod +x $soft_dir/2_install_conda.sh && sh $soft_dir/2_install_conda.sh && rm -rf $soft_dir/2_install_conda.sh 

#下载安装驱动
# if [ -s NVIDIA-Linux-x86_64-$driver_ver.run ]; then
#     echo "驱动已存在安装目录，即将使用该驱动"
# else
#     echo "NVIDIA-Linux-x86_64-$driver_ver.run not found!!!download now..."
#     if ! wget -c https://cn.download.nvidia.com/XFree86/Linux-x86_64/$driver_ver/NVIDIA-Linux-x86_64-$driver_ver.run; then
#         echo "Failed to download nvidia drives, please download it to $soft_dir directory manually and try again."
#         exit 1
#     fi
# fi
# chmod +x NVIDIA-Linux-x86_64-$driver_ver.run
# sudo -s ./NVIDIA-Linux-x86_64-$driver_ver.run -no-opengl-files -no-x-check -Z -z -dkms

#rm -rf NVIDIA-Linux-x86_64-$driver_ver.run

echo "=================================================== "
echo "=======  驱动安装完成。10秒钟系统重启后继续！  ======= "
echo "=================================================== "

echo 10
sleep 1s &&echo 9
sleep 1s &&echo 8
sleep 1s &&echo 7
sleep 1s &&echo 6
sleep 1s &&echo 5
sleep 1s &&echo 4
sleep 1s &&echo 3
sleep 1s &&echo 2
sleep 1s &&echo 1
rm ~/1_system_init.sh && sudo reboot