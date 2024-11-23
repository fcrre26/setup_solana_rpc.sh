#!/bin/bash

# 一键搭建Solana RPC节点脚本

echo "Solana RPC节点搭建脚本"

# 菜单函数
menu() {
    echo "请选择操作："
    echo "1. 挂载磁盘"
    echo "2. 设置CPU性能模式"
    echo "3. 下载Solana CLI"
    echo "4. 创建验证者私钥"
    echo "5. 系统调优"
    echo "6. 开启防火墙"
    echo "7. 创建启动脚本和服务"
    echo "8. 启动Solana RPC节点"
    echo "9. 查看同步进度"
    echo "10. 调整SWAP空间"
    echo "11. 退出"
    read -p "输入选项：" option
    case $option in
        1) mount_disks;;
        2) set_cpu_performance;;
        3) download_solana_cli;;
        4) create_validator_keypair;;
        5) sys_tuning;;
        6) enable_firewall;;
        7) create_service;;
        8) start_solana_rpc;;
        9) check_sync_progress;;
        10) setup_swap;;
        11) exit;;
        *) echo "无效选项，请重新输入";;
    esac
}

# 挂载磁盘
mount_disks() {
    echo "检查并挂载磁盘..."
    mkdir -p /root/sol/{accounts,ledger,bin}

    # 检查是否已经挂载
    if mount | grep -q "/root/sol/ledger"; then
        echo "Ledger disk already mounted."
    else
        fdisk /dev/nvme0n1
        mkfs -t ext4 /dev/nvme0n1
        mount /dev/nvme0n1 /root/sol/ledger
        echo '/dev/nvme0n1 /root/sol/ledger ext4 defaults 0 0' >> /etc/fstab
    fi

    if mount | grep -q "/root/sol/accounts"; then
        echo "Accounts disk already mounted."
    else
        fdisk /dev/nvme1n1
        mkfs -t ext4 /dev/nvme1n1
        mount /dev/nvme1n1 /root/sol/accounts
        echo '/dev/nvme1n1 /root/sol/accounts ext4 defaults 0 0' >> /etc/fstab
    fi

    sync
}

# 设置CPU性能模式
set_cpu_performance() {
    echo "设置CPU为performance模式..."
    apt install linux-tools-common linux-tools-$(uname -r)
    cpupower frequency-set --governor performance
    watch "grep 'cpu MHz' /proc/cpuinfo"
}

# 下载Solana CLI
download_solana_cli() {
    echo "下载Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.15/install)"
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> /root/.bashrc
    source /root/.bashrc
    solana --version
}

# 创建验证者私钥
create_validator_keypair() {
    echo "创建验证者私钥..."
    solana-keygen new -o /root/sol/validator-keypair.json
}

# 系统调优
sys_tuning() {
    echo "进行系统调优..."
    echo -e '# Increase UDP buffer sizes\nnet.core.rmem_default = 134217728\nnet.core.rmem_max = 134217728\nnet.core.wmem_default = 134217728\nnet.core.wmem_max = 134217728' >> /etc/sysctl.conf
    echo -e '# Increase memory mapped files limit\nvm.max_map_count = 1000000' >> /etc/sysctl.conf
    echo -e '# Increase number of allowed open file descriptors\nfs.nr_open = 1000000' >> /etc/sysctl.conf
    sysctl -p
    echo 'DefaultLimitNOFILE=1000000' >> /etc/systemd/system.conf
    systemctl daemon-reload
    echo -e '# Increase process file descriptor count limit\n* - nofile 1000000' >> /etc/security/limits.conf
    ulimit -n 1000000
}

# 开启防火墙
enable_firewall() {
    echo "开启防火墙..."
    sudo ufw allow 22
    sudo ufw allow 8000:8020/tcp
    sudo ufw allow 8000:8020/udp
    sudo ufw allow 8899
    sudo ufw allow 8900
    sudo ufw enable
    sudo ufw status
}

# 创建启动脚本和服务
create_service() {
    echo "创建启动脚本和服务..."
    cat > /root/sol/bin/validator.sh << 'EOF'
#!/bin/bash
exec solana-validator \
    --ledger /root/sol/ledger \
    --accounts /root/sol/accounts \
    --identity /root/sol/validator-keypair.json \
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
EOF
    chmod +x /root/sol/bin/validator.sh
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
    systemctl start sol
    systemctl status sol
    systemctl stop sol
    systemctl restart sol
    systemctl daemon-reload
}

# 启动Solana RPC节点
start_solana_rpc() {
    echo "启动Solana RPC节点..."
    systemctl start sol
}

# 查看同步进度
check_sync_progress() {
    echo "查看同步进度..."
    solana-keygen pubkey /root/sol/validator-keypair.json
    solana gossip | grep {pubkey}
    solana catchup {pubkey}
}

# 调整SWAP空间
setup_swap() {
    echo "调整SWAP空间..."
    echo "请输入SWAP空间大小（例如：120G）："
    read -p "SWAP大小: " swap_size
    if [[ -z "$swap_size" ]]; then
        echo "未输入SWAP空间大小，使用默认值4G。"
        swap_size="4G"
    fi

    # 确保输入以G结尾，如果不是，则添加G
    if [[ "$swap_size" != *G ]]; then
        swap_size+="G"
    fi

    # 创建SWAP文件
    fallocate -l $swap_size /swapfile
    if [ $? -ne 0 ]; then
        echo "创建SWAP文件失败，请检查输入的SWAP空间大小是否正确。"
        return 1
    fi

    # 设置权限并启用SWAP
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "SWAP空间已设置为 $swap_size"
}

# 主循环
while true; do
    menu
done
