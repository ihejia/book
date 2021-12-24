# CentOS7卡安装界面解决办法

该故障原因：centos7默认内核版本保持在3.10导致在使用新的CPU、主板、wifi等设备时安装会卡在引导界面

错误提示如下：

![](https://book.258tiao.com/photo/centos_install_error.jpg)

```
解决办法:
	将该机器的硬盘安装在可以正常引导的机器安装系统后，升级内核版本为长期支持版或者最新版后，硬盘安装回该机器使用正常。
```

具体操作方法如下：

### 一、选择并下载并执行

##### 1、长期支持版内核

```bash
cd ~ && wget https://book.258tiao.com/script/centos7_update_kernel_lt.sh && chmod +x centos7_update_kernel_lt.sh && ./centos7_update_kernel_lt.sh && rm -rf ~/centos7_update_kernel_lt.sh
```

##### 2、最新版内核

```bash
cd ~ && wget https://book.258tiao.com/script/centos7_update_kernel_ml.sh && chmod +x centos7_update_kernel_ml.sh && ./centos7_update_kernel_ml.sh && rm -rf ~/centos7_update_kernel_ml.sh
```

### 二、重启验证内核版本
`uname -a`

