#!/bin/bash

# ====================
# Solana 节点管理脚本
# ====================
# 模块化设计，便于维护和扩展。

LOG_FILE="/var/log/solana_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# 主菜单函数
menu() {
    echo "============================="
    echo "      Solana 节点管理       "
    echo "============================="
    echo "请选择操作："
    echo "1. 安装依赖项和 Rust 工具链"
    echo "2. 挂载磁盘"
    echo "3. 设置CPU性能模式"
    echo "4. 下载Solana CLI"
    echo "5. 创建验证者私钥"
    echo "6. 系统调优"
    echo "7. 开启防火墙"
    echo "8. 创建启动脚本和服务"
    echo "9. 启动Solana RPC节点"
    echo "10. 查看同步进度"
    echo "11. 调整SWAP空间"
    echo "12. 系统服务管理"
    echo "13. 查看系统服务日志"
    echo "14. 查看 Solana RPC 日志"
    echo "15. 退出"
    echo "============================="
    read -p "输入选项：" option
    case $option in
        1) install_dependencies;;
        2) mount_disks;;
        3) set_cpu_performance;;
        4) download_solana_cli;;
        5) create_validator_keypair;;
        6) sys_tuning;;
        7) enable_firewall;;
        8) create_service;;
        9) start_solana_rpc;;
        10) check_sync_progress;;
        11) adjust_swap;;
        12) service_menu;;
		13) view_service_logs;;
		14) view_rpc_logs;;
        15) echo "退出脚本"; exit 0;;
        *) echo "无效选项，请重新输入";;
    esac
}

# -------------------------
# 模块 1: 安装依赖项和 Rust 工具链
# -------------------------
install_dependencies() {
    echo "开始安装必要的依赖项..."
    apt update
    apt install -y build-essential pkg-config libssl-dev libclang-dev libudev-dev curl
    if [ $? -eq 0 ]; then
        echo "依赖项安装完成。"
    else
        echo "依赖项安装失败，请检查系统配置。"
        return
    fi

    echo "安装 Rust 工具链..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    if [ $? -eq 0 ]; then
        echo "Rust 工具链安装完成。"
        source $HOME/.cargo/env
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.cargo/bin:$PATH"
        rustc --version && cargo --version
    else
        echo "Rust 工具链安装失败，请检查网络连接。"
        return
    fi
}

