# Linux下查看硬盘UUID和修改硬盘UUID

转载注明本文链接：

```note
硬盘分区查看可以通过ls与blkid命令,具体示例如下：
```

### 一、查看硬盘分区

#### 1、通过ls命令

`ls -l /dev/disk/by-uuid`
    
#### 2、通过blkid命令

`blkid`

//该命令可以查看所有硬盘分区ID

如果查看具体某个分区ID在参数上添加即可例如：

`blkid /dev/sda5`


### 二、修改硬盘分区UUID

```note
下面示例如何新建与修改UUID。
```

#### 1、新建和改变分区的UUID

`sudo uuidgen | xargs tune2fs /dev/sda3 -U`

#### 2、umount 分区挂载（已挂载分区不能修改）

#### 3、将需要的UUID写到分区
`tune2fs -U fb64ca8a-dc5f-4446-8c18-4e0f05dbcbe1 /dev/sda3`
