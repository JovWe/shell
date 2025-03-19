#!/bin/bash

# 定义DNS服务器（阿里云 + 腾讯云）
DNS_SERVERS=("223.5.5.5" "223.6.6.6" "119.29.29.29" "119.28.28.28")

# 检测Rocky Linux版本
ROCKY_VERSION=$(rpm -E %rhel)

# 获取主网络接口名称
INTERFACE=$(ip route | awk '/default/ {print $5}')

if [[ -z "$INTERFACE" ]]; then
    echo "❌ 无法检测到活动网络接口"
    exit 1
fi

# 根据版本选择配置文件
if [[ $ROCKY_VERSION -ge 9 ]]; then
    CONFIG_FILE="/etc/NetworkManager/system-connections/${INTERFACE}.nmconnection"
    BACKUP_FILE="${CONFIG_FILE}.bak-$(date +%Y%m%d)"
    sed -i.bak "/^dns=/d" $CONFIG_FILE
    awk -v dns="${DNS_SERVERS[*]}" -i inplace '
        /^$$ipv4$$/ {
            print $0
            print "dns=" dns
            getline
            while ($0 !~ /^\[/) {
                getline
            }
        }
        {print}
    ' $CONFIG_FILE
    echo "✅ 已更新NetworkManager配置[6](@ref)"
else
    CONFIG_FILE="/etc/sysconfig/network-scripts/ifcfg-${INTERFACE}"
    BACKUP_FILE="${CONFIG_FILE}.bak-$(date +%Y%m%d)"
    cp $CONFIG_FILE $BACKUP_FILE
    
    # 清理旧DNS设置
    sed -i '/^DNS[0-9]=/d' $CONFIG_FILE
    
    # 写入新DNS
    for i in "${!DNS_SERVERS[@]}"; do
        echo "DNS$((i+1))=${DNS_SERVERS[$i]}" >> $CONFIG_FILE
    done
    echo "✅ 已更新传统网络配置[2,4](@ref)"
fi

# 应用配置变更
if [[ $ROCKY_VERSION -ge 9 ]]; then
    nmcli connection reload $INTERFACE
    nmcli connection down $INTERFACE && nmcli connection up $INTERFACE
else
    systemctl restart NetworkManager
fi

# 验证配置
echo -e "\n🔄 当前DNS配置："
grep 'nameserver' /etc/resolv.conf
echo -e "\n📡 网络接口状态："
nmcli device show $INTERFACE | grep IP4.DNS