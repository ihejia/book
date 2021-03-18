#!/bin/bash
soft_dir=/opt/benchmark
conda_ver="Anaconda3-2020.11-Linux-x86_64.sh"
conda_path="/usr/local/anaconda3"

cd $soft_dir
if [ -f ./$conda_ver ] ; then
	 rm -rf $conda_ver
fi

wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/$conda_ver

if [ ! -e "$conda_ver" ] ; then
	echo "Download error,Please check the networks!"
    else
	sudo -s sh $conda_ver -b -u -p $conda_path
#	rm -rf $conda_ver
	sudo -s chown -R $(whoami):$(whoami) $conda_path

	#couda初始化设置
	echo "Conda安装完毕,是否初始化客户端"
        read -p "输入y同意或者任意键取消:" conda_set ;
        if  [ $conda_set = 'y' ] ; then
	        $conda_path/bin/conda init
        else
                echo -e "选择不初始化conda环境,后期可使用命令 $conda_path/bin/conda init 完成初始化"
        fi

	#tensorflow环境配置
	echo "是否创建tensorflow测试环境"
	read -p "输入y同意或者任意键取消:" tensorflow_set ;
	if  [ $tensorflow_set = 'y' ] ; then
	#	$conda_path/bin/conda create -n tf-gpu python=3.6 tensorflow-gpu==1.13.1 -y //更新版本以适应30系列显卡
		$conda_path/bin/conda create -n tf21 python=3.7 tensorflow-gpu==2.1 cudatoolkit=10.1 -y
		rm -rf benchmarks_tf21 benchmarks_tf21.tar.gz tensorflow_benchmark.sh
		#如果访问github困难将修改为wget下载程序包
		#git clone -b cnn_tf_v2.1_compatible https://github.com/tensorflow/benchmarks  benchmarks_tf21
		wget https://tools.258tiao.com/tools/benchmarks_tf21.tar.gz
		wget --no-check-certificate -P ~ https://tools.258tiao.com/script/tensorflow_benchmark.sh && chmod +x ~/tensorflow_benchmark.sh 
		tar -zvxf benchmarks_tf21.tar.gz
	else
		echo "选择不安装Tensorflow测试环境！"
	fi

        #pythorch环境配置
        echo "是否创建pythorch测试环境"
        read -p "输入y同意或者任意键取消:" pythorch_set ;
	if  [ $pythorch_set = 'y' ] ; then
                $conda_path/bin/conda create -n pytorch_benchmark python=3.7 pytorch torchtext torchvision -c pytorch-nightly -y
				rm -rf pytorch_benchmark ~/pytorch_benchmark.sh
				#如果访问github困难将修改为wget下载程序包
				git clone https://github.com/pytorch/benchmark  pytorch_benchmark
				wget --no-check-certificate -P ~ https://tools.258tiao.com/script/pytorch_benchmark.sh && chmod +x ~/pytorch_benchmark.sh
        else
                echo "选择不安装pytorch测试环境"
        fi

	#合并tensorflow与pytorch环境，由于30系列显卡不支持1.13故将tensorflow升级到2.1版本
	# echo "是否创建tensorflow、pytorch测试环境"
	# read -p "输入y同意或者任意键取消:" tensorflow_set ;
	# if  [ $tensorflow_set = 'y' ] ; then
	# 	$conda_path/bin/conda create -n tf21 python=3.7 tensorflow-gpu==2.1 cudatoolkit=10.1 pytorch torchtext torchvision -c pytorch-nightly -y
	# else
	# 	echo "选择不安装测试环境！"
	# fi

	sudo -s chown -R $(whoami):$(whoami) $conda_path
fi

echo "=================================================== "
echo "=======  配置环境完成，重启后执行相应程序测试  ======= "
echo "====  tensorflow_benchmark为tensorflow性能测试  ==== "
echo "======  pytorch_benchmark为pytorch性能测试  ======== "
echo "=================================================== "

sleep 3s