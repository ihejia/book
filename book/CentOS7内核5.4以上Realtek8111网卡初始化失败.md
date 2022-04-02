# CentOS7升级内核5.4以上, Realtek 8111网卡初始化失败
https://www.cnblogs.com/milton/p/14654301.html
在Centos7中, 升级内核到5.4.x或5.11.x时, 都会出现realtek8111网卡无法启动的问题, 在dmesg中能看到这个错误

```bash
$ dmesg |grep -i r8169
...
r8169 0000:01:00.0: realtek.ko not loaded
```

对这个问题的临时解决办法为

```bash
rmmod r8169
modprobe r8169
```

持久化的解决办法为添加到服务

```bash
# 添加service文件
vi /etc/systemd/system/load-realtek-driver.service

#内容开始
[Unit]
Description=Load Realtek drivers.
Before=network-online.target

[Service]
Type=simple
ExecStartPre=/usr/sbin/rmmod r8169
ExecStart=/usr/sbin/modprobe r8169

[Install]
WantedBy=multi-user.target
#内容结束

# 然后
systemctl enable load-realtek-driver.service
```
