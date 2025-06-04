#!/bin/bash

# 脚本名称: add_swap.sh
# 描述: 一键为Linux添加swap内存的交互式脚本
# 作者: AI助手
# 创建日期: $(date +"%Y-%m-%d")

# 颜色定义
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # 无颜色

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 请以root权限运行此脚本${NC}"
    exit 1
fi

# 显示当前swap状态
echo -e "${YELLOW}当前系统Swap状态:${NC}"
free -h | grep -i swap
echo ""

# 检查是否已存在swap
swap_exists=$(swapon --show)
if [ -n "$swap_exists" ]; then
    echo -e "${YELLOW}系统已存在Swap分区:${NC}"
    swapon --show
    echo ""
    read -p "是否继续添加新的Swap? (y/n): " continue_choice
    if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
        echo -e "${GREEN}操作已取消${NC}"
        exit 0
    fi
fi

# 交互式设置Swap大小
while true; do
    read -p "请输入要创建的Swap大小(单位:GB): " swap_size_gb
    if [[ "$swap_size_gb" =~ ^[0-9]+$ ]]; then
        if [ "$swap_size_gb" -gt 0 ]; then
            break
        else
            echo -e "${RED}错误: Swap大小必须大于0${NC}"
        fi
    else
        echo -e "${RED}错误: 请输入有效的数字${NC}"
    fi
done

# 确认操作
echo -e "${YELLOW}将创建 ${swap_size_gb}GB 的Swap空间${NC}"
read -p "确认继续? (y/n): " confirm_choice
if [[ "$confirm_choice" != "y" && "$confirm_choice" != "Y" ]]; then
    echo -e "${GREEN}操作已取消${NC}"
    exit 0
fi

# 设置swap文件路径
swap_file="/swapfile_${swap_size_gb}G"

# 检查文件是否已存在
if [ -f "$swap_file" ]; then
    echo -e "${RED}警告: $swap_file 已存在${NC}"
    read -p "是否覆盖? (y/n): " overwrite_choice
    if [[ "$overwrite_choice" != "y" && "$overwrite_choice" != "Y" ]]; then
        echo -e "${GREEN}操作已取消${NC}"
        exit 0
    fi
    # 如果文件正在被使用为swap，先关闭它
    swapoff "$swap_file" 2>/dev/null
fi

# 计算swap大小（以MB为单位）
swap_size_mb=$((swap_size_gb * 1024))

echo -e "${GREEN}开始创建Swap文件...${NC}"

# 创建swap文件
echo -e "${YELLOW}步骤1: 创建swap文件 (这可能需要一些时间)...${NC}"
dd if=/dev/zero of="$swap_file" bs=1M count="$swap_size_mb" status=progress
chmod 600 "$swap_file"

# 设置swap文件
echo -e "${YELLOW}步骤2: 设置swap文件...${NC}"
mkswap "$swap_file"

# 启用swap
echo -e "${YELLOW}步骤3: 启用swap...${NC}"
swapon "$swap_file"

# 添加到fstab以使其在重启后仍然生效
echo -e "${YELLOW}步骤4: 配置开机自动挂载...${NC}"
if ! grep -q "$swap_file" /etc/fstab; then
    echo "$swap_file none swap sw 0 0" >> /etc/fstab
    echo -e "${GREEN}已添加到/etc/fstab，重启后自动挂载${NC}"
fi

# 设置swappiness
current_swappiness=$(cat /proc/sys/vm/swappiness)
echo -e "${YELLOW}当前swappiness值: $current_swappiness${NC}"
read -p "是否修改swappiness值? (推荐值:10) (y/n): " change_swappiness
if [[ "$change_swappiness" == "y" || "$change_swappiness" == "Y" ]]; then
    read -p "请输入新的swappiness值 (0-100): " new_swappiness
    if [[ "$new_swappiness" =~ ^[0-9]+$ ]] && [ "$new_swappiness" -ge 0 ] && [ "$new_swappiness" -le 100 ]; then
        sysctl vm.swappiness="$new_swappiness"
        if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
            echo "vm.swappiness=$new_swappiness" >> /etc/sysctl.conf
        else
            sed -i "s/vm\.swappiness=.*/vm.swappiness=$new_swappiness/" /etc/sysctl.conf
        fi
        echo -e "${GREEN}swappiness已设置为 $new_swappiness${NC}"
    else
        echo -e "${RED}无效的swappiness值，保持不变${NC}"
    fi
fi

# 显示结果
echo -e "\n${GREEN}Swap创建完成!${NC}"
echo -e "${YELLOW}当前系统Swap状态:${NC}"
free -h | grep -i swap
echo ""
swapon --show

echo -e "\n${GREEN}操作成功完成!${NC}"
