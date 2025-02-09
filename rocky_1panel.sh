#!/bin/bash
#Install Latest Stable 1Panel Release

osCheck=`uname -a`
if [[ $osCheck =~ 'x86_64' ]];then
    architecture="amd64"
elif [[ $osCheck =~ 'arm64' ]] || [[ $osCheck =~ 'aarch64' ]];then
    architecture="arm64"
elif [[ $osCheck =~ 'armv7l' ]];then
    architecture="armv7"
elif [[ $osCheck =~ 'ppc64le' ]];then
    architecture="ppc64le"
elif [[ $osCheck =~ 's390x' ]];then
    architecture="s390x"
else
    echo "暂不支持的系统架构，请参阅官方文档，选择受支持的系统。"
    exit 1
fi

if [[ ! ${INSTALL_MODE} ]];then
	INSTALL_MODE="stable"
else
    if [[ ${INSTALL_MODE} != "dev" && ${INSTALL_MODE} != "stable" ]];then
        echo "请输入正确的安装模式（dev or stable）"
        exit 1
    fi
fi

VERSION=$(curl -s https://resource.fit2cloud.com/1panel/package/${INSTALL_MODE}/latest)
HASH_FILE_URL="https://resource.fit2cloud.com/1panel/package/${INSTALL_MODE}/${VERSION}/release/checksums.txt"

if [[ "x${VERSION}" == "x" ]];then
    echo "获取最新版本失败，请稍候重试"
    exit 1
fi

package_file_name="1panel-${VERSION}-linux-${architecture}.tar.gz"
package_download_url="https://resource.fit2cloud.com/1panel/package/${INSTALL_MODE}/${VERSION}/release/${package_file_name}"
expected_hash=$(curl -s "$HASH_FILE_URL" | grep "$package_file_name" | awk '{print $1}')

if [ -f ${package_file_name} ];then
    actual_hash=$(sha256sum "$package_file_name" | awk '{print $1}')
    if [[ "$expected_hash" == "$actual_hash" ]];then
        echo "安装包已存在，跳过下载"
        rm -rf 1panel-${VERSION}-linux-${architecture}
        tar zxvf ${package_file_name}
        cd 1panel-${VERSION}-linux-${architecture}
        /bin/bash install.sh
        exit 0
    else
        echo "已存在安装包，但是哈希值不一致，开始重新下载"
        rm -f ${package_file_name}
    fi
fi

# 安装Docker
echo "开始安装Docker..."

# 删除旧版本Docker（如果存在）
sudo yum remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine

# 安装必要的依赖
yum install -y yum-utils

# 添加Docker仓库（默认使用阿里云源）
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装Docker
yum -y install docker-ce docker-ce-cli containerd.io

# 启动Docker服务
systemctl start docker
systemctl enable --now docker
systemctl daemon-reload
systemctl restart docker

echo "Docker安装完成"

# 开始安装1Panel
echo "开始下载 1Panel ${VERSION} 版本在线安装包"
echo "安装包下载地址： ${package_download_url}"

curl -LOk -o ${package_file_name} ${package_download_url}
curl -sfL https://resource.fit2cloud.com/installation-log.sh | sh -s 1p install ${VERSION}
if [ ! -f ${package_file_name} ];then
	echo "下载安装包失败，请稍候重试。"
	exit 1
fi

tar zxvf ${package_file_name}
if [ $? != 0 ];then
	echo "下载安装包失败，请稍候重试。"
	rm -f ${package_file_name}
	exit 1
fi
cd 1panel-${VERSION}-linux-${architecture}

/bin/bash install.sh
