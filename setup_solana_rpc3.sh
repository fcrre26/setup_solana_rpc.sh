#!/bin/bash

# ====================
# Solana 节点管理脚本
# 基于 Anza 文档：
# - RPC 节点：https://docs.anza.xyz/operations/setup-an-rpc-node
# - 验证节点：https://docs.anza.xyz/operations/setup-a-validator
# ====================

LOG_FILE="/var/log/solana_node_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# 主菜单函数
menu() {
    echo "============================="
    echo "      Solana 节点管理       "
    echo "============================="
    echo "请选择操作："
    echo "1. 安装依赖项和 Rust 工具链"
    echo "2. 挂载磁盘"
    echo "3. 设置 CPU 性能模式"
    echo "4. 下载 Solana CLI"
    echo "5. 创建验证者私钥"
    echo "6. 系统调优"
    echo "7. 开启防火墙"
    echo "8. 创建启动脚本和服务"
    echo "9. 启动 Solana RPC 节点"
    echo "10. 启动 Solana 验证节点"
    echo "11. 查看同步进度"
    echo "12. 调整 SWAP 空间"
    echo "13. 系统服务管理"
    echo "14. 查看日志"
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
        9) start_rpc_node;;
        10) start_validator_node;;
        11) check_sync_progress;;
        12) adjust_swap;;
        13) service_management;;
        14) view_logs;;
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
    mkdir -p /mnt/solana/{ledger,accounts}

    # 自动检测 NVMe 设备
    nvme_devs=$(ls /dev/nvme*n1 2>/dev/null)
    if [ -z "$nvme_devs" ]; then
        echo "未检测到 NVMe 设备，请检查硬件连接。"
        return 1
    fi

    echo "检测到的 NVMe 设备："
    echo "$nvme_devs"
    read -p "请选择第一个磁盘设备（用于 Ledger）： " nvme_ledger
    read -p "请选择第二个磁盘设备（用于 Accounts）： " nvme_accounts

    if [[ ! -e "$nvme_ledger" || ! -e "$nvme_accounts" ]]; then
        echo "选择的磁盘设备无效，请重新选择。"
        return 1
    fi

    echo "Ledger: $nvme_ledger -> /mnt/solana/ledger"
    echo "Accounts: $nvme_accounts -> /mnt/solana/accounts"
    read -p "确认格式化并挂载？输入 yes 继续：" confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "操作取消。"
        return
    fi

    # 格式化并挂载
    mkfs -t ext4 "$nvme_ledger"
    mount "$nvme_ledger" /mnt/solana/ledger
    echo "$nvme_ledger /mnt/solana/ledger ext4 defaults 0 0" >> /etc/fstab

    mkfs -t ext4 "$nvme_accounts"
    mount "$nvme_accounts" /mnt/solana/accounts
    echo "$nvme_accounts /mnt/solana/accounts ext4 defaults 0 0" >> /etc/fstab

    echo "磁盘挂载完成。"
}

# -------------------------
# 模块 3: 设置 CPU 性能模式
# -------------------------
set_cpu_performance() {
    echo "设置 CPU 为 performance 模式..."
    apt install -y linux-tools-common linux-tools-$(uname -r)
    if ! command -v cpupower &>/dev/null; then
        echo "cpupower 未安装，请检查依赖。"
        return 1
    fi
    cpupower frequency-set --governor performance
    echo "CPU 性能模式已设置为 performance。"
}

# -------------------------
# 模块 4: 下载 Solana CLI
# -------------------------
download_solana_cli() {
    echo "下载最新版 Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
    if [ $? -eq 0 ]; then
        echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
        export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
        source ~/.bashrc
        solana --version
        echo "Solana CLI 安装成功。"
    else
        echo "Solana CLI 安装失败，请检查网络连接。"
        return 1
    fi
}

# -------------------------
# 模块 5: 创建验证者私钥
# -------------------------
create_validator_keypair() {
    echo "创建验证者私钥..."
    solana-keygen new -o /mnt/solana/validator-keypair.json
    echo "验证者私钥已创建：/mnt/solana/validator-keypair.json"
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

    cat > /etc/systemd/system/solana-validator.service << 'EOF'
[Unit]
Description=Solana Validator
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
LimitNOFILE=1000000
Environment="PATH=/root/.local/share/solana/install/active_release/bin:/usr/bin:/bin"
ExecStart=/root/.local/share/solana/install/active_release/bin/solana-validator \
    --ledger /mnt/solana/ledger \
    --accounts /mnt/solana/accounts \
    --identity /mnt/solana/validator-keypair.json \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
    --full-rpc-api \
    --no-voting \
    --rpc-port 8899 \
    --gossip-port 8001 \
    --dynamic-port-range 8000-8020 \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size \
    --enable-rpc-transaction-history \
    --log /var/log/solana-validator.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable solana-validator
    echo "Solana 验证节点服务已创建并启用。"
}

# -------------------------
# 模块 9: 启动 Solana RPC 节点
# -------------------------
start_rpc_node() {
    echo "启动 Solana RPC 节点..."
    systemctl start solana-validator
    systemctl status solana-validator
}

# -------------------------
# 模块 10: 启动 Solana 验证节点
# -------------------------
start_validator_node() {
    echo "启动 Solana 验证节点..."
    systemctl start solana-validator
    systemctl status solana-validator
}

# -------------------------
# 模块 11: 查看同步进度
# -------------------------
check_sync_progress() {
    echo "查看同步进度..."
    validator_pubkey=$(solana-keygen pubkey /mnt/solana/validator-keypair.json)
    solana catchup "$validator_pubkey"
}

# -------------------------
# 模块 12: 调整 SWAP 空间
# -------------------------
adjust_swap() {
    echo "调整 SWAP 空间..."
    read -p "请输入 SWAP 文件大小（例如：4G）： " swap_size
    fallocate -l "$swap_size" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "SWAP 空间已设置为 $swap_size"
}

# -------------------------
# 模块 13: 系统服务管理
# -------------------------
service_management() {
    echo "系统服务管理选项："
    echo "1. 启动服务"
    echo "2. 停止服务"
    echo "3. 重启服务"
    echo "4. 查看服务状态"
    echo "5. 返回主菜单"
    read -p "输入选项：" service_option
    case $service_option in
        1) systemctl start solana-validator;;
        2) systemctl stop solana-validator;;
        3) systemctl restart solana-validator;;
        4) systemctl status solana-validator;;
        5) menu;;
        *) echo "无效选项，请重新输入"; service_management;;
    esac
}

# -------------------------
# 模块 14: 查看日志
# -------------------------
view_logs() {
    echo "查看日志..."
    tail -n 50 /var/log/solana-validator.log
    echo "按 q 退出日志查看"
    read -p "按回车返回主菜单"
    menu
}

# 主程序循环
while true; do
    menu
done
