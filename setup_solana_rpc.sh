#!/bin/bash

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
    echo "11. 系统服务管理"
    echo "12. 退出"
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
        11) service_menu;;
        12) exit;;
        *) echo "无效选项，请重新输入";;
    esac
}

# 挂载磁盘
mount_disks() {
    echo "检查并挂载磁盘..."
    mkdir -p /root/sol/{accounts,ledger,bin}

    # 自动检测 NVMe 设备
    nvme_devs=$(ls /dev/nvme*n1 | head -n 1)
    nvme_devs2=$(ls /dev/nvme*n1 | tail -n 1 | head -n 1)

    if [ -z "$nvme_devs" ]; then
        echo "未检测到NVMe设备，请检查硬件连接。"
        return
    fi

    echo "检测到的NVMe设备：$nvme_devs"
    echo "检测到的第二个NVMe设备：$nvme_devs2"

    # 创建文件系统并挂载
    mkfs -t ext4 $nvme_devs
    mount $nvme_devs /root/sol/ledger
    echo "$nvme_devs /root/sol/ledger ext4 defaults 0 0" >> /etc/fstab"

    mkfs -t ext4 $nvme_devs2
    mount $nvme_devs2 /root/sol/accounts
    echo "$nvme_devs2 /root/sol/accounts ext4 defaults 0 0" >> /etc/fstab"

    sync
}

# 设置CPU性能模式
set_cpu_performance() {
    echo "设置CPU为performance模式..."
    apt install linux-tools-common linux-tools-$(uname -r)
    cpupower frequency-set --governor performance
    echo "CPU性能模式已设置为performance。"
    watch "grep 'cpu MHz' /proc/cpuinfo"
}

# 下载Solana CLI
download_solana_cli() {
    echo "下载Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.15/install)"
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> /root/.bashrc
    # 立即更新当前终端的 PATH 环境变量
    export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
    # 验证安装
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
    ufw allow 22
    ufw allow 8000:8020/tcp
    ufw allow 8000:8020/udp
    ufw allow 8899
    ufw allow 8900
    ufw enable
    ufw status
}

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

# 启动Solana RPC节点
start_solana_rpc() {
    echo "启动Solana RPC节点..."
    systemctl start sol
}

# 查看同步进度
check_sync_progress() {
    echo "查看同步进度..."
    validator_pubkey=$(solana-keygen pubkey /root/sol/validator-keypair.json)
    echo "您的验证者公钥是：$validator_pubkey"
    solana gossip | grep "$validator_pubkey"
    solana catchup "$validator_pubkey"
}

# 调整SWAP空间
adjust_swap() {
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
