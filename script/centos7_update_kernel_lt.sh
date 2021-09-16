#!/bin/bash
#download and install
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo yum -y install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
sudo yum -y remove kernel-headers
sudo yum -y --enablerepo=elrepo-kernel install kernel-lt.x86_64 kernel-lt-devel.x86_64 kernel-lt-headers.x86_64

mbrboot()
{
  echo The system use mbr boot mode !
  mbr=`sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg |awk -F ": " '{print $2}' | awk NR==1`
  echo $mbr
  sudo grub2-set-default "$mbr"
}

uefiboot()
{
  echo The system uefi boot mode !
  uefi=`sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/efi/EFI/centos/grub.cfg |awk -F ": " '{print $2}' | awk NR==1`
  echo $uefi
  sudo grub2-set-default "$uefi"
}



if [ -d /sys/firmware/efi ]; then
  uefiboot
else
  mbrboot
fi 

#[ -d /sys/firmware/efi ] && echo UEIF || echo Leagcy

echo "=================================================== "
echo "=========  内核安装完成。系统重启后生效！  ========== "
echo "=================================================== "