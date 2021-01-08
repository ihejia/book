# CentOS7 升级内核后安装N卡驱动报错解决方法

## Power by AMD China FAE Team

## 转载注明本文链接：https://blog.258tiao.com/?id=4

升级CentOS内核后，由于新版的kernel核心使用新版本的gcc 9.3.1编译。系统内置的gcc版本为 4.8.5，会导致N卡驱动拒绝安装。

错误提示为：

该错误可以通过升级系统gcc版本解决，步骤如下：

### 1、添加scl源

`yum install centos-release-scl scl-utils-build -y`

### 2、安装编译内核相同版本的gcc

`yum install devtoolset-9-gcc.x86_64 devtoolset-9-gcc-c++.x86_64 devtoolset-9-gcc-gdb-plugin.x86_64 -y`

### 3、列出安装的scl包

`scl -l`
可以看到当前安装了 devtoolset-9

### 4、临时切换版本

`scl enable devtoolset-9 bash`

```note
### 5、切换后查看gcc版本
`gcc -v`
```


可以看到切换后gcc版本为9.3.1

```warning
## 注意事项：
1、安装N卡驱动时不要勾选DKMS ，勾选后安装时会导致错误
错误提示如下：

2、切换命令只是临时更改系统gcc版本，如需替换系统旧版为新版，请将新版本gcc g++建立软链接在 /usr/bin目录下即可
3、目前长期支持版内核5.10 在磁盘格式为Btrfs时 有严重性能衰退，目前已找到原因并给出了补丁，但是还没有更新到主线，建议分区为其他格式或者等补丁
```