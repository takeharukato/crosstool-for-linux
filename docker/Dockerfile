#
# Linux用クロス開発環境コンテナイメージ
#
# -*- coding:utf-8 mode: dockerfile-mode -*-
# Copyright (C) 1998-2022 by Project HOS
# http://sourceforge.jp/projects/hos/
#

# Ubuntu環境を使用
FROM ubuntu
# メインテナ名
LABEL maintainer="Takeharu KATO"
# リポジトリと関連付ける
LABEL org.opencontainers.image.source https://github.com/takeharukato/crosstool-for-linux
# tzdataインストール時にタイムゾーンを聞かないようにする
ENV DEBIAN_FRONTEND=noninteractive
# ターゲットCPU
# __TARGET_CPU_ENV_LINE__
# イメージファイル名
# __TARGET_IMAGENAME_LINE__
#
#事前準備
#
# 基本ディレクトリ
RUN mkdir -p /home/cross/mkcross/workdir ; \
    mkdir -p /home/cross/mkcross/patches/gdb ; \
    mkdir -p /home/cross/mkcross/vscode/_devcontainer;\
    mkdir -p /home/cross/mkcross/vscode/_vscode;

# クロスコンパイラ作成スクリプトをコピー
COPY scripts/mklinux-cross.sh /home/cross/mkcross

# .devcontainer関連ファイルをコピー
COPY vscode/_devcontainer/Dockerfile /home/cross/mkcross/vscode/_devcontainer
COPY vscode/_devcontainer/devcontainer.json /home/cross/mkcross/vscode/_devcontainer
# .vscode関連ファイルをコピー
COPY vscode/_vscode/c_cpp_properties.json /home/cross/mkcross/vscode/_vscode
COPY vscode/_vscode/launch.json /home/cross/mkcross/vscode/_vscode
COPY vscode/_vscode/tasks.json /home/cross/mkcross/vscode/_vscode
COPY vscode/_vscode/settings.json /home/cross/mkcross/vscode/_vscode
# ワークスペース関連ファイルをコピー
COPY vscode/sample.code-workspace /home/cross/mkcross/vscode

# QEmuのクロスでバッグ用パッチをコピー
COPY patches/gdb/gdb-8.3-qemu-x86-64.patch /home/cross/mkcross/patches/gdb

# ファイル構成確認
# RUN ls -lR /home/cross/mkcross;       \
#     cd /home/cross/mkcross/workdir ;  \

# コンパイル環境生成
RUN ls -lR /home/cross/mkcross;       \
    cd /home/cross/mkcross/workdir ;  \
    /bin/bash ../mklinux-cross.sh;    \
    ls -lR /opt/cross/gcc;            \
    rm -fr /home/cross;
