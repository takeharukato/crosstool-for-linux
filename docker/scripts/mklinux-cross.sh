#!/bin/bash
#
# -*- coding:utf-8 mode: bash-mode -*-
#
# Linux用クロス開発環境構築スクリプト
#
# Copyright (C) 1998-2022 by Project HOS
# http://sourceforge.jp/projects/hos/
#

# コンパイル対象CPU
if [ "x${TARGET_CPUS}" = "x" ]; then
	TARGET_CPUS="i386 riscv32 riscv64 mips mipsel microblaze microblazeel arm armhw"
	TARGET_CPUS="riscv64"
	echo "No target cpus specified, build all: ${TARGET_CPUS}"
else
	echo "Target CPUS: ${TARGET_CPUS}"
fi


#
#アーカイブ展開時のディレクトリ名
#
declare -A tool_names=(
	["binutils"]="binutils-2.38"
	["gcc"]="gcc-11.2.0"
	["glibc"]="glibc-2.34"
	["gdb"]="gdb-11.2"
	["qemu"]="qemu-6.2.0"
	["kernel"]="linux-5.14.7"
	)
#
#アーカイブファイル名
#
declare -A tool_archives=(
	["binutils-2.38"]="binutils-2.38.tar.gz"
	["gcc-11.2.0"]="gcc-11.2.0.tar.gz"
	["glibc-2.34"]="glibc-2.34.tar.gz"
	["gdb-11.2"]="gdb-11.2.tar.gz"
	["qemu-6.2.0"]="qemu-6.2.0.tar.xz"
	["linux-5.14.7"]="linux-5.14.7.tar.gz"
	)

#
#URL
#
declare -A tool_urls=(
	["binutils-2.38"]="https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.gz"
	["gcc-11.2.0"]="https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.gz"
	["glibc-2.34"]="https://ftp.gnu.org/gnu/libc/glibc-2.34.tar.gz"
	["gdb-11.2"]="https://ftp.gnu.org/gnu/gdb/gdb-11.2.tar.gz"
	["qemu-6.2.0"]="https://download.qemu.org/qemu-6.2.0.tar.xz"
	["linux-5.14.7"]="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.14.7.tar.gz"
	)

#
# QEmuのターゲット
#
declare -A qemu_targets=(
	["i386"]="i386-softmmu,i386-linux-user"
	["riscv32"]="riscv32-softmmu,riscv32-linux-user"
	["riscv64"]="riscv64-softmmu,riscv64-linux-user"
	["mips"]="mips-softmmu,mips-linux-user"
	["mipsel"]="mipsel-softmmu,mipsel-linux-user"
	["arm"]="arm-softmmu,arm-linux-user"
	["armhw"]="arm-softmmu,arm-linux-user"
	["microblaze"]="microblaze-softmmu,microblaze-linux-user"
	["microblazeel"]="microblazeel-softmmu,microblazeel-linux-user"
	)

#
# カーネルのcpu名
#
declare -A kern_cpus=(
    ["aarch64"]="arm64"
    ["arm"]="arm"
    ["armhw"]="arm"
    ["microblaze"]="microblaze"
    ["microblazeel"]="microblaze"
    ["mips"]="mips"
    ["mipsel"]="mips"
    ["powerpc"]="powerpc"
    ["riscv32"]="riscv"
    ["riscv64"]="riscv"
    ["sh4"]="sh"
    ["sparc64"]="sparc64"
)

#
# カーネルのコンフィグレーション名
#
declare -A kern_configs=(
    ["powerpc"]="pmac32_defconfig"
    ["sh4"]="sh7770_generic_defconfig"
    ["sparc64"]="sparc64_defconfig"
)

#
# ライブラリディレクトリ
#
declare -A lib_cpus=(
    ["aarch64"]="lib64"
    ["arm"]="lib"
    ["armhw"]="lib"
    ["microblaze"]="lib"
    ["microblazeel"]="lib"
    ["mips"]="lib"
    ["mipsel"]="lib"
    ["powerpc"]="lib"
    ["riscv32"]="lib"
    ["riscv64"]="lib64"
    ["sh4"]="lib"
    ["sparc64"]="lib"
)

#
# QEmuのCPU名
#
declare -A qemu_cpus=(
	["i386"]="i386"
	["riscv32"]="riscv32"
	["riscv64"]="riscv64"
	["mips"]="mips"
	["mipsel"]="mipsel"
	["arm"]="arm"
	["armhw"]="arm"
	["microblaze"]="microblaze"
	["microblazeel"]="microblazeel"
	)

#
# QEmuの起動オプション
#
declare -A qemu_opts=()

#
# ターゲット名
#
declare -A cpu_target_names=(
	["i386-linux"]="i386-unknown-linux-gnu"
	["riscv32-linux"]="riscv32-unknown-linux-gnu"
	["riscv64-linux"]="riscv64-unknown-linux-gnu"
	["mips-linux"]="mips-unknown-linux-gnu"
	["mipsel-linux"]="mipsel-unknown-linux-gnu"
	["arm-linux"]="arm-linux-gnueabi"
	["armhw-linux"]="arm-linux-gnueabihf"
	["microblaze-linux"]="microblaze-unknown-linux-gnu"
	["microblazeel-linux"]="microblazeel-unknown-linux-gnu"
)

#
# ターゲット用cflags
#
declare -A cpu_target_cflags=()

#
# リモートGDB接続先ポート
#
MKCROSS_REMOTE_GDB_PORT=1234

#
#スクリプト配置先ディレクトリ
#
MKCROSS_SCRIPTS_DIR=$(cd $(dirname $0);pwd)
#
#パッチ配置先ディレクトリ
#
MKCROSS_PATCHES_DIR=${MKCROSS_SCRIPTS_DIR}/patches
#
#vscodeのテンプレート
#
MKCROSS_VSCODE_TEMPL_DIR=${MKCROSS_SCRIPTS_DIR}/vscode
#
#インストール先
#
CROSS_PREFIX="/opt/cross/gcc"
# lmodのモジュールファイル
LMOD_MODULE_DIR="${CROSS_PREFIX}/lmod/modules"
# シェルの初期化ファイル
SHELL_INIT_DIR="${CROSS_PREFIX}/etc/shell/init"
# lmodのモジュールファイル
LMOD_MODULE_DIR="${CROSS_PREFIX}/lmod/modules"
# シェルの初期化ファイル
SHELL_INIT_DIR="${CROSS_PREFIX}/etc/shell/init"
# Hos開発ユーザ名
DEVLOPER_NAME="devuser"
# Hos開発ディレクトリ
DEVLOPER_HOME="/home/${DEVLOPER_NAME}"

# コンパイル対象CPUの配列
targets=(`echo ${TARGET_CPUS}`)

# コンパイル作業のトップディレクトリ
TOP_DIR=`pwd`

# ダウンロードアーカイブ格納ディレクトリ
DOWNLOADS_DIR=${TOP_DIR}/downloads

