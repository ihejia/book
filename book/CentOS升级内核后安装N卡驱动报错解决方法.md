# CentOS7 升级内核后安装N卡驱动报错解决方法


转载注明本文链接：

```tip
升级CentOS内核后，由于新版的kernel核心使用新版本的gcc 9.3.1编译。系统内置的gcc版本为 4.8.5，会导致N卡驱动拒绝安装。

错误提示如下：

![Branching](https://book.258tiao.com/photo/1.jpg)
```

该错误可以通过升级系统gcc版本解决，步骤如下：

### 1、添加scl源

`yum install centos-release-scl scl-utils-build -y`

### 2、安装编译内核相同版本的gcc

`yum install devtoolset-9-gcc.x86_64 devtoolset-9-gcc-c++.x86_64 devtoolset-9-gcc-gdb-plugin.x86_64 -y`

### 3、列出安装的scl包

`scl -l`

可以看到当前安装了 `devtoolset-9`

![Branching](https://book.258tiao.com/photo/devtoolver.jpg)

### 4、临时切换版本

`scl enable devtoolset-9 bash`

### 5、切换后查看gcc版本

`gcc -v`

![Branching](https://book.258tiao.com/photo/gccv.jpg)

可以看到切换后gcc版本为9.3.1

```warning
## 注意事项：
1、安装N卡驱动时不要勾选DKMS ，勾选后安装时会导致错误
错误提示如下：

![Branching](https://book.258tiao.com/photo/nv_error.jpg)

2、切换命令只是临时更改系统gcc版本，如需替换系统旧版为新版，请将新版本gcc g++建立软链接在 /usr/bin目录下即可

3、由于扩展库主线LT与ML内核升级导致只能安装460及以上驱动，低版本驱动在更新内核后无法安装
```
