#!/usr/bin/env bash

ADDRESS_JEMALLOC=https://github.com/jemalloc/jemalloc.git
ADDRESS_KNEM=https://gforge.inria.fr/git/knem/knem.git
ADDRESS_AMD_FLAME_BLIS=https://github.com/flame/blis/archive/amd.zip
ADDRESS_AMD_BLIS=https://github.com/amd/blis.git
AMD_AOCL20_TAR=aocl-blis-mt-ubuntu-2.0.tar.gz
ADDRESS_AMD_AOCL20=https://github.com/amd/blis/releases/download/2.0/$AMD_AOCL20_TAR
AMD_AOCL21_TAR=aocl-ubuntu-2.1-1910.tar.gz
ADDRESS_AMD_AOCL21=http://aocl.amd.com/data/oct-2019/$AMD_AOCL21_TAR
ADDRESS_OPENMPI=https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.0.tar.bz2
ADDRESS_HPL=https://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
SCRIPT_NAME="$(basename $0)"
build_xhpl=false
exit_on_error=false
test_run=false
download_amd_aocl=true
work_dir_only=false
local_install=false
openmpi_only=false
knem_only=false
remove_hpl_dir=false

top=$(pwd)
HPL_DIR=$top'/hpl'

parse_args()
{
	# Based upon:
	# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
	
	# Make sure you call this routine as follows:
	# parse_args "$@"
	# Otherwise, the commandline arguments will not be in scope

	echo "Parsing $# arguments..." 
	while [ $# -gt 0 ]
	do
		echo "Parsing arguments :$#"
		key="$1"
		case $key in
			-b|--build_xhpl)
				build_xhpl=true
				shift # past argument
			;;
			-e|--exit_on_error)
				exit_on_error=true
				shift # past argument
			;;
			-h|--help)
				help_show
				exit 0
			;;
			-i|--install_dir)
				if [[ $2 == /* ]]; then
					HPL_DIR="$2"
				else
					echo "You need to provide the literal HPL installation path starting with the root '/' directory."
					exit 1
				fi
				shift # past argument
				shift # past value
			;;
			-k|--knem_install_only)
				knem_only=true
				shift # past argument
			;;
			-l|--local_install) # do not use online sources
				local_install=true
				shift # past argument
			;;
			-o|--openmpi_install_only)
				openmpi_only=true
				shift # past argument
			;;
			-r|--remove_hpl_dir_before_install)
				remove_hpl_dir=true
				shift # past argument
			;;
			-t|--test)
				echo You chose to make a test run
				test_run=true
				shift # past argument
			;;
			--default)
				DEFAULT=YES
				shift # past argument
			;;
			-w|--work_dir_only)
				work_dir_only=true
				shift # past argument
			;;
			*)    # unknown option
				echo "You have entered the unknown switch $key"
				#echo "Exiting script."
				#exit 1
			;;
		esac
	done
	set -- "${POSITIONAL[@]}" # restore positional parameters
}

help_show()
{
	# Display Help
	echo 
	echo "usage  : ./$SCRIPT_NAME [-h] [-i <custom_dir_path>] [-w <install only the work directory>]"
	echo "example: ./$SCRIPT_NAME -i /home/user/hpl -b"
	echo "options:"
	echo "-h|--help     Print this Help."
	echo "-b|--build_xhpl                     Build the xhpl binary instead of using the prebuilt binary"
	echo "-e|--exit_on_error                  Exit script on error"
	echo "-i|--install_dir <custom_dir_path>  Install HPL to <custom_dir_path>"
	echo "-l|--local_install                  Use only local sources; do not use online sources"
	echo "-k|--knem_install_only              Only install knem"
	echo "-o|--openmpi_install_only           Only install openmpi"
	echo "-r|--remove_hpl_dir_before_install  Remove the existing hpl directory before install"
	echo "-t|--test                           Test run: display cmd arguments and sysinfo"
	echo "-w|--work_dir_only                  Only install the work directory"
	echo 
}

enable_ubuntu_repositories()
{
	echo Enable all Ubuntu repositories...
	add-apt-repository universe
	add-apt-repository multiverse
	add-apt-repository restricted
	add-apt-repository main
}

install_dependencies()
{
	# install all dependencies软件版本错误导致不能执行
	apt update
	apt install -y pkg-config gcc-9 g++-9 gfortran-9 gcc-9-multilib g++-9-multilib make numactl libnuma-dev hwloc libhwloc-dev libelf-dev screenfetch mc wget htop dmidecode git unzip vim htop tmux python3 python3-pip python-is-python3 lm-sensors openssh-server
	apt install -y linux-headers-$(uname -r) linux-tools-$(uname -r) linux-tools-generic
	apt install -y python-is-python3
	# make gcc 9.0/g++9.0 default
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100
	update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 100
	update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-9 100
	pip3 install psutil
}

purge_packages()
{
	apt purge -y snapd ubuntu-core-launcher squashfs-tools unattended-upgrades
}

set_cpu_performance()
{
	# set the CPU governor to performance
	cpupower frequency-set -g performance
}

get_sysinfo()
{
	# Find out how many sockets are in the system
	sockets=$( lscpu | grep "Socket(s)" | awk '{print $2}' )
	echo "$sockets socket(s) detected "
	# Find out how many physical cores per socket
	cores=$( lscpu | grep "Core(s) per socket" | awk '{print $4}' )
	echo "$cores core(s) per socket detected "
	# Find out how many NUMA nodes are in the system
	numa=$( numactl --hardware | grep "available:" | awk '{print $2}' )
	echo "$numa NUMA nodes detected "
}

install_jemalloc()
{
	cd $HPL_DIR
	if [ $local_install != true ]; then
		#Download and install jemalloc:
		git clone $ADDRESS_JEMALLOC jemalloc
	fi
	cd jemalloc/
	./autogen.sh
	CFLAGS="-Ofast -march=znver2" ./configure
	make clean
	make dist
	make -j $(($sockets * $cores))
	make install
	cd $HPL_DIR
}

set_build_flags()
{
    BUILD_FLAGS="CFLAGS='-Ofast -march=znver2 -ljemalloc -I$HPL_DIR/jemalloc/include/jemalloc' LDFLAGS=-L$HPL_DIR/jemalloc/lib"
    echo BUILD_FLAGS = $BUILD_FLAGS
    eval $BUILD_FLAGS
    echo CFLAGS = $CFLAGS
    echo LDFLAGS = $LDFLAGS
}

install_knem()
{
	rm -rf /opt/knem
	get_sysinfo
    cd $HPL_DIR
	if [ $local_install != true ]; then
		#Download and install knem
		git clone $ADDRESS_KNEM knem
	fi
    cd knem
    ./autogen.sh
    eval $BUILD_FLAGS
    ./configure
    make clean
    make -j $(($sockets * $cores))
    make install
    /opt/knem/sbin/knem_local_install
    cd $HPL_DIR
}

build_amd_flame_blis()
{
	get_sysinfo
    cd $HPL_DIR
	#build and install Flame AMD BLIS:
    wget $ADDRESS_AMD_FLAME_BLIS
    unzip amd.zip
    cd blis-amd
    eval $BUILD_FLAGS
    ./configure --prefix=/opt/blis --enable-threading=openmp zen2
    make clean
    make -j $(($sockets * $cores))  # This number must be equal to the number of physical cores of the system
    make install
	BLIS_DIR=/opt/blis
	LIB_BLIS=libblis.so
    cd $HPL_DIR
}

build_amd_blis()
{
	get_sysinfo
	BLIS_DIR=/opt/amd-blis
	LIB_BLIS=libblis.so
	rm -rf $BLIS_DIR
	get_sysinfo
    cd $HPL_DIR
    # build and install AMD BLIS:
    git clone $ADDRESS_AMD_BLIS
    cd blis
    echo "Build Multi-threaded BLIS"
    enableblismt="--enable-threading=openmp"
    eval $BUILD_FLAGS
    echo ./configure --enable-shared --enable-cblas $enableblismt --prefix=$BLIS_DIR zen2
    ./configure --enable-shared --enable-cblas $enableblismt --prefix=$BLIS_DIR zen2
    make clean
    make -j $(($sockets * $cores))
    make install
    cd $HPL_DIR
}


copy_amd_aocl()
{
	cd $top
	cp $AMD_AOCL21_TAR $HPL_DIR/
	cd -
}


install_amd_aocl()
{
	get_sysinfo
    cd $HPL_DIR
	if [ $download_amd_aocl == true ] && [ $local_install != true ]; then
		AOCL_DIR=/opt/amd/aocl/2.0
		rm -rf $AOCL_DIR
		mkdir /opt/amd
		mkdir /opt/amd/aocl
		mkdir /opt/amd/aocl/2.0
		mkdir /opt/amd/aocl/2.0/amd-blis-mt
		BLIS_DIR=$AOCL_DIR/amd-blis-mt
		LIB_BLIS=libblis-mt.so
		wget $ADDRESS_AMD_AOCL20
		tar -xvf $AMD_AOCL20_TAR
		cd amd-blis-mt
		#./install.sh -t /opt
		cp lib/* $BLIS_DIR
	else
		AOCL_DIR=/opt/amd/aocl/2.1-1910
		rm -rf $AOCL_DIR
		BLIS_DIR=$AOCL_DIR/amd-blis-mt
		LIB_BLIS=libblis-mt.so
		copy_amd_aocl
		tar -xvf $AMD_AOCL21_TAR
		cd aocl-ubuntu-2.1-1910
		./install.sh -t /opt
	fi
    cd $HPL_DIR
}

build_openmpi()
{
	rm -rf /opt/openmpi
	get_sysinfo
	if [ $local_install != true ]; then
		#Download and install openmpi
		wget $ADDRESS_OPENMPI
	fi
    tar -xvf openmpi-4.0.0.tar.bz2
    cd openmpi-4.0.0
    eval $BUILD_FLAGS
    ./configure --prefix=/opt/openmpi --with-knem=/opt/knem
    make clean
    make -j $(($sockets * $cores))  # This number must be equal to the number of physical cores of the system
    make install
    cd $HPL_DIR
    ln -s /opt/openmpi/lib/libmpi.so.40.20.0 /opt/openmpi/lib/libmpi.so.20
}

backup_xhpl_bin()
{
	cd $top
	mkdir $HPL_DIR/work/xhpl_backup
	cp xhpl $HPL_DIR/work/xhpl_backup/
}

move_xhpl_bin()
{
	backup_xhpl_bin
	cd $top
	#修改移动为拷贝mv xhpl $HPL_DIR/work/
	mv xhpl $HPL_DIR/work/
}

build_hpl()
{
	cd $HPL_DIR
	if [ $local_install != true ]; then
		#Download and install HPL-2.3
		wget $ADDRESS_HPL
	fi
    tar -xvf hpl-2.3.tar.gz
    mv hpl-2.3 hpl
    cd hpl
echo "########################################################################
#  -- High Performance Computing Linpack Benchmark (HPL)
#     HPL - 2.3 - December 2, 2018
#     Antoine P. Petitet
#     University of Tennessee, Knoxville
#     Innovative Computing Laboratory
#     (C) Copyright 2000-2008 All Rights Reserved
#
#  -- Copyright notice and Licensing terms:
#
#  Redistribution  and  use in  source and binary forms, with or without
#  modification, are  permitted provided  that the following  conditions
#  are met:
#
#  1. Redistributions  of  source  code  must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce  the above copyright
#  notice, this list of conditions,  and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#  3. All  advertising  materials  mentioning  features  or  use of this
#  software must display the following acknowledgement:
#  This  product  includes  software  developed  at  the  University  of
#  Tennessee, Knoxville, Innovative Computing Laboratory.
#
#  4. The name of the  University,  the name of the  Laboratory,  or the
#  names  of  its  contributors  may  not  be used to endorse or promote
#  products  derived   from   this  software  without  specific  written
#  permission.
#
#  -- Disclaimer:
#
#  THIS  SOFTWARE  IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE UNIVERSITY
#  OR  CONTRIBUTORS  BE  LIABLE FOR ANY  DIRECT,  INDIRECT,  INCIDENTAL,
#  SPECIAL,  EXEMPLARY,  OR  CONSEQUENTIAL DAMAGES  (INCLUDING,  BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA OR PROFITS; OR BUSINESS INTERRUPTION)  HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT,  STRICT LIABILITY,  OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ######################################################################
#
# ----------------------------------------------------------------------
# - shell --------------------------------------------------------------
# ----------------------------------------------------------------------
#
SHELL        = /bin/sh
#
CD           = cd
CP           = cp
LN_S         = ln -s
MKDIR        = mkdir
RM           = /bin/rm -f
TOUCH        = touch
#
# ----------------------------------------------------------------------
# - Platform identifier ------------------------------------------------
# ----------------------------------------------------------------------
#
ARCH         = \$(arch)
#
# ----------------------------------------------------------------------
# - HPL Directory Structure / HPL library ------------------------------
# ----------------------------------------------------------------------
#
TOPdir       = ../../..
INCdir       = \$(TOPdir)/include
BINdir       = \$(TOPdir)/bin/\$(ARCH)
LIBdir       = \$(TOPdir)/lib/\$(ARCH)
#
HPLlib       = \$(LIBdir)/libhpl.a
#
# ----------------------------------------------------------------------
# - MPI directories - library ------------------------------------------
# ----------------------------------------------------------------------
# MPinc tells the  C  compiler where to find the Message Passing library
# header files,  MPlib  is defined  to be the name of  the library to be
# used. The variable MPdir is only used for defining MPinc and MPlib.
#
MPdir        = /opt/openmpi
MPinc        = -I\$(MPdir)/include
MPlib        = \$(MPdir)/lib/libmpi.so
#
# ----------------------------------------------------------------------
# - Linear Algebra library (AMD BLIS or BLAS or VSIPL) -----------------------------
# ----------------------------------------------------------------------
# LAinc tells the  C  compiler where to find the Linear Algebra  library
# header files,  LAlib  is defined  to be the name of  the library to be
# used. The variable LAdir is only used for defining LAinc and LAlib.
#
LAdir        = $BLIS_DIR
LAinc        = -I\$(LAdir)/include
LAlib        = \$(LAdir)/lib/$LIB_BLIS
#
# ----------------------------------------------------------------------
# - F77 / C interface --------------------------------------------------
# ----------------------------------------------------------------------
# You can skip this section  if and only if  you are not planning to use
# a  BLAS  library featuring a Fortran 77 interface.  Otherwise,  it  is
# necessary  to  fill out the  F2CDEFS  variable  with  the  appropriate
# options.  **One and only one**  option should be chosen in **each** of
# the 3 following categories:
#
# 1) name space (How C calls a Fortran 77 routine)
#
# -DAdd_              : all lower case and a suffixed underscore  (Suns,
#                       Intel, ...),                           [default]
# -DNoChange          : all lower case (IBM RS6000),
# -DUpCase            : all upper case (Cray),
# -DAdd__             : the FORTRAN compiler in use is f2c.
#
# 2) C and Fortran 77 integer mapping
#
# -DF77_INTEGER=int   : Fortran 77 INTEGER is a C int,         [default]
# -DF77_INTEGER=long  : Fortran 77 INTEGER is a C long,
# -DF77_INTEGER=short : Fortran 77 INTEGER is a C short.
#
# 3) Fortran 77 string handling
#
# -DStringSunStyle    : The string address is passed at the string loca-
#                       tion on the stack, and the string length is then
#                       passed as  an  F77_INTEGER  after  all  explicit
#                       stack arguments,                       [default]
# -DStringStructPtr   : The address  of  a  structure  is  passed  by  a
#                       Fortran 77  string,  and the structure is of the
#                       form: struct {char *cp; F77_INTEGER len;},
# -DStringStructVal   : A structure is passed by value for each  Fortran
#                       77 string,  and  the  structure is  of the form:
#                       struct {char *cp; F77_INTEGER len;},
# -DStringCrayStyle   : Special option for  Cray  machines,  which  uses
#                       Cray  fcd  (fortran  character  descriptor)  for
#                       interoperation.
#
F2CDEFS      = -Dadd__ -DF77_INTEGER=int -DStringSunStyle
#
# ----------------------------------------------------------------------
# - HPL includes / libraries / specifics -------------------------------
# ----------------------------------------------------------------------
#
HPL_INCLUDES = -I\$(INCdir) -I\$(INCdir)/\$(ARCH) \$(LAinc) \$(MPinc)
HPL_LIBS     = \$(HPLlib) \$(LAlib) \$(MPlib) -lm
#
# - Compile time options -----------------------------------------------
#
# -DHPL_COPY_L           force the copy of the panel L before bcast;
# -DHPL_CALL_CBLAS       call the cblas interface;
# -DHPL_CALL_VSIPL       call the vsip  library;
# -DHPL_DETAILED_TIMING  enable detailed timers;
#
# By default HPL will:
#    *) not copy L before broadcast,
#    *) call the Fortran 77 BLAS interface
#    *) not display detailed timing information.
#
HPL_OPTS     = -DHPL_PROGRESS_REPORT
#
# ----------------------------------------------------------------------
#
HPL_DEFS     = \$(F2CDEFS) \$(HPL_OPTS) \$(HPL_INCLUDES)
#
# ----------------------------------------------------------------------
# - Compilers / linkers - Optimization flags ---------------------------
# ----------------------------------------------------------------------
#
CC           = gcc
CCNOOPT      = \$(HPL_DEFS)
CCFLAGS      = \$(HPL_DEFS) -fomit-frame-pointer -O3 -funroll-loops -march=znver2 -fopenmp -ljemalloc -I$HPL_DIR/jemalloc/include/jemalloc
#
LINKER       = gcc
LINKFLAGS    = -L$HPL_DIR/jemalloc/lib \$(CCFLAGS)
#
ARCHIVER     = ar
ARFLAGS      = r
RANLIB       = echo
#
# ----------------------------------------------------------------------" > Make.zen2
    make clean
    make arch=zen2
	cd $HPL_DIR
    cd work
    cp ../hpl/bin/zen2/xhpl .
	cd $HPL_DIR
}

create_script_generate_hpl_files()
{
	cd $HPL_DIR/work

echo "#!/bin/bash
#
# Run the appfile as root, which specifies 16 processes, each with its own CPU binding for OpenMP

# set the CPU governor to performance
cpupower frequency-set -g performance

# Verify the knem module is loaded
lsmod | grep -q knem
if [ \$? -eq 1 ]; then
    echo \"Loading knem module...\"
    sudo modprobe -v knem
fi

mpi_options=\"--allow-run-as-root --mca mpi_leave_pinned 1 --bind-to none --report-bindings --mca btl self,vader --map-by ppr:1:l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores\"
sudo /opt/openmpi/bin/mpirun \$mpi_options -app ./appfile_ccx" > run_hpl_ccx.sh
chmod +x run_hpl_ccx.sh

echo "#!/bin/bash
#
# Bind memory to node \$1 and four child threads to CPUs specified in \$2
#
# Kernel parallelization is performed at the 2nd innermost loop (IC)

export LD_LIBRARY_PATH=$BLIS_DIR/lib:\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/openmpi/lib:\$LD_LIBRARY_PATH


export OMP_NUM_THREADS=\$3
export GOMP_CPU_AFFINITY=\"\$2\"
export OMP_PROC_BIND=TRUE

# BLIS_JC_NT=1 (No outer loop parallelization):
export BLIS_JC_NT=1
# BLIS_IC_NT= #cores/ccx (# of 2nd level threads – one per core in the shared L3 cache domain):
export BLIS_IC_NT=\$OMP_NUM_THREADS
# BLIS_JR_NT=1 (No 4th level threads):
export BLIS_JR_NT=1
# BLIS_IR_NT=1 (No 5th level threads):
export BLIS_IR_NT=1

numactl --membind=\$1 ./xhpl" > xhpl_ccx.sh
chmod +x xhpl_ccx.sh

generate_hpl_files_python="generate_hpl_files_v1.0.4.py"
echo "creating $generate_hpl_files_python..."
echo "#!/usr/bin/env python
import math
import psutil
import subprocess
import argparse

# Modify the following three variables as appropriate:
physical_cores_per_ccx = 4 # This is specific to your AMD EPYC CPU
percent_mem = 84.64 # Specify the portion of memory to use
NB = 224 # HPL block size

appfile_name = 'appfile_ccx'

# CONSTANTS:
ONE_GIBIBYTE = 1024**3
DP_SIZE = 8
EOL = '\n'

# parse command line arguments for:
#     physical_cores_per_ccx: the number of physical cores per ccx
#     percent_mem: % of memory used for HPL
#     NB: block size
def parse_command_line_args(parser):
    global physical_cores_per_ccx, percent_mem, NB, mem_GiB

    # add arguments:
    parser.add_argument('--nb', '-nb', help='set block size (int)', type=int)
    parser.add_argument('--percent_mem', '-pm', help='specify percentage memory to use (float)', type=float)
    parser.add_argument('--physical_cores_per_ccx', '-pcpc', help='number of physical cores per ccx (int)', type=int)
    parser.add_argument('--memory_GiB', '-mgb', help='DRAM memory in GiB (int)', type=int)

    # read arguments from command line:
    args = parser.parse_args()
    if args.nb:
        NB = args.nb
        print('Commmand line argument supplied: The block size (NB) is now set to: ' + str(NB))
    if args.percent_mem:
        percent_mem = args.percent_mem
        print('Commmand line argument supplied: The percentage of memory to be used is now set to: ' + str(percent_mem))
    if args.physical_cores_per_ccx:
        physical_cores_per_ccx = args.physical_cores_per_ccx
        print('Commmand line argument supplied: The number of physical cores per CCX is now set to: ' + str(physical_cores_per_ccx))
    if args.memory_GiB:
        mem_GiB = args.memory_GiB
        print('Commmand line argument supplied: The total system memory (GiB) is now set to: ' + str(mem_GiB))

def generate_appfile():
    result = ''
    numa_node = ccx_nbr = 0
    prefix = '-np 1 ./xhpl_ccx.sh '
    postfix = ' ' + str( physical_cores_per_ccx )
    for pcore in range(0, physical_cores, physical_cores_per_ccx):
        xhpl_aff = str(pcore) + '-' + str(pcore + physical_cores_per_ccx - 1)
        numa_node = int( ccx_nbr / ccx_per_numa_node )
        result += prefix + str(numa_node) + ' ' + xhpl_aff + postfix + EOL
        ccx_nbr += 1  
    return result
    
def generate_appfile_logical_cores():
    result = ''
    numa_node = ccx_nbr = 0
    prefix = '-np 1 ./xhpl_ccx.sh '
    postfix = ' ' + str( physical_cores_per_ccx )
    for pcore in range(0, physical_cores, physical_cores_per_ccx):
        xhpl_aff = str(pcore) + '-' + str(pcore + physical_cores_per_ccx - 1) + ',' + \\
            str(pcore + physical_cores) + \\
            '-' + str(pcore + physical_cores + physical_cores_per_ccx - 1)
        numa_node = int( ccx_nbr / ccx_per_numa_node )
        result += prefix + str(numa_node) + ' ' + xhpl_aff + postfix + EOL
        ccx_nbr += 1  
    return result

def generate_hpl_dat(a_n, a_nb, a_p, a_q):
    result = '''HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out     output file name (if any)
6           device out (6=stdout,7=stderr,file)
1           # of problems sizes (N)
nnnnnn      Ns
1           # of NBs
nbnbnb      # of problems sizes (N)
0           MAP process mapping (0=Row-,1=Column-major)
1           # of process grids (P x Q)
pppppp      Ps
qqqqqq      Qs
16.0        threshold
1           # of panel fact<
2           PFACTs (0=left, 1=Crout, 2=Right)
1           # of recursive stopping criterium
4           NBMINs (>= 1)
1           # of panels in recursion
2           NDIVs
1           # of recursive panel fact.
1           RFACTs (0=left, 1=Crout, 2=Right)
1           # of broadcast
1           BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1           # of lookahead depth
1           DEPTHs (>=0)
2           SWAP (0=bin-exch,1=long,2=mix)
64          swapping threshold
0           L1 in (0=transposed,1=no-transposed) form
0           U in (0=transposed,1=no-transposed) form
1           Equilibration (0=no,1=yes)
8           memory alignment in double (> 0)'''.replace('nnnnnn', str(a_n) + ' '*(6 - len(str(a_n)) ))
    result = result.replace('nbnbnb',str(a_nb) + ' '*(6 - len(str(a_nb))))
    result = result.replace('pppppp',str(a_p) + ' '*(6 - len(str(a_p))))
    result = result.replace('qqqqqq',str(a_q) + ' '*(6 - len(str(a_q))))
    return result

def get_numa_node_count():
    return int(subprocess.check_output('numactl --hardware | grep \"available:\" | awk \'{print \$2}\'', shell=True))
    
def get_socket_count():
    return int( subprocess.check_output( 'lscpu | grep \"Socket(s)\" | awk \'{print \$2}\'', shell=True ))

def get_numa_node_min_mem_GiB():
    return float(subprocess.check_output('numactl -H | grep size: | awk \'{print \$4}\' | sort -n | head -1', shell=True)) / 1024

def get_physical_cores_per_socket():
    return int(subprocess.check_output( 'lscpu | grep \"Core(s) per socket\" | awk \'{print \$4}\'', shell=True ))
    
def get_physical_cores_total():
    return get_socket_count() * get_physical_cores_per_socket()

def get_mem_GiB():
    return int( float(psutil.virtual_memory()[0]) / ONE_GIBIBYTE )

def calculate_N():
    # Calculate N based upon the amount of system memory and the percentage
    # specified to be used:
    global mem_GiB, ONE_GIBIBYTE, DP_SIZE, percent_mem, NB
    N = math.sqrt((mem_GiB * ONE_GIBIBYTE / DP_SIZE) * (percent_mem/100))
    # Calculate the number of blocks that can be used:
    nbr_blocks = int(N / NB)
    # Recalculate N to be the product of the number of block and block size
    N = NB * nbr_blocks
    return N
    
### Main program ###

numa_node_count = get_numa_node_count()
print( 'The NUMA node count is ' + str( numa_node_count ))
socket_count = get_socket_count()
print( 'The system socket count is ' + str(socket_count) )
numa_min_mem = get_numa_node_min_mem_GiB()
print( 'The lowest NUMA node memory amount (GiB) is ' + str( numa_min_mem ) )
if numa_min_mem == 0:
    print( '*** One or more of your NUMA nodes do not have memory installed! ***' )
    print( '*** This script does not handle that configuration.              ***' )
    print( '*** You will need to either install memory on all NUMA nodes or  ***' )
    print( '*** you will have to manually set up the run. Exiting script...  ***' )
    quit()
physical_cores = get_physical_cores_total()
print( 'The number of physical cores detected: ' + str( physical_cores ))
mem_GiB = get_mem_GiB()
mem_GiB_min = int( numa_node_count * numa_min_mem )
if mem_GiB_min < mem_GiB:
    print( 'The calculated minimum NUMA node memory amount was ' + str( mem_GiB_min ) + ' GiB.')
    print( 'The adjusted memory amount is ' + str( mem_GiB_min ) + ' GiB versus detected total of ' + str( mem_GiB ) + ' GiB.')
    mem_GiB = mem_GiB_min
else:
    print( 'The calculated minimum NUMA node memory amount was ' + str( mem_GiB_min ) + ' GiB.')
    print( 'Using the original detected memory amount of ' + str( mem_GiB ) + ' GiB.')
ccx_total = physical_cores / physical_cores_per_ccx
ccx_per_numa_node = ccx_total / numa_node_count
nbr_of_processes = ccx_total
if nbr_of_processes == 4:
    p = 2
    q = 2
elif nbr_of_processes == 8:
    p = 2
    q = 4
elif nbr_of_processes == 16:
    p = 4
    q = 4
elif nbr_of_processes == 24:
    p = 4
    q = 6
elif nbr_of_processes == 32:
    p = 4
    q = 8

parse_command_line_args( argparse.ArgumentParser(description='HPL configuration file generator.') )
N = calculate_N()
print( 'The optimal N setting for your SUT is ' + str( N ) + EOL )

file = open('HPL.dat','w')
hpl_txt = generate_hpl_dat(N, NB, p, q)
file.write( hpl_txt )
print( 'HPL.dat:' )
print( hpl_txt )
file.close()

print

file = open(appfile_name,'w')
appfile_txt = generate_appfile()
file.write( appfile_txt  )
print( appfile_name + ':')
print( appfile_txt )
file.close()" > $generate_hpl_files_python
    echo "Finished creating $generate_hpl_files_python."
    chmod +x $generate_hpl_files_python
    python3 ./$generate_hpl_files_python
}

create_test_script()
{
    echo "#/bin/bash
cd hpl/work
./run_hpl_ccx.sh" >$top/run_hpl_test.sh
chmod +x $top/run_hpl_test.sh
}

create_vim_settings()
{
    VIMRC="$HOME/.vimrc"
    if [ -e $VIMRC ]; then
        echo "$VIMRC already exists. Skipping modifications."
    else
    echo "set mouse=a
    set number
    set wrap"  > $VIMRC
    fi
}

prep_ssh()
{
    SSHD_CONFIG=/etc/ssh/sshd_config
    RESTART_SSHD=false
    # permit root ssh login:
    PERMIT_ROOT_LOGIN="PermitRootLogin yes"
    if grep -i "$PERMIT_ROOT_LOGIN" $SSHD_CONFIG; then
        echo "$PERMIT_ROOT_LOGIN found."
    else
        echo "PermitRootLogin yes" >> $SSHD_CONFIG
        RESTART_SSHD=true
    fi
    # reduce ssh disconnects when idle:
    CLIENT_ALIVE_INTERVAL="ClientAliveInterval 120"
    if grep -i "$CLIENT_ALIVE_INTERVAL" $SSHD_CONFIG; then
        echo "$CLIENT_ALIVE_INTERVAL found in $SSHD_CONFIG"
    else
        echo $CLIENT_ALIVE_INTERVAL >> $SSHD_CONFIG
        RESTART_SSHD=true
    fi
    if [ $RESTART_SSHD == true ]; then
        echo "Restarting sshd..."
        systemctl restart sshd
        echo "sshd restarted."
    fi
}

track_history()
{
	# track history from all ssh instances:
	shopt -s histappend
}

make_test_run()
{
	echo "You have selected a test run."
	echo "The top directory is $top"
	echo "The hpl installation directory is $HPL_DIR"
	echo
	get_sysinfo
	echo
	echo "Place your debug statements here."
	echo
	echo "Exiting script."
	exit 0
}

########################################
### MAIN SCRIPT ###
########################################

parse_args "$@"
if [ $exit_on_error == true ]; then
	echo Setting exit on error.
	set -e
fi
if [ $test_run == true ]; then
	make_test_run
fi
if [ $remove_hpl_dir == true ]; then
	echo Removing the existing hpl directory...
	rm -rf $HPL_DIR
fi

rm -rf $top/xhpl && wget -P $top https://tools.258tiao.com/tools/hpl/xhpl.tar.gz &&tar -zvxf xhpl.tar.gz &&chmod +x $top/xhpl
create_test_script
rm -rf $HPL_DIR
mkdir $HPL_DIR
cd $HPL_DIR
mkdir work



if [ $work_dir_only == true ]; then
	set_cpu_performance
	get_sysinfo
	move_xhpl_bin
	install_amd_aocl
	create_script_generate_hpl_files
elif [ $openmpi_only == true ]; then
	build_openmpi
elif [ $knem_only == true ]; then
	install_knem
else
	enable_ubuntu_repositories
	install_dependencies
	purge_packages
	set_cpu_performance
	get_sysinfo
	install_jemalloc
	set_build_flags
	install_knem
	#build_amd_blis
	install_amd_aocl
	build_openmpi
	if [ $build_xhpl == true ]; then
		build_hpl
		backup_xhpl_bin
	else
		move_xhpl_bin
	fi
	create_script_generate_hpl_files
#	create_vim_settings
#没必要设置	prep_ssh
#	track_history
	echo "------------------- 测试程序安装完成 ------------------"
        echo "---------- 执行./run_hpl_test.sh等待结果即可 ----------"
	echo "-------------------------------------------------------"
	echo "---- The HPL test software installation complted ! ----"
	echo "------------ Run ./run_hpl_test.sh --------------------"
fi