# ターゲット用の最適化フラグ
MKCROSS_OPT_FLAGS_FOR_TARGET="-g -O2 -finline-functions"

# glibcサポートカーネル版数
MKCROSS_GLIBC_ENABLE_KERNEL=3.2

#
#ツール名を取得する
# get_tool_name CPU名 ツール種別
#
get_tool_name(){
	local cpu
	local tool
	local tool_key
	local archive_key
	local rc

	cpu=$1
	tool=$2

	rc="None"

	if [ "x${tool_names[${tool}]}" != "x" ]; then
	rc="${tool_names[${tool}]}"
	fi

	#
	# CPU固有
	#
	tool_key="${cpu}-${tool}"

	if [ "x${tool_names[${tool_key}]}" != "x" ]; then
		rc="${tool_names[${tool_key}]}"
	fi

	echo "${rc}"
}

#
#アーカイブ名を取得する
# get_archive_name CPU名 ツール種別
#
get_archive_name(){
	local cpu
	local tool
	local tool_key
	local archive_key
	local archive
	local rc

	cpu=$1
	tool=$2

	rc="None"

	if [ "x${tool_names[${tool}]}" != "x" ]; then
	archive_key="${tool_names[${tool}]}"
	archive="${tool_archives[${archive_key}]}"
		if [ "x${archive}" != "x" ]; then
			rc="${archive}"
		fi
	fi

	#
	# CPU固有
	#
	tool_key="${cpu}-${tool}"

	if [ "x${tool_names[${tool_key}]}" != "x" ]; then
		archive_key="${tool_names[${tool_key}]}"
		archive="${tool_archives[${archive_key}]}"
		if [ "x${archive}" != "x" ]; then
			rc="${archive}"
		fi
	fi

	echo "${rc}"
}

download_archives(){
	local tool
	local cpu
	local tool_key
	local archive_key
	local url

	mkdir -p "${DOWNLOADS_DIR}"

	pushd "${DOWNLOADS_DIR}"

	for tool in "binutils" "gcc" "glibc" "gdb" "kernel" "qemu"
	do
	#
	# 共通アーカイブのダウンロード
	#
		if [ "x${tool_names[${tool}]}" != "x" ]; then
			archive_key="${tool_names[${tool}]}"
			url="${tool_urls[${archive_key}]}"
			if [ "x${url}" != "x" ]; then
				echo "download ${tool} from ${url}"
				curl -s -OL "${url}"
			fi
		fi

	#
	# CPU固有のアーカイブをダウンロード
	#
		for cpu in "${targets[@]}"
		do
			tool_key="${cpu}-${tool}"
			if [ "x${tool_names[${tool_key}]}" != "x" ]; then
				archive_key="${tool_names[${tool_key}]}"
				url="${tool_urls[${archive_key}]}"
				if [ "x${url}" != "x" ]; then
					echo "${cpu} uses ${tool} from ${url}"
					curl -s -OL "${url}"
				fi
			fi
		done
	done

	popd
}

