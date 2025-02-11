#!/bin/bash


# 确保脚本以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
  echo "请使用 root 权限运行此脚本"
  exit 1
fi

# 创建 /etc/docker 目录（如果不存在）
mkdir -p /etc/docker

# 创建或覆盖 daemon.json 文件
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://docker.hpcloud.cloud",
    "https://docker.m.daocloud.io",
    "https://docker.unsee.tech",
    "https://docker.1panel.live",
    "http://mirrors.ustc.edu.cn",
    "https://docker.chenby.cn",
    "http://mirror.azure.cn",
    "https://dockerpull.org",
    "https://dockerhub.icu",
    "https://hub.rat.dev",
    "https://mirror.ccs.tencentyun.com",
    "https://hub-mirror.c.163.com",
    "https://registry.docker-cn.com",
    "https://proxy.1panel.live",
    "https://docker.1panel.top",
    "https://docker.1ms.run",
    "https://docker.ketches.cn",
    "https://hub.geekery.cn",
    "https://docker.1panel.dev",
    "https://docker.foreverlink.love",
    "https://docker.fxxk.dedyn.io",
    "https://dytt.online",
    "https://func.ink",
    "https://lispy.org",
    "https://docker.xiaogenban1993.com",
    "https://docker.xn--6oq72ry9d5zx.cn",
    "https://docker.zhai.cm",
    "https://docker.5z5f.com",
    "https://a.ussh.net",
    "https://docker.cloudlayer.icu",
    "https://docker.linkedbus.com",
    "https://atomhub.openatom.cn"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

echo "daemon.json 文件已成功创建/更新"

# 如果 Docker 服务正在运行，重启使配置生效
if systemctl is-active --quiet docker; then
  echo "重启 Docker 服务以应用新配置..."
  systemctl restart docker
  echo "Docker 服务已重启"
fi
