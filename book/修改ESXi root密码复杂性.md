# 修改ESXi root密码复杂性


转载注明本文链接

```note
ESXi 默认密码策略太过于严格，引起使用不便，可以通过修改密码复杂性解决
```

### 1、开启服务器SSH登录权限
    
### 2、登录ESXi服务器后按下面方式处理

`vi /etc/pam.d/passwd`

编辑内容如下：

`password required /lib/security/$ISA/pam_passwdqc.so retry=3 min=disabled,disabled,7,7,7 max=30 match=4 similar=deny enforce=users`

保存并退出，

### 3、命令行输入passwd进行密码修改即可。

```warning
主要是enforce=users在起作用。
```

参考：<https://www.jianshu.com/p/54356825239b>