#
#環境準備
#
prepare(){

	apt-get update;

	apt-get install -y sudo

	apt-get install -y emacs vim nano

	apt-get install -y device-tree-compiler

	apt-get install -y language-pack-ja-base language-pack-ja

	apt-get install -y git ninja-build python3 python3-dev swig

	apt-get install -y autotools-dev curl python3 libmpc-dev \
	libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
	libtool patchutils bc zlib1g-dev libexpat-dev lmod

	apt-get install -y m4 automake autoconf gettext libtool \
	 libltdl-dev gperf autogen guile-3.0 texinfo texlive  \
         python3-sphinx git openssh-server diffutils patch rsync

	apt-get install -y giflib-tools libpng-dev libtiff-dev libgtk-3-dev \
	libncursesw6 libncurses5-dev libncursesw5-dev libgnutls30 nettle-dev \
	libgcrypt20-dev libsdl2-dev libguestfs-tools python3-brlapi \
	bluez-tools bluez-hcidump bluez libusb-dev libcap-dev libcap-ng-dev \
	libiscsi-dev  libnfs-dev libguestfs-dev libcacard-dev liblzo2-dev \
	liblzma-dev libseccomp-dev libssh-dev libssh2-1-dev libglu1-mesa-dev \
	mesa-common-dev freeglut3-dev ngspice-dev libattr1-dev libaio-dev \
	libtasn1-dev google-perftools libvirglrenderer-dev multipath-tools \
	libsasl2-dev libpmem-dev libudev-dev libcapstone-dev librdmacm-dev \
	libibverbs-dev libibumad-dev libvirt-dev libffi-dev libbpfcc-dev \
	libdaxctl-dev


	apt-get -y clean

	rm -rf /var/lib/apt/lists/*
}

#
# cross_binutils ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
cross_binutils(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/binutils"
	local build_dir="$5/binutils"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="binutils"
	local sim_arg
	local archive
	local tool
	local rmfile
	local build

	build=`gcc -dumpmachine`

	echo "@@@ binutils @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	#
	# Simulator
	#
	sim_arg=""
	case "${cpu}" in
		microblaze | microblazeel)
			sim_arg="--disable-sim"
			;;
	esac

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	pushd "${build_dir}"
	${src_dir}/${tool}/configure                              \
		  --prefix="${prefix}"                            \
		  --build=${build}                              \
		  --host=${build}                               \
		  --target=${target}                            \
		  --with-local-prefix="${prefix}/${target}"       \
		  --disable-shared                                \
		  --disable-werror                                \
		  --disable-nls                                   \
		  ${sim_arg}                                      \
		  --with-sysroot="${sys_root}"
	make -j`nproc`
	make install
	popd

	#
	#.laファイルを削除する
	#
	echo "Remove .la files"

	find "${prefix}" -name '*.la'|while read rmfile
	do
		echo "Remove ${rmfile}"
		rm -f "${rmfile}"
	done

	#
	#ビルド環境のツールと混在しないようにする
	#
	echo "Remove addr2line ar as c++filt elfedit gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip on ${prefix}/bin"

	for rmfile in addr2line ar as c++filt elfedit gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip
	do
		if [ -f "${prefix}/bin/${rmfile}" ]; then
			rm -f "${prefix}/bin/${rmfile}"
		fi
	done
}

#
# cross_gcc_stage1 ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
cross_gcc_stage1(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/gcc_stage1"
	local build_dir="$5/gcc_stage1"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="gcc"
	local rmfile
	local tool
	local archive
	local target_cflags
	local build

	build=`gcc -dumpmachine`

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	echo "@@@ gcc_stage1 @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Target Cflags:${target_cflags}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	pushd "${build_dir}"
	env CFLAGS_FOR_TARGET="${MKCROSS_OPT_FLAGS_FOR_TARGET} ${target_cflags}" \
	${src_dir}/${tool}/configure                            \
		--prefix="${prefix}"                            \
		--target=${target}                            \
		--build=${build}                              \
		--host=${build}                               \
		--with-local-prefix="${prefix}/${target}"       \
		--disable-shared                                \
		--disable-werror                                \
		--disable-nls                                   \
		--enable-languages=c                            \
		--disable-bootstrap                             \
		--disable-werror                                \
		--disable-shared                                \
		--disable-multilib                              \
		--with-newlib                                   \
		--without-headers                               \
		--disable-lto                                   \
		--disable-threads                               \
		--disable-decimal-float                         \
		--disable-libatomic                             \
		--disable-libitm                                \
		--disable-libquadmath                           \
		--disable-libvtv                                \
		--disable-libcilkrts                            \
		--disable-libmudflap                            \
		--disable-libssp                                \
		--disable-libmpx                                \
		--disable-libgomp                               \
		--disable-libsanitizer                          \
		--with-sysroot="${sys_root}"

	#
	#make allを実行できるだけのヘッダやC標準ライブラリがないため部分的に
	#コンパイラの構築を行う
	#
	#crosstool-ng-1.19.0のscripts/build/cc/gcc.shを参考にした
	#

	#
	#cpp/libiberty(GNU共通基盤ライブラリ)の構築
	#
	make configure-gcc configure-libcpp configure-build-libiberty
	make -j`nproc` all-libcpp all-build-libiberty

	#
	#libdecnumber/libbacktrace(gccの動作に必須なライブラリ)の構築
	#
	make configure-libdecnumber
	make -j`nproc` -C libdecnumber libdecnumber.a
	make configure-libbacktrace
	make -j`nproc` -C libbacktrace

	#
	#gcc(Cコンパイラ)とアーキ共通基盤ライブラリ(libgcc)の構築
	#
	make -C gcc libgcc.mvars
	make -j`nproc` all-gcc all-target-libgcc
	make install-gcc install-target-libgcc

	popd

	#
	#.laファイルを削除する
	#
	echo "Remove .la files"

	find ${prefix} -name '*.la'|while read rmfile
	do
		echo "Remove ${rmfile}"
		rm -f ${rmfile}
	done

	#
	#ホストのgccとの混乱を避けるため以下を削除
	#
	echo "Remove cpp gcc gcc-ar gcc-nm gcc-ranlib gcov ${target}-cc on ${prefix}/bin"
	for rmfile in cpp gcc gcc-ar gcc-nm gcc-ranlib gcov ${target}-cc
	do
		if [ -f "${prefix}/bin/${rmfile}" ]; then
			rm -f "${prefix}/bin/${rmfile}"
		fi
	done
}

#
# gen_kernel_headers ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
gen_kernel_headers(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/kernel_header"
	local build_dir="$5/kernel_header"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="kernel"
	local rmfile
	local tool
	local archive
	local target_cflags
	local kern_config
	local kern_cpu

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	kern_config="${kern_configs[${cpu}]}"
	if [ "x${kern_config}" = "x" ]; then
	    kern_config="defconfig"
	fi

	kern_cpu="${kern_cpus[${cpu}]}"
	if [ "x${kern_cpu}" = "x" ]; then
	    kern_cpu="${cpu}"
	fi

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	echo "@@@ kernel_header @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Tool: ${tool}"
	echo "Target Cflags:${target_cflags}"
	echo "Kernel CPU:${kern_cpu}"
	echo "Kernel Config:${kern_config}"

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	pushd "${src_dir}"
	tar xf ${DOWNLOADS_DIR}/${archive}
	popd

	pushd "${src_dir}/${tool}"

	#カーネルのコンフィグレーションを設定
    	make ARCH="${kern_cpu}" HOSTCC="gcc" "${kern_config}"

	#カーネルヘッダのインストール
	make ARCH="${kern_cpu}" HOSTCC="gcc" \
	     INSTALL_HDR_PATH="${sys_root}/usr" V=1 headers_install

	popd
}

#
# gen_glibc_headers ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
gen_glibc_headers(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/glibc_header"
	local build_dir="$5/glibc_header"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="glibc"
	local rmfile
	local tool
	local archive
	local target_cflags
	local build

	build=`gcc -dumpmachine`

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	echo "@@@ glibc header @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Tool: ${tool}"
	echo "Target Cflags:${target_cflags}"

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	pushd "${build_dir}"

	#
	# configureの設定
	#
	# CFLAGS="-O -finline-functions"
	#   コンパイルオプションに -finline-functions
	#   を指定する(インライン関数が使用できることを前提にglibcが
	#   書かれているため, -Oを指定した場合、 -finline-functionsがないと
	#   コンパイルできない). -O3を指定した場合のライブラリを使用すると
	#   プログラムが動作しないことがあったため, -Oでコンパイルする。
	# --prefix=${prefix}
	#          ${prefix}配下にインストールする
	# --host=${target}
	#        ${target}で指定されたマシン上で動作するlibcを生成する
	# --target=${target}
	#        ${target}で指定されたマシン上で動作するバイナリを出力する
	#        ツール群を作成する
	#  --prefix=/usr
	#           /usr/include,/usr/lib64,/usr/lib配下にヘッダ・ライブラリ
	#           をインストールする
	#  --without-cvs
	#          CVSからのソース獲得を行わない
	#  --disable-profile
	#          gprof対応版ライブラリを生成しない
	#  --without-gd
	#          GDグラフックライブラリが必要なツールを生成しない
	#  --disable-debug
	#          デバッグオプションを指定しない
	#  --with-headers=${SYSROOT}/usr/include
	#          ${SYSROOT}/usr/include配下のヘッダを参照する
	#  --enable-add-ons=nptl,libidn
	#          NPTLをスレッドライブラリに, libidn国際ドメイン名ライブラリ
	#          を構築する(実際にはスタートアップルーチンのみ構築)
	#  --enable-kernel=${GLIBC_ENABLE_KERNEL}
	#          動作可能なカーネルの範囲（動作可能な範囲で最も古いカーネルの
	#          版数を指定する(上記のGLIBC_ENABLE_KERNELの設定値説明を参照)
	#  --disable-nscd
	#          ヘッダの生成のみを行うため, ncsdのコンパイルをしない
	#  --disable-obsolete-rpc
	#          ヘッダの生成のみを行うため, 廃止されたrpcライブラリを生成しない
	#  --without-selinux
	#          ターゲット用のlibselinuxがないため, selinux対応無しでコンパイルする
	#  --disable-mathvec
	#          mathvecを作成しない(libmが必要となるため)
	CFLAGS="-O -finline-functions"                 \
	      ${src_dir}/${tool}/configure             \
              --host=${target}                       \
              --target=${target}                     \
              --build=${build}                       \
              --prefix=/usr                            \
              --without-cvs                            \
              --disable-profile                        \
              --without-gd                             \
              --disable-debug                          \
              --disable-sanity-checks                  \
	      --disable-mathvec                        \
              --with-headers="${sys_root}/usr/include"    \
              --enable-add-ons=nptl,libidn,ports       \
	      --enable-kernel="${MKCROSS_GLIBC_ENABLE_KERNEL}"   \
	      --disable-werror                       \
	      --disable-nscd                         \
              --disable-obsolete-rpc                 \
              --without-selinux

    #
    #以下のconfigparmsは, make-3.82対応のために必要
    #make-3.82は, makeの引数で以下のオプションを引き渡せない障害があるので,
    #configparmに設定を記載.
    #
    #http://sourceware.org/bugzilla/show_bug.cgi?id=13810
    #Christer Solskogen 2012-03-06 14:18:58 UTC
    #の記事参照
    #
    #install-bootstrap-headers=yes
    #   libcのヘッダだけをインストールする
    #
    #cross-compiling=yes
    #   クロスコンパイルを行う
    #
    #install_root=${SYSROOT}
    #   ${SYSROOT}配下にインストールする. --prefixに/usrを設定しているので
    #   ${SYSROOT}/usr/include配下にヘッダをインストールする意味となる.
    #
    cat >> configparms<<EOF
install-bootstrap-headers=yes
cross-compiling=yes
install_root=${sys_root}
EOF

    #
    #glibcの仕様により生成されないヘッダファイルをコピーする
    #(eglibcでは、バグと見なされ, 修正されているがコミュニティ間の
    #考え方の相違で, glibcでは修正されない)
    #
    mkdir -p "${sys_root}/usr/include/gnu"
    touch "${sys_root}/usr/include/gnu/stubs.h"
    touch "${sys_root}/usr/include/gnu/stubs-lp64.h"

    if [ ! -f "${sys_root}/usr/include/features.h" ]; then
	cp -v "${src_dir}/${tool}/include/features.h" \
	   "${sys_root}/usr/include"
    fi

    #
    #libcのヘッダのみをインストール
    #
    BUILD_CC=${build}-gcc                \
    CFLAGS="-O  -finline-functions"        \
    CC=${prefix}/bin/${target}-gcc                       \
    AR=${prefix}/bin/${target}-ar                        \
    LD=${prefix}/bin/${target}-ld                        \
    RANLIB=${prefix}/bin/${target}-ranlib                \
    sudo make -i install-bootstrap-headers=yes install-headers

    #
    #glibcの仕様により生成されないヘッダファイルをコピーする
    #
    if [ ! -f "${sys_root}/usr/include/bits/stdio_lim.h" ]; then
	cp -v bits/stdio_lim.h "${sys_root}/usr/include/bits"
    fi
    #
    #32bit版のstabsを仮生成する
    #
    if [ ! -f "${sys_root}/usr/include/gnu/stubs-32.h" ]; then
	touch "${sys_root}/usr/include/gnu/stubs-32.h"
    fi

    popd
}

#
# gen_glibc_startup ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
gen_glibc_startup(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/glibc_startup"
	local build_dir="$5/glibc_startup"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="glibc"
	local rmfile
	local tool
	local archive
	local target_cflags
	local _lib
	local build

	build=`gcc -dumpmachine`

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	_lib="${lib_cpus[${cpu}]}"
	if [ "x${_lib}" = "x" ]; then
	    _lib="lib"
	fi

	echo "@@@ glibc startup @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Tool: ${tool}"
	echo "Target Cflags:${target_cflags}"
	echo "libdir :${_lib}"

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}/${tool}"

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	pushd "${build_dir}"

    CFLAGS="-O -finline-functions"               \
	${src_dir}/${tool}/configure             \
        --host=${target}                       \
        --target=${target}                     \
        --prefix=/usr                            \
        --without-cvs                            \
        --disable-profile                        \
        --without-gd                             \
        --disable-debug                          \
        --disable-sanity-checks                  \
	--disable-mathvec                        \
        --with-headers="${sys_root}/usr/include" \
        --enable-add-ons=nptl,libidn,ports       \
	--enable-kernel="${MKCROSS_GLIBC_ENABLE_KERNEL}"  \
	  --disable-werror                       \
	  --disable-nscd                         \
	  --disable-systemtap                    \
          --without-selinux
    #
    #以下のconfigparmsは, make-3.82対応のために必要
    #make-3.82は, makeの引数で以下のオプションを引き渡せない障害があるので,
    #configparmに設定を記載.
    #
    #http://sourceware.org/bugzilla/show_bug.cgi?id=13810
    #Christer Solskogen 2012-03-06 14:18:58 UTC
    #の記事参照
    #
    #cross-compiling=yes
    #   クロスコンパイルを行う
    #
    #install_root=${SYSROOT}
    #   ${SYSROOT}配下にインストールする. --prefixに/usrを設定しているので
    #   ${SYSROOT}/usr/include配下にヘッダをインストールする意味となる.
    #
    cat >> configparms<<EOF
cross-compiling=yes
install_root=${sys_root}
EOF

    BUILD_CC=${build}-gcc                \
    CFLAGS="-O  -finline-functions"        \
    CC=${prefix}/bin/${target}-gcc                       \
    AR=${prefix}/bin/${target}-ar                        \
    LD=${prefix}/bin/${target}-ld                        \
    RANLIB=${prefix}/bin/${target}-ranlib                \
    make -j`nproc` csu/subdir_lib

    #
    #Cのスタートアップルーチンを${SYSROOT}の/usr/lib64にコピーする
    #（ディレクトリを作成してから, インストールする)
    #
    mkdir -pv "${sys_root}/usr/${_lib}"
    cp -pv csu/crt[1in].o "${sys_root}/usr/${_lib}"
    # Cのスタートアップルーチンをgccのローカルプレフィックスにコピーする
    # shなど一部のcpuの場合, gccのローカルプレフィックスを見に行くため
    mkdir -p "${prefix}/${target}/${_lib}"
    cp -pv csu/crt[1in].o "${prefix}/${target}/${_lib}"

    #libc.soを作るためには, libc.soのリンクオプション(-lc)を付けて,
    #コンパイルを通す必要がある（実際にlibc.soの関数は呼ばないので
    #空のlibc.soでよい)
    #そこで、libgcc_s.soを作るために, ダミーのlibc.soを作る
    #http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.16.0.tar.bz2
    #crosstool-ng-1.16.0/scripts/build/libc/glibc-eglibc.sh-common
    #の記述を参照して作成。
    #
    ${target}-gcc  -nostdlib        \
        -nostartfiles    \
        -shared          \
        -x c /dev/null   \
        -o "${sys_root}/usr/${_lib}/libc.so"

    popd


    #
    #stage2のコンパイラはsysrootのlibにcrtを見に行くので以下の処理を追加。
    #
    if [ ! -d "${sys_root}/lib" ]; then
	mkdir -p "${sys_root}/lib"
    fi

    pushd "${sys_root}/lib"
    rm -f libc.so crt1.o crti.o crtn.o
    ln -sv "../usr/${_lib}/libc.so"
    ln -sv "../usr/${_lib}/crt1.o"
    ln -sv "../usr/${_lib}/crti.o"
    ln -sv "../usr/${_lib}/crtn.o"
    popd

    #
    #バイアーキ版のコンパイラ生成にも対応できるように,
    #libgcc_so生成時にインストール先の/lib64配下にもスタートアップを
    #見に行けるように以下の処理を実施
    #
    if [ "x${_lib}" != "xlib" ]; then
	mkdir -pv "${sys_root}/${_lib}"
	pushd "${sys_root}/${_lib}"
	rm -f libc.so crt1.o crti.o crtn.o
	ln -sv "../usr/${_lib}/libc.so"
	ln -sv "../usr/${_lib}/crt1.o"
	ln -sv "../usr/${_lib}/crti.o"
	ln -sv "../usr/${_lib}/crtn.o"
	popd
    fi
}

#
# cross_gcc_stage2 ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
cross_gcc_stage2(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/gcc_stage2"
	local build_dir="$5/gcc_stage2"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="gcc"
	local rmfile
	local tool
	local archive
	local target_cflags
	local build

	build=`gcc -dumpmachine`

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	echo "@@@ gcc_stage2 @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Target Cflags:${target_cflags}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	pushd "${build_dir}"

    env CC_FOR_BUILD=${build}-gcc                          \
    CXX_FOR_BUILD=${build}-g++                             \
    AR_FOR_BUILD=${build}-ar                               \
    LD_FOR_BUILD=${build}-ld                               \
    RANLIB_FOR_BUILD=${build}-ranlib                       \
    ${src_dir}/${tool}/configure                             \
	--prefix=${prefix}                                   \
	--target=${target}                                   \
	--with-local-prefix="${prefix}/${target}"            \
	--with-sysroot="${sys_root}"                         \
	--enable-languages=c                                 \
	--enable-shared                                      \
	--disable-bootstrap                                  \
	--disable-werror                                     \
	--disable-multilib                                   \
	--disable-threads                                    \
	--disable-lto                                        \
	--disable-decimal-float                              \
	--disable-libatomic                                  \
	--disable-libitm                                     \
        --disable-libquadmath                                \
	--disable-libvtv                                     \
	--disable-libcilkrts                                 \
	--disable-libmudflap                                 \
	--disable-libssp                                     \
	--disable-libmpx                                     \
	--disable-libgomp                                    \
	--disable-libsanitizer                               \
	--disable-nls

    #
    #cpp/libiberty(GNU共通基盤ライブラリ)の構築
    #
    make configure-gcc configure-libcpp configure-build-libiberty
    make -j`nproc` all-libcpp all-build-libiberty

    #
    #libdecnumber/libbacktrace(gccの動作に必須なライブラリ)の構築
    #
    make configure-libdecnumber
    make -j`nproc` -C libdecnumber libdecnumber.a
    make configure-libbacktrace
    make -j`nproc` -C libbacktrace

    #
    #libgccのコンパイルオプション定義を生成し,
    #libcはまだないことから, -lcを除去する
    #
    make -j`nproc` -C gcc libgcc.mvars
    sed -r -i -e 's@-lc@@g' gcc/libgcc.mvars

    #
    #gcc(Cコンパイラ)とアーキ共通基盤ライブラリ(libgcc)の構築
    #
    make -j`nproc` all-gcc all-target-libgcc
    sudo make install-gcc install-target-libgcc

    popd
}

#
# cross_glibc_lib ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
cross_glibc_lib(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/glibc_lib"
	local build_dir="$5/glibc_lib"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="glibc"
	local rmfile
	local tool
	local archive
	local target_cflags
	local _lib
	local make_target

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	_lib="${lib_cpus[${cpu}]}"
	if [ "x${_lib}" = "x" ]; then
	    _lib="lib"
	fi

	echo "@@@ glibc library @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Tool: ${tool}"
	echo "Target Cflags:${target_cflags}"
	echo "libdir :${_lib}"

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}/${tool}"

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	pushd "${build_dir}"

	CFLAGS="-O -finline-functions"           \
	${src_dir}/${tool}/configure             \
        --build=${build}                       \
        --host=${target}                       \
        --target=${target}                     \
        --prefix=/usr                            \
        --without-cvs                            \
        --disable-profile                        \
        --without-gd                             \
        --disable-debug                          \
        --disable-sanity-checks                  \
	--disable-mathvec                        \
        --with-headers="${sys_root}/usr/include" \
        --enable-kernel="${MKCROSS_GLIBC_ENABLE_KERNEL}" \
        --enable-add-ons=nptl,libidn,ports       \
	  --disable-werror                       \
          --disable-systemtap                    \
          --disable-obsolete-rpc                 \
          --without-selinux

    #
    #以下のconfigparmsは, make-3.82対応のために必要
    #make-3.82は, makeの引数で以下のオプションを引き渡せない障害があるので,
    #configparmに設定を記載.
    #
    #http://sourceware.org/bugzilla/show_bug.cgi?id=13810
    #Christer Solskogen 2012-03-06 14:18:58 UTC
    #の記事参照
    #
    #cross-compiling=yes
    #   クロスコンパイルを行う
    #
    #install_root=${SYSROOT}
    #   ${SYSROOT}配下にインストールする. --prefixに/usrを設定しているので
    #   ${SYSROOT}/usr/include配下にヘッダをインストールする意味となる.
    #
    cat >> configparms<<EOF
cross-compiling=yes
install_root=${sys_root}
EOF
    #
    #libgcc_eh.a付きのコンパイラ生成時に一時的に作成したlibc.soを削除する
    #
    echo "Remove pseudo libc.so"
    rm -f "${sys_root}/${_lib}/libc.so"
    rm -f "${sys_root}/lib/libc.so"

    #
    # eglibcへの対処
    #
    if [ ! -f ${src_dir}/${tool}/EGLIBC.cross-building ]; then
	make_target="lib"
    else
	make_target="install-lib-all"
    fi

    echo "@@@@ Install with :${make_target} @@@@"

    #sysroot配下にライブラリがインストールされていないため,
    #libcの附属コマンドは構築できない.
    #このことから, ライブラリのみを構築する.
    #malloc/libmemusage.soのビルドで止まるため, -iをつけて強制インストールする
    BUILD_CC=${build}-gcc                \
    CFLAGS="-O  -finline-functions"        \
    CC=${prefix}/bin/${target}-gcc                       \
    AR=${prefix}/bin/${target}-ar                        \
    LD=${prefix}/bin/${target}-ld                        \
    RANLIB=${prefix}/bin/${target}-ranlib                \
    make -i -j`nproc` INSTALL_TARGET="${make_target}"

    #
    #構築したライブラリのインストール
    #
    mkdir -pv "${sys_root}/usr/${_lib}"
    rm -f     "${sys_root}/usr/${_lib}/crt[1in].o"
    rm -f     "${sys_root}/usr/${_lib}/libc.so"
    rm -f     "${prefix}/${target}/${_lib}/crt[1in].o"

    #
    # スタートアップファイルをコピーする
    #
    cp csu/crt1.o csu/crti.o csu/crtn.o \
	"${sys_root}/usr/${_lib}"
    #
    #リンクを張り直す
    #
    pushd "${sys_root}/lib"
    rm -f libc.so crt1.o crti.o crtn.o
    ln -sv "../usr/${_lib}/libc.so"
    ln -sv "../usr/${_lib}/crt1.o"
    ln -sv "../usr/${_lib}/crti.o"
    ln -sv "../usr/${_lib}/crtn.o"
    popd

    if [ "x${_lib}" != "xlib" ]; then
	mkdir -p "${sys_root}/${_lib}"
	pushd "${sys_root}/${_lib}"
	rm -f libc.so crt1.o crti.o crtn.o
	ln -sv "../usr/${_lib}/libc.so"
	ln -sv "../usr/${_lib}/crt1.o"
	ln -sv "../usr/${_lib}/crti.o"
	ln -sv "../usr/${_lib}/crtn.o"
	popd
    fi


    popd
}

#
# cross_gcc_stage3 ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
cross_gcc_stage3(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/gcc_stage3"
	local build_dir="$5/gcc_stage3"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="gcc"
	local rmfile
	local tool
	local archive
	local target_cflags
	local build

	build=`gcc -dumpmachine`

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	echo "@@@ gcc_stage3 @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Target Cflags:${target_cflags}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	_lib="${lib_cpus[${cpu}]}"
	if [ "x${_lib}" = "x" ]; then
	    _lib="lib"
	fi


	pushd "${build_dir}"

	env CC_FOR_BUILD=${build}-gcc                           \
	    CXX_FOR_BUILD=${build}-g++                          \
	    AR_FOR_BUILD=${build}-ar                            \
	    LD_FOR_BUILD=${build}-ld                            \
	    RANLIB_FOR_BUILD=${build}-ranlib                    \
	    ${src_dir}/${tool}/configure                          \
	    --prefix="${prefix}"                                 \
            --build=${build}                                   \
            --host=${build}                                    \
	    --target=${target}                                 \
	    --with-local-prefix="${prefix}/${target}"            \
	    --disable-bootstrap                                  \
	    --disable-werror                                     \
	    --enable-shared                                      \
	    --enable-languages=c                                 \
	    --disable-multilib                                   \
	    --enable-threads=posix                               \
	    --enable-symvers=gnu                                 \
	    --enable-__cxa_atexit                                \
	    --enable-c99                                         \
	    --enable-long-long                                   \
	    --disable-lto                                        \
	    --disable-decimal-float                              \
	    --disable-libatomic                                  \
	    --disable-libitm                                     \
            --disable-libquadmath                                \
	    --disable-libvtv                                     \
	    --disable-libcilkrts                                 \
	    --disable-libmudflap                                 \
	    --disable-libssp                                     \
	    --disable-libmpx                                     \
	    --disable-libgomp                                    \
	    --disable-libsanitizer                               \
	    --with-sysroot="${sys_root}"                         \
	    --with-long-double-128                               \
	    --disable-nls

	make -j`nproc`
	sudo make  install
	popd

	echo "Remove .la files"
	pushd "${prefix}"
	find . -name '*.la'|while read file
	do
	    echo "Remove ${file}"
	    sudo rm -f "${file}"
	done
	popd

	#
	#リンクを張り直す
	#
	pushd "${sys_root}/lib"
	rm -f libc.so crt1.o crti.o crtn.o
	ln -sv "../usr/${_lib}/libc.so"
	ln -sv "../usr/${_lib}/crt1.o"
	ln -sv "../usr/${_lib}/crti.o"
	ln -sv "../usr/${_lib}/crtn.o"
	popd

	if [ "x${_lib}" != "xlib" ]; then
	    mkdir -p "${sys_root}/${_lib}"
	    pushd "${sys_root}/${_lib}"
	    rm -f libc.so crt1.o crti.o crtn.o
	    ln -sv "../usr/${_lib}/libc.so"
	    ln -sv "../usr/${_lib}/crt1.o"
	    ln -sv "../usr/${_lib}/crti.o"
	    ln -sv "../usr/${_lib}/crtn.o"
	    popd
	fi
}

#
# cross_glibc ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
cross_glibc(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/glibc"
	local build_dir="$5/glibc"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="glibc"
	local rmfile
	local tool
	local archive
	local target_cflags
	local _lib
	local make_target

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	_lib="${lib_cpus[${cpu}]}"
	if [ "x${_lib}" = "x" ]; then
	    _lib="lib"
	fi

	echo "@@@ glibc @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Tool: ${tool}"
	echo "Target Cflags:${target_cflags}"
	echo "libdir :${_lib}"

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}/${tool}"

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	pushd "${build_dir}"

	CFLAGS="-O -finline-functions"           \
	${src_dir}/${tool}/configure             \
        --build=${build}                       \
        --host=${target}                       \
        --target=${target}                     \
        --prefix=/usr                            \
        --without-cvs                            \
        --disable-profile                        \
        --without-gd                             \
        --disable-debug                          \
        --disable-sanity-checks                  \
	--disable-mathvec                        \
        --with-headers="${sys_root}/usr/include" \
        --enable-kernel="${MKCROSS_GLIBC_ENABLE_KERNEL}"   \
        --enable-add-ons=nptl,libidn,ports       \
	  --disable-werror                       \
          --disable-systemtap                    \
          --disable-obsolete-rpc                 \
          --without-selinux

    #
    #以下のconfigparmsは, make-3.82対応のために必要
    #make-3.82は, makeの引数で以下のオプションを引き渡せない障害があるので,
    #configparmに設定を記載.
    #
    #http://sourceware.org/bugzilla/show_bug.cgi?id=13810
    #Christer Solskogen 2012-03-06 14:18:58 UTC
    #の記事参照
    #
    #cross-compiling=yes
    #   クロスコンパイルを行う
    #
    #install_root=${SYSROOT}
    #   ${SYSROOT}配下にインストールする. --prefixに/usrを設定しているので
    #   ${SYSROOT}/usr/include配下にヘッダをインストールする意味となる.
    #
    cat >> configparms<<EOF
cross-compiling=yes
install_root=${sys_root}
EOF

    BUILD_CC=${build}-gcc                        \
	    BUILD_AR=${build}-ar                 \
	    BUILD_LD=${build}-ld                 \
	    BUILD_RANLIB=${build}-ranlib         \
	    CFLAGS="-O -finline-functions"         \
	    CC=${prefix}/bin/${target}-gcc       \
	    AR=${prefix}/bin/${target}-ar        \
	    LD=${prefix}/bin/${target}-ld        \
	    RANLIB="${prefix}/bin/${target}-ranlib" \
	    make -j`nproc` all


      pushd "${sys_root}/lib"
      rm -f libc.so crt1.o crti.o crtn.o
      popd

      pushd "${sys_root}/${_lib}"
      rm -f libc.so crt1.o crti.o crtn.o
      popd

      BUILD_CC=${build}-gcc         \
      BUILD_AR=${build}-ar          \
      BUILD_LD=${build}-ld          \
      BUILD_RANLIB=${build}-ranlib  \
      CFLAGS="-O -finline-functions"  \
      CC=${prefix}/bin/${target}-gcc       \
      AR=${prefix}/bin/${target}-ar        \
      LD=${prefix}/bin/${target}-ld        \
      RANLIB=${prefix}/bin/${target}-ranlib \
      sudo make install_root="${sys_root}" install

    popd

    #
    #multilib非対応のコンパイラはsysrootのlibにcrtを見に行くので以下の処理を追加。
    #
    if [ ! -d "${sys_root}/lib" ]; then
	mkdir -p "${sys_root}/lib"
    fi

    pushd "${sys_root}/lib"
    rm -f crt1.o crti.o crtn.o
    ln -sv "../usr/${_lib}/crt1.o"
    ln -sv "../usr/${_lib}/crti.o"
    ln -sv "../usr/${_lib}/crtn.o"
    popd
}

#
# cross_gcc_linux_final ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
cross_gcc_linux_final(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/gcc_linux_final"
	local build_dir="$5/gcc_linux_final"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="gcc"
	local rmfile
	local tool
	local archive
	local target_cflags
	local build

	build=`gcc -dumpmachine`

	target_cflags="${cpu_target_cflags[${cpu}-${toolchain_type}]}"

	echo "@@@ gcc_linux_final @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "Target Cflags:${target_cflags}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	_lib="${lib_cpus[${cpu}]}"
	if [ "x${_lib}" = "x" ]; then
	    _lib="lib"
	fi


	pushd "${build_dir}"

    env CC_FOR_BUILD=${build}-gcc                          \
    CXX_FOR_BUILD=${build}-g++                             \
    AR_FOR_BUILD=${build}-ar                               \
    LD_FOR_BUILD=${build}-ld                               \
    RANLIB_FOR_BUILD=${build}-ranlib                       \
    ${src_dir}/${tool}/configure                             \
	--prefix="${prefix}"                                 \
        --build=${build}                                   \
        --host=${build}                                    \
	--target=${target}                                 \
	--with-local-prefix="${prefix}/${target}"            \
	--disable-bootstrap                                  \
	--disable-werror                                     \
	--enable-shared                                      \
	--enable-languages=c,c++                             \
	--disable-multilib                                   \
	--enable-threads=posix                               \
	--enable-symvers=gnu                                 \
	--enable-__cxa_atexit                                \
	--enable-c99                                         \
	--enable-long-long                                   \
	--enable-libmudflap                                  \
	--enable-libssp                                      \
	--enable-libgomp                                     \
	--disable-libsanitizer                               \
	--with-sysroot="${sys_root}"                         \
	--with-long-double-128                               \
	--disable-nls

    make -j`nproc`
    sudo make install
    popd

    echo "Remove .la files"
    pushd "${prefix}"
    find . -name '*.la'|while read file
    do
	echo "Remove ${file}"
	sudo rm -f "${file}"
    done
    popd

    #
    #リンクを張り直す
    #
    pushd "${sys_root}/lib"
    rm -f libc.so crt1.o crti.o crtn.o
    ln -sv "../usr/${_lib}/libc.so"
    ln -sv "../usr/${_lib}/crt1.o"
    ln -sv "../usr/${_lib}/crti.o"
    ln -sv "../usr/${_lib}/crtn.o"
    popd

    if [ "x${_lib}" != "xlib" ]; then
	mkdir -p "${sys_root}/${_lib}"
	pushd "${sys_root}/${_lib}"
	rm -f libc.so crt1.o crti.o crtn.o
	ln -sv "../usr/${_lib}/libc.so"
	ln -sv "../usr/${_lib}/crt1.o"
	ln -sv "../usr/${_lib}/crti.o"
	ln -sv "../usr/${_lib}/crtn.o"
	popd
    fi
}

#
# cross_gdb ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
cross_gdb(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/gdb"
	local build_dir="$5/gdb"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local key="gdb"
	local python_path
	local python_arg
	local rmfile
	local tool
	local archive
	local sim_arg
	local build

	build=`gcc -dumpmachine`

	echo "@@@ gdb @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	#
	# python連携
	#
	python_path=`which python`
	if [ "none${python_path}" = "none" ]; then
		python_path=`which python3`
	if [ "none${python_path}" = "none" ]; then
		python_path=`which python2`
	fi
	fi

	if [ "none${python_path}" = "none" ]; then
		python_path='none'
	fi

	if [ "${python_path}" != "none" ]; then
	echo "Python is installed on ${python_path}"
		python_arg="--with-python=${python_path}"
	else
		python_arg=""
	fi

	case "${cpu}" in
		v850)
			python_arg="--with-python=no"
			;;
	esac

	#
	# Simulator
	#
	sim_arg=""
	case "${cpu}" in
		microblaze | microblazeel)
			sim_arg="--disable-sim"
			;;
	esac

	pushd "${src_dir}"
	tar xf "${DOWNLOADS_DIR}/${archive}"
	popd

	#
	#gdb用のパッチを適用
	#
	pushd "${src_dir}/${tool}"
	patch -p1 < "${MKCROSS_PATCHES_DIR}/gdb/gdb-8.3-qemu-x86-64.patch"
	popd

	#
	# configureの設定
	#
	#--prefix="${prefix}"
	#          ${prefix}配下にインストールする
	#--target="${target}"
	#          ターゲット環境向けのコードを生成するコンパイラを構築する
	#--with-local-prefix="${prefix}/${target}"
	#          gdb内部で使用するファイルを"${prefix}/${target}"に格納する
	#${python_arg}
	#          pythonスクリプトによるデバッグ支援機能を有効にする
	#--disable-werror
	#         警告をエラーと見なさない
	#--disable-nls
	#         コンパイル時間を短縮するためNative Language Supportを無効化する
	#
	pushd "${build_dir}"
	${src_dir}/${tool}/configure                            \
		--prefix="${prefix}"                            \
		--target=${target}                              \
		--build=${build}                                \
		--host=${build}                                 \
		--with-local-prefix="${prefix}/${target}"       \
		${python_arg}                                   \
		${sim_arg}                                      \
		--disable-werror                                \
		--disable-nls                                   \

	make -j`nproc`
	make install

	popd


	#
	#.laファイルを削除する
	#
	echo "Remove .la files"

	find ${prefix} -name '*.la'|while read rmfile
	do
		echo "Remove ${rmfile}"
		rm -f ${rmfile}
	done
}

#
# build_qemu ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
build_qemu(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local src_dir="$4/qemu"
	local build_dir="$5/qemu"
	local toolchain_type="$6"
	local sys_root="${prefix}/rfs"
	local qemu_target_list
	local key="qemu"
	local tool
	local archive

	qemu_target_list="${qemu_targets[${cpu}]}"

	if [ "x${qemu_target_list}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	echo "@@@ qemu @@@"
	echo "Prefix:${prefix}"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	echo "QEmu targets: ${qemu_target_list}"

	tool=`get_tool_name ${cpu} ${key}`
	archive=`get_archive_name ${cpu} ${key}`

	if [ "x${archive}" = "x" ]; then
		echo "No ${key} for ${cpu}"
		return 1
	fi

	mkdir -p "${sys_root}"
	if [ -d "${src_dir}" ]; then
		rm -fr "${src_dir}"
	fi
	mkdir -p "${src_dir}"

	if [ -d "${build_dir}" ]; then
		rm -fr "${build_dir}"
	fi
	mkdir -p "${build_dir}"

	pushd "${src_dir}"
	tar xf ${DOWNLOADS_DIR}/${archive}
	popd

	pushd "${build_dir}"
	${src_dir}/${tool}/configure                        \
		--prefix="${prefix}"                            \
		--target-list="${qemu_target_list}"             \
		--enable-user                                   \
		--enable-linux-user                             \
		--enable-system                                 \
		--interp-prefix="${sys_root}"                   \
		--enable-tcg-interpreter                        \
		--enable-modules                                \
		--enable-membarrier                             \
		--disable-werror

	make -j`nproc`
	make install

	popd
}

#
# generate_module_file ターゲットCPU ターゲット名 プレフィクス ソース展開ディレクトリ ビルドディレクトリ ツールチェイン種別
#
generate_module_file(){
	local cpu="$1"
	local target="$2"
	local prefix="$3"
	local key="lmod"
	local mod_file
	local target_var
	local qemu_cpu
	local qemu_line

	target_var=`echo ${target}|sed -e 's|-|_|g'`

	qemu_cpu="${qemu_cpus[${cpu}]}"
	qemu_line="# No QEmu system simulator for ${target}"
	if [ "x${qemu_cpu}" != "x" ]; then
		qemu_line="setenv QEMU	   qemu-system-${qemu_cpu}"
	fi

	echo "@@@ Environment Module File @@@"
	echo "target:${target}"
	echo "Sysroot:${sys_root}"
	echo "BuildDir:${build_dir}"
	echo "SourceDir:${src_dir}"
	if [ "x${qemu_cpu}" != "x" ]; then
		echo "QEmuCPUName:${qemu_cpu}"
	fi
	echo "var: ${target_var}"

	mod_file=`echo "${target}"| tr '[:lower:]' '[:upper:]'`
	mod_file="${mod_file}-GCC"
	echo "Generate ${mod_file} ..."

	mkdir -p ${LMOD_MODULE_DIR}

	#
	# Tcl形式のEnvironment Moduleファイルを生成
	#
	cat <<EOF > "${LMOD_MODULE_DIR}/${mod_file}"
#%Module1.0
##
## gcc toolchain for ${target}
##
## Note: This is generated automatically.
##

proc ModulesHelp { } {
		puts stderr "gcc toolchain for ${target} Setting \n"
}
#
module-whatis   "gcc toolchain for ${target} Setting"

# for Tcl script only
set ${target_var}_gcc_path "${prefix}/bin"

# environmnet variables
setenv CROSS_COMPILE ${target}-
setenv GCC_ARCH      ${target}-
setenv GDB_COMMAND   ${target}-gdb

${qemu_line}

# append pathes
prepend-path    PATH    \${${target_var}_gcc_path}

EOF
}

main(){
	local cpu
	local prefix
	local build_dir
	local src_dir
	local orig_path
	local target_name
	local toolchain_type

	#
	# 事前準備
	#
	orig_path="${PATH}"

	mkdir -p "${LMOD_MODULE_DIR}"
	mkdir -p "${SHELL_INIT_DIR}"
	mkdir -p "${DOWNLOADS_DIR}"

	# 開発環境セットアップ
	prepare

	#
	# クロス環境構築
	#

	#アーカイブのダウンロード
	download_archives

	# 各CPU向けのコンパイラを生成
	for cpu in "${targets[@]}"
	do

		build_dir="${TOP_DIR}/${cpu}/build"
		src_dir="${TOP_DIR}/${cpu}/src"
		prefix="${CROSS_PREFIX}/${cpu}"

		toolchain_type="linux"
		target_name="${cpu}-unknown-${toolchain_type}-gnu"
		if [ "x${cpu_target_names[${cpu}-${toolchain_type}]}" != "x" ]; then
			target_name="${cpu_target_names[${cpu}-${toolchain_type}]}"
		fi

		mkdir -p "${prefix}"
		mkdir -p "${prefix}/rfs"

		export PATH="${prefix}/bin:${orig_path}"

		echo "@@@ ${cpu} @@@"
		echo "Target:${target_name}"
		echo "Prefix:${prefix}"
		echo "Sysroot:${prefix}/rfs"
		echo "BuildDir:${build_dir}"
		echo "SourceDir:${src_dir}"
		echo "PATH:${PATH}"


#		build_qemu \
#		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"


		cross_binutils \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"
		cross_gcc_stage1 \
			"${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"
		gen_kernel_headers \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"
		gen_glibc_headers \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"
		gen_glibc_startup \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"
		cross_gcc_stage2 \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"
		cross_glibc_lib \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"
		cross_gcc_stage3 \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"

		cross_glibc \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"

		cross_gcc_linux_final \
		    "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"

		# cross_gdb \
		#     "${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"

		generate_module_file \
			"${cpu}" "${target_name}" "${prefix}" "${src_dir}" "${build_dir}" "${toolchain_type}"

		#
		# 一時ディレクトリを削除
		#
		if [ -f "${build_dir}" ]; then
			rm -fr "${build_dir}"
		fi

		if [ -f "${src_dir}" ]; then
			rm -fr "${src_dir}"
		fi

		export PATH="${orig_path}"
	done


	#
	#シェルの初期化ファイルを作成する
	#
	generate_shell_init

	#
	# 開発者ユーザを作成する
	#
	echo "@@@ Create User @@@"
	adduser                                             \
		-q                                          \
		--home "${DEVLOPER_HOME}"                   \
		--gecos "Embedded Linux Developer"  \
		--disabled-login                            \
		"${DEVLOPER_NAME}"

	# sudoerに追加
	usermod -aG sudo "${DEVLOPER_NAME}"

	# パスワードレスでsudoを実行可能にする
	echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

	#
	# .bashrcを更新する
	#
	if [ -f ${DEVLOPER_HOME}/.bashrc ]; then
	cat <<EOF >> ${DEVLOPER_HOME}/.bashrc
#
# development environment
#
if [ -f ${SHELL_INIT_DIR}/bash ]; then
	source ${SHELL_INIT_DIR}/bash
fi
#
# set prompt
#
export PS1="[\u@\h \W]"
#
# Language Environment
#
export LANG="ja_JP.UTF-8"
EOF
	fi

	echo "Complete"
}

main $@
