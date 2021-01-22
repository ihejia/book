# 解决linux笔记本休眠唤醒黑屏

## Power by AMD China FAE Team

转载注明本文链接：<https://blog.258tiao.com/?id=4>

```note
debian 与 基于debian系列的ubuntu在笔记本使用时经常会遇到休眠后黑屏的情况，可以通过安装软件解决
```

运行命令如下：

`sudo apt install laptop-mode-tools `

```
大多数笔记本安装以上软件可以解决休眠问题，但是有些笔记本比较特殊，安装该软件后没有缓解可以继续安装pm-utils软件：
```

`sudo apt-get install pm-utils`



pm-utils具体介绍如下:

https://blog.csdn.net/qingqing7/article/details/78555006

详细配置可参考archlinux维基其连接如下：

https://wiki.archlinux.org/index.php/Laptop_Mode_Tools_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)

下面有一篇详细介绍的文章并解决安装该工具后鼠标不能唤醒的问题：

https://blog.csdn.net/zn2857/article/details/53064894