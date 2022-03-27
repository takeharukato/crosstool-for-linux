#
# 開発環境コンテナイメージの作成と登録
# -*- coding:utf-8 mode: gmake-mode -*-
# Copyright (C) 1998-2022 by Project HOS
# http://sourceforge.jp/projects/hos/
#

.PHONY: release build build-each run clean clean-images dist-clean prepare \
	clean-workdir build-and-push-each gen-container-dockerfile

TOP_DIR=.

#ターゲットCPU
TARGET_CPUS ?= "riscv64 riscv32 i386 x86_64 arm armhw aarch64 mips mipsel microblaze microblazeel powerpc powerpc64 sparc64"

# 構築テスト用CPU
BUILD_CPU ?= "riscv64"

IMAGE_NAME=crosstool-for-linux

all: release

define CLEAN_WORKDIR
	@if [ -d workdir ]; then \
		rm -fr workdir; \
	fi
endef

define BUILD_IMAGE_ONE
	echo "cpu:$1";		\
	cat docker/Dockerfile | \
	sed -e \
	"s|# __TARGET_CPU_ENV_LINE__|ENV TARGET_CPUS=\"$1\"|g" \
	-e "s|# __TARGET_IMAGENAME_LINE__|ENV THIS_IMAGE_NAME=\"ghcr.io/${GITHUB_USER}/${IMAGE_NAME}-$1:latest\"|g" | \
	tee workdir/Dockerfile; \
	docker build -t "ghcr.io/${GITHUB_USER}/${IMAGE_NAME}-$1:latest" workdir 2>&1 |\
	tee build-$1.log;
endef

define BUILD_AND_PUSH_IMAGE_ONE
	$(call BUILD_IMAGE_ONE,$1)
	if [ -f registry/ghcr.txt ]; then \
		cat registry/ghcr.txt | docker login ghcr.io -u ${GITHUB_USER} --password-stdin; \
		docker push ghcr.io/${GITHUB_USER}/${IMAGE_NAME}-$1:latest; \
		docker logout; \
	fi;
endef

clean-workdir:
	$(call CLEAN_WORKDIR)

prepare: clean-workdir
	@mkdir -p workdir/scripts
	@cp -a docker/patches workdir
	@cp -a docker/vscode workdir
	@cp docker/scripts/*.sh workdir/scripts

gen-container-dockerfile:
	cat docker/Dockerfile | \
	sed \
	-e 's|# __TARGET_CPU_ENV_LINE__|ENV TARGET_CPUS="__REPLACE_TARGET_CPUS__"|g'  \
	-e 's|# __TARGET_IMAGENAME_LINE__|ENV THIS_IMAGE_NAME="__REPLACE_IMAGE_NAME__"|g' | \
	tee templates/Dockerfiles/Dockerfile.tmpl

release: gen-container-dockerfile

build: prepare
	@if [ "x${BUILD_CPU}" != "x" ]; then \
		$(call BUILD_IMAGE_ONE,${BUILD_CPU}) \
	else \
		echo "Please specify BUILD_CPU environment variable."; \
	fi;

build-each: prepare
	$(foreach cpu, ${TARGET_CPUS},$(call BUILD_IMAGE_ONE,${cpu}))
	$(call CLEAN_WORKDIR)


build-and-push-each: prepare
	$(foreach cpu, ${TARGET_CPUS},$(call BUILD_AND_PUSH_IMAGE_ONE,${cpu}))
	$(call CLEAN_WORKDIR)

run:
	docker run -it ${IMAGE_NAME}

clean-images:
	@docker rm -f `docker ps -a -q` || :
	@docker system prune -a -f

clean:
	${RM} *~

dist-clean: clean
	${RM} -f build.log build-*.log
