# HPL for AMD CPU测试工具一键配置
## Power by AMD China FAE Team

转载注明本文链接：<https://tools.258tiao.com>

```note
1、该脚本目前只在ubuntu 20.04 LTS环境进行测试通过

2、其他操作系统没有进行测试

3、由于库文件的原因该脚本仅限于AMD CPU使用
```
```warning
警告：执行该命令会删除已安装的测试环境目录
```
### 一、复制并执行下面的命令
`rm -rf ~/hpl && mkdir ~/hpl && cd ~/hpl && wget https://tools.258tiao.com/tools/hpl/install-hpl-ubuntu2004-newer-gcc9-v1.0.5.sh && chmod +x install-hpl-ubuntu2004-newer-gcc9-v1.0.5.sh &&sudo -s ./install-hpl-ubuntu2004-newer-gcc9-v1.0.5.sh &&sudo -s chown -R $whoami:$whoami ./`


### 二、运行测试程序并等待结果

`./run_hpl_test.sh`