# -------------------------
# 模块 2: 挂载磁盘
# -------------------------
mount_disks() {
echo "检查并挂载磁盘..."
sleep 1

# 检测到的 NVMe 设备：
lsblk -o NAME,SIZE,TYPE | grep nvme
echo ""

# 选择第一个磁盘设备（用于 Ledger）
echo "请选择第一个磁盘设备（用于 Ledger，编号如 nvme0n1）："
read -p "输入设备编号（例如：nvme0n1）： " ledger_device
# 选择第二个磁盘设备（用于 Accounts）
echo "请选择第二个磁盘设备（用于 Accounts，编号如 nvme1n1）："
read -p "输入设备编号（例如：nvme1n1）： " accounts_device

# 确认格式化并挂载
echo "确认格式化并挂载？输入 yes 继续："
read -p "输入：" confirm
if [ "$confirm" != "yes" ]; then
  echo "挂载操作已取消。"
  exit 1
fi

echo "正在格式化并挂载设备..."
sleep 1

# 检查是否为 RAID 并请求用户确认是否移除
is_raid() {
  local device=$1
  if lsblk -o TYPE,NAME | grep -q "$device.*md"; then
    return 0 # 是 RAID
  else
    return 1 # 不是 RAID
  fi
}

remove_raid() {
  local device=$1
  echo "检测到 $device 是 RAID 设备。是否要移除 RAID 并继续？(yes/no)"
  read -p "输入：" raid_confirm
  if [ "$raid_confirm" == "yes" ]; then
    # 停止 RAID
    mdadm --stop /dev/$device
    mdadm --remove /dev/$device
    echo "RAID 已移除。"
  else
    echo "RAID 移除已取消。"
    exit 1
  fi
}

# 对 Ledger 和 Accounts 设备进行检查和处理
for device in "$ledger_device" "$accounts_device"; do
  if is_raid $device; then
    remove_raid $device
  fi

  # 获取完整的设备路径
  full_device_path="/dev/$device"

  # 格式化设备
  echo "正在格式化 $full_device_path 为 ext4 文件系统..."
  mkfs.ext4 "$full_device_path"

  # 创建挂载点
  mkdir -p "/root/sol/${device//n1/ledger}"
  mkdir -p "/root/sol/${device//n1/accounts}"

  # 挂载设备
  echo "正在挂载 $full_device_path 到对应的挂载点..."
  mount "$full_device_path" "/root/sol/${device//n1/ledger}"
  mount "$full_device_path" "/root/sol/${device//n1/accounts}"

  # 添加到 /etc/fstab 以实现开机自动挂载
  echo "$full_device_path /root/sol/${device//n1/ledger} ext4 defaults 0 0" >> /etc/fstab
  echo "$full_device_path /root/sol/${device//n1/accounts} ext4 defaults 0 0" >> /etc/fstab
done

echo "磁盘挂载完成。"

# -------------------------
# 模块 3: 设置 CPU 性能模式
# -------------------------
set_cpu_performance() {
    echo "设置 CPU 为 performance 模式..."
    apt install -y linux-tools-common linux-tools-$(uname -r)
    if ! command -v cpupower &>/dev/null; then
        echo "cpupower 未安装，请检查依赖。"
        return
    fi
    cpupower frequency-set --governor performance
    echo "CPU 性能模式已设置为 performance。"
}

# -------------------------
# 模块 4: 下载 Solana CLI
# -------------------------
download_solana_cli() {
    echo "下载 Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.15/install)"
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> /root/.bashrc
    export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
    source /root/.bashrc
    solana --version
}

# -------------------------
# 模块 5: 创建验证者私钥
# -------------------------
create_validator_keypair() {
    echo "创建验证者私钥..."
    solana-keygen new -o /root/sol/validator-keypair.json
    echo "验证者私钥已创建：/root/sol/validator-keypair.json"
}

# -------------------------
# 模块 6: 系统调优
# -------------------------
sys_tuning() {
    echo "进行系统调优..."
    tuning_params=(
        "net.core.rmem_default=134217728"
        "net.core.rmem_max=134217728"
        "net.core.wmem_default=134217728"
        "net.core.wmem_max=134217728"
        "vm.max_map_count=1000000"
        "fs.nr_open=1000000"
    )
    for param in "${tuning_params[@]}"; do
        if ! grep -q "$param" /etc/sysctl.conf; then
            echo "$param" >> /etc/sysctl.conf
        fi
    done
    sysctl -p
    echo 'DefaultLimitNOFILE=1000000' >> /etc/systemd/system.conf
    echo '* - nofile 1000000' >> /etc/security/limits.conf
    systemctl daemon-reload
    echo "系统调优完成。"
}

# -------------------------
# 模块 7: 开启防火墙
# -------------------------
enable_firewall() {
    echo "开启防火墙..."
    ufw allow 22
    ufw allow 8000:8020/tcp
    ufw allow 8000:8020/udp
    ufw allow 8899
    ufw allow 8900
    ufw enable
    ufw status
}

# -------------------------
# 模块 8: 创建启动脚本和服务
# -------------------------
create_service() {
    echo "创建启动脚本和服务..."

    # 确保 /root/sol 目录存在
    mkdir -p /root/sol/{accounts,ledger,bin}

    # 创建 Solana 验证器启动脚本
    cat > /root/sol/bin/validator.sh << 'EOF'
#!/bin/bash

exec solana-validator \
    --ledger /root/sol/ledger \
    --accounts /root/sol/accounts \
    --identity /root/validator-keypair.json \
    --known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
    --known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
    --known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \
    --known-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
    --full-rpc-api \
    --no-voting \
    --private-rpc \
    --rpc-port 8899 \
    --gossip-port 8001 \
    --dynamic-port-range 8000-8020 \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size \
    --account-index program-id \
    --account-index spl-token-mint \
    --account-index spl-token-owner \
    --enable-rpc-transaction-history \
    --enable-cpi-and-log-storage \
    --init-complete-file /root/init-completed \
    --log /root/solana-rpc.log

    # 以下参数按需选择添加
    # 务必了解每个参数的功能
    # --rpc-bind-address 0.0.0.0 \
    # --tpu-enable-udp \
    # --only-known-rpc \
    # --rpc-send-default-max-retries 0 \
    # --rpc-send-service-max-retries 0 \
    # --rpc-send-retry-ms 2000 \
    # --minimal-snapshot-download-speed 1073741824 \
    # --maximum-snapshot-download-abort 3 \
    # --rpc-send-leader-count 1500 \
    # --private-rpc \
    # --accounts-index-memory-limit-mb 1024000 \
    # --limit-ledger-size 50000000 \
    # --minimal-snapshot-download-speed 1073741824 \
EOF

    # 使启动脚本可执行
    chmod +x /root/sol/bin/validator.sh

    # 创建 systemd 服务文件
    cat > /etc/systemd/system/sol.service << 'EOF'
[Unit]
Description=Solana Validator
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
LimitNOFILE=1000000
LogRateLimitIntervalSec=0
Environment="PATH=/bin:/usr/bin:/root/.local/share/solana/install/active_release/bin"
ExecStart=/root/sol/bin/validator.sh

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载 systemd 配置
    systemctl daemon-reload

    # 启用服务
    systemctl enable sol

    # 启动服务
    systemctl start sol

    # 打印服务状态
    systemctl status sol

    # 打印完成信息并返回主菜单
    echo "Solana 验证器服务已启动并正在运行。"
    menu
}

# -------------------------
# 模块 9: 启动 Solana RPC 节点
# -------------------------
start_solana_rpc() {
    echo "启动 Solana RPC 节点..."
    systemctl start sol
}

# -------------------------
# 模块 10: 查看同步进度
# -------------------------
check_sync_progress() {
    echo "查看同步进度..."
    validator_pubkey=$(solana-keygen pubkey /root/sol/validator-keypair.json)
    echo "您的验证者公钥是：$validator_pubkey"
    solana gossip | grep "$validator_pubkey"
    solana catchup "$validator_pubkey"
}

# -------------------------
# 模块 11: 调整 SWAP 空间
# -------------------------
adjust_swap() {
    echo "调整 SWAP 空间..."
    echo "请输入 SWAP 文件大小（例如：4G）："
    read -p "SWAP 大小: " swap_size
    if [[ -z "$swap_size" ]]; then
        echo "未输入 SWAP 大小，使用默认值 4G。"
        swap_size="4G"
    fi
    fallocate -l "$swap_size" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "SWAP 空间已设置为 $swap_size"
}

# -------------------------
# 模块 12: 服务管理菜单
# -------------------------
service_menu() {
    echo "系统服务管理选项："
    echo "1. 启动服务"
    echo "2. 停止服务"
    echo "3. 查看服务状态"
    echo "4. 重启服务"
    echo "5. 返回主菜单"
    read -p "输入选项：" service_option
    case $service_option in
        1) systemctl start sol;;
        2) systemctl stop sol;;
        3) systemctl status sol;;
        4) systemctl restart sol;;
        5) menu;;
        *) echo "无效选项，请重新输入"; service_menu;;
    esac
}
# -------------------------
# 模块 13: 查看系统服务日志
# -------------------------
view_service_logs() {
    echo "显示最近 50 条系统服务日志..."
    journalctl -u sol -n 50
    echo "按 q 退出日志查看"
    read -p "按回车返回主菜单"
    menu
}

# -------------------------
# 模块 14: 查看 Solana RPC 日志
# -------------------------
view_rpc_logs() {
    echo "============================="
    echo "    Solana RPC 日志查看     "
    echo "============================="
    echo "1. 查看最近 50 条日志"
    echo "2. 实时监控日志"
    echo "3. 返回主菜单"
    echo "============================="
    
    read -p "请选择查看方式 (1-3): " log_option
    
    case $log_option in
        1)
            echo "显示最近 50 条 RPC 日志..."
            tail -n 50 /root/solana-rpc.log
            echo "按回车返回日志菜单"
            read
            view_rpc_logs
            ;;
        2)
            echo "实时监控 RPC 日志... (按 Ctrl+C 退出)"
            tail -f /root/solana-rpc.log
            ;;
        3)
            menu
            ;;
        *)
            echo "无效选项，请重新选择"
            view_rpc_logs
            ;;
    esac
}
# 主程序循环
while true; do
    menu
done
