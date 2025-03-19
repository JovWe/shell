# Shell
## 前言

这里存储一些我开发或完善的脚本。

## rocky_1panel

针对Rocky的docker安装问题，从1panel官方脚本中加入了拉取dnf阿里云镜像软件仓库的docker并安装的操作。

```
wget https://raw.githubusercontent.com/jovwe/shell/main/rocky_1panel.sh && chmod +x rocky_1panel.sh && ./rocky_1panel.sh
```

## add_docker_r.sh

针对国内docker镜像拉取问题，添加了网上搜索的目前（2025年2月11日）可用的镜像库。

```
wget https://raw.githubusercontent.com/jovwe/shell/main/add_docker_r.sh && chmod +x add_docker_r.sh && ./add_docker_r.sh
```

## rocky_dns.sh

针对rocky的默认dns在国内无法正常访问的情况，更改dns为阿里云和腾讯云公共dns

```
wget https://raw.githubusercontent.com/jovwe/shell/main/rocky_dns.sh && chmod +x rocky_dns.sh && ./rocky_dns.sh
```
