# -*- coding: utf-8 -*-
import sys
import subprocess
import os
import ssl
import re

# 添加颜色代码类定义（因为install_dependencies函数会用到）
class Colors:
    """终端颜色代码"""
    HEADER = '\033[95m'      # 紫色
    OKBLUE = '\033[94m'      # 蓝色
    OKGREEN = '\033[92m'     # 绿色
    WARNING = '\033[93m'     # 黄色
    FAIL = '\033[91m'        # 红色
    ENDC = '\033[0m'         # 结束颜色
    BOLD = '\033[1m'         # 加粗
    UNDERLINE = '\033[4m'    # 下划线

# 在Colors类定义后添加
class Icons:
    """终端图标"""
    INFO = "ℹ️ "
    SUCCESS = "✅ "
    WARNING = "⚠️ "
    ERROR = "❌ "
    SCAN = "🔍 "
    CPU = "💻 "
    THREAD = "🧵 "
    STATS = "📊 "
    NODE = "🖥️ "
    SPEED = "⚡ "
    LATENCY = "📡 "
    TIME = "⏱️ "

def install_dependencies():
    """自动安装所需的依赖包"""
    try:
        print(f"{Colors.OKBLUE}[依赖] 正在检查系统依赖...{Colors.ENDC}")
        
        # 检查 solana-cli 是否已安装
        try:
            subprocess.check_output(["solana", "--version"])
            print(f"{Colors.OKGREEN}[成功] Solana CLI 已安装{Colors.ENDC}")
        except:
            print(f"{Colors.WARNING}[安装] 正在安装 Solana CLI...{Colors.ENDC}")
            try:
                # 使用新的安装URL和指定版本
                install_cmd = "sh -c \"$(curl -sSfL https://release.anza.xyz/v2.0.18/install)\""
                subprocess.check_call(install_cmd, shell=True)
                
                # 更新环境变量
                solana_path = "/root/.local/share/solana/install/active_release/bin"
                os.environ["PATH"] = f"{solana_path}:{os.environ['PATH']}"
                
                # 检查安装是否成功
                try:
                    version = subprocess.check_output(["solana", "--version"], env=os.environ).decode().strip()
                    print(f"{Colors.OKGREEN}[成功] Solana CLI {version} 安装完成{Colors.ENDC}")
                except:
                    print(f"{Colors.WARNING}[警告] Solana CLI 已安装但需要重启终端{Colors.ENDC}")
                    print(f"{Colors.WARNING}请运行以下命令或重启终端:{Colors.ENDC}")
                    print(f"export PATH=\"{solana_path}:$PATH\"")
                    return False
                    
            except Exception as e:
                print(f"{Colors.FAIL}[错误] Solana CLI 安装失败: {e}{Colors.ENDC}")
                print(f"{Colors.WARNING}请手动安装 Solana CLI:{Colors.ENDC}")
                print("1. curl -sSfL https://release.anza.xyz/v2.0.18/install | sh")
                print("2. export PATH=\"/root/.local/share/solana/install/active_release/bin:$PATH\"")
                return False
        
        # 更新包列表
        print(f"{Colors.OKBLUE}[系统] 更新包列表...{Colors.ENDC}")
        subprocess.check_call(["apt", "update"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # 系统依赖包
        system_packages = [
            "python3-pip",
            "python3-dev",
            "build-essential",
            "libssl-dev",
            "libffi-dev",
            "python3-setuptools",
            "python3-wheel"
        ]
        
        # 安装系统依赖
        print(f"{Colors.OKBLUE}[系统] 安装系统依赖...{Colors.ENDC}")
        for pkg in system_packages:
            try:
                subprocess.check_call(["apt", "install", "-y", pkg], 
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"{Colors.OKGREEN}[成功] 安装 {pkg}{Colors.ENDC}")
            except:
                print(f"{Colors.WARNING}[警告] 安装 {pkg} 失败{Colors.ENDC}")

        # Python 依赖包
        python_packages = [
            "websocket-client",
            "requests",
            "psutil",
            "urllib3",
            "tabulate",
            "ipaddress"
        ]
        
        # 安装 Python 依赖
        print(f"{Colors.OKBLUE}[Python] 安装 Python 依赖...{Colors.ENDC}")
        for package in python_packages:
            try:
                subprocess.check_call(["pip3", "install", "--upgrade", package],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"{Colors.OKGREEN}[成功] 安装 {package}{Colors.ENDC}")
            except Exception as e:
                print(f"{Colors.WARNING}[警告] 安装 {package} 失败: {e}{Colors.ENDC}")
                return False

        print(f"{Colors.OKGREEN}[完成] 所有依赖安装完成！{Colors.ENDC}")
        return True

    except Exception as e:
        print(f"{Colors.FAIL}[错误] 安装依赖时出错: {e}{Colors.ENDC}")
        print(f"{Colors.WARNING}请手动运行以下命令：{Colors.ENDC}")
        print("apt update")
        print("apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev")
        print("pip3 install websocket-client requests psutil urllib3 tabulate ipaddress")
        print("curl -sSfL https://release.anza.xyz/v2.0.18/install | sh")
        return False

# 在程序开始时检查并安装依赖
if os.geteuid() == 0:  # 检查是否有root权限
    try:
        import websocket
        import requests
        import psutil
        import urllib3
        import tabulate
    except ImportError:
        print("检测到缺少必要的依赖包，正在安装...")
        if not install_dependencies():
            print(f"{Colors.FAIL}[错误] 自动安装依赖失败{Colors.ENDC}")
            print(f"{Colors.WARNING}请确保系统有网络连接并重试{Colors.ENDC}")
            sys.exit(1)
        print("依赖安装完成！")
else:
    print("请使用root权限运行此脚本以自动安装依赖:")
    print("sudo python3 scan_solana_rpc.py")
    sys.exit(1)

# 现在可以安全地导入其他所需模块
import pkg_resources
import requests
import socket
import time
import platform
import json
import websocket
from typing import List, Dict, Tuple, Optional
from subprocess import Popen, PIPE
import ipaddress
import threading
from queue import Queue
from concurrent.futures import ThreadPoolExecutor, as_completed
import psutil
import multiprocessing
import logging
import queue
from multiprocessing import Process
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import asyncio
from collections import OrderedDict
import random
from collections import defaultdict
from collections import Counter
from tabulate import tabulate
from queue import Empty
from threading import Event

# 在文件顶部添加 ScanStats 类定义
class ScanStats:
    """扫描统计信息类，用于跟踪扫描过程中的各种统计数据"""
    def __init__(self):
        self.reset()

    def reset(self):
        """重置所有统计数据"""
        self.total_scanned = 0  # 总扫描数
        self.port_open = 0      # 端口开放数
        self.http_failed = 0    # HTTP失败数
        self.ws_failed = 0      # WebSocket失败数
        self.high_latency = 0   # 延迟超限数
        self.sync_failed = 0    # 同步失败数
        self.valid_nodes = 0    # 有效节点数
        self.valid_nodes_list = []  # 有效节点列表
        self.synced_nodes = 0       # 同步节点数
        self.ws10001_available = 0  # 10001端口可用数

    def update_stats(self, **kwargs):
        """更新统计数据"""
        for key, value in kwargs.items():
            if hasattr(self, key):
                setattr(self, key, getattr(self, key) + value)

    def add_valid_node(self, node_info: Dict):
        """添加新的有效节点并更新统计"""
        self.valid_nodes_list.append(node_info)
        self.valid_nodes = len(self.valid_nodes_list)
        # 更新其他相关统计
        if 'latency' in node_info and node_info['latency'] > 300:
            self.high_latency += 1

    def update_sync_stats(self, is_synced: bool):
        if is_synced:
            self.synced_nodes += 1
            
    def update_ws10001_stats(self, available: bool):
        if available:
            self.ws1001_available += 1

class DisplayManager:
    """显示管理类，负责所有输出的格式化和美化"""
    
    @staticmethod
    def create_time_stats(start_time: float, current: int, total: int) -> str:
        """创建时间统计信息"""
        elapsed = time.time() - start_time
        progress = current / total if total > 0 else 0
        remaining = (elapsed / progress) * (1 - progress) if progress > 0 else 0
        
        # 格式化时间
        def format_time(seconds: float) -> str:
            if seconds < 60:
                return f"{int(seconds)}秒"
            elif seconds < 3600:
                return f"{int(seconds//60)}分{int(seconds%60)}秒"
            else:
                hours = int(seconds // 3600)
                minutes = int((seconds % 3600) // 60)
                return f"{hours}小时{minutes}分"
        
        return (
            f"{Colors.OKBLUE}时间统计:{Colors.ENDC}\n"
            f"- 已用时间: {format_time(elapsed)}\n"
            f"- 剩余时间: {format_time(remaining)}\n"
            f"- 总预计时间: {format_time(elapsed + remaining)}"
        )
    
    @staticmethod
    def create_separator(width: int = 70) -> str:
        """创建分隔线"""
        return "-" * width
    
    @staticmethod
    def create_progress_bar(current: int, total: int, width: int = 40) -> str:
        """创建进度条"""
        progress = current / total if total > 0 else 0
        filled = int(width * progress)
        bar = "#" * filled + "-" * (width - filled)  # 使用#表示已完成，-表示未完成
        percentage = progress * 100
        return f"[{bar}] {current}/{total} ({percentage:.1f}%)"
    
    @staticmethod
    def create_ip_table(ip_segments: Dict[str, Dict]) -> str:
        """创建IP段统计表格"""
        table = []
        table.append("+------------+--------+--------+-----------+------------+")
        table.append("|   IP段     |  总数  |  可用  | 延迟(ms)  |   状态     |")
        table.append("+------------+--------+--------+-----------+------------+")
        
        for ip_segment, data in ip_segments.items():
            row = f"| {ip_segment:<10} | {data['total']:^6} | {data['available']:^6} | "
            row += f"{data['latency']:^9} | {data['status']:^8} |"
            table.append(row)
        
        table.append("+------------+--------+--------+-----------+------------+")
        return "\n".join(table)
    
    @staticmethod
    def create_ip_list_table(valid_ips: List[Dict]) -> str:
        """创建可用IP列表表格"""
        # 表头
        header = "|     IP          | 延迟(ms) |   服务商   |    机房        |         HTTP地址           |         WS地址            | 状态  |"
        separator = "-" * len(header)
        
        table = [separator, header, separator]
        
        # 添加数据行
        for ip_info in valid_ips:
            latency = float(ip_info["latency"])
            # 根据延迟设置状态图标
            status = "[+]" if latency < 200 else "[o]" if latency < 300 else "[-]"
            
            # 格式化每一行
            row = (
                f"| {ip_info['ip']:<14} "
                f"| {latency:^8} "
                f"| {ip_info['provider']:<10} "
                f"| {ip_info['city']:<12} "
                f"| {ip_info['http_url']:<25} "
                f"| {ip_info['ws_url']:<25} "
                f"| {status:^5} |"
            )
            table.append(row)
        
        table.append(separator)
        return "\n".join(table)
    
    @staticmethod
    def print_scan_header():
        """打印扫描开始信息"""
        print(f"\n{Colors.HEADER}开始检测IP可用性...{Colors.ENDC}")
        print(DisplayManager.create_separator())
        print()
    
    @staticmethod
    def print_scan_progress(current_segment: str, segment_progress: Dict, total_progress: Dict):
        """打印扫描进度"""
        # 总体进度显示
        total_segments = total_progress.get('total_segments', 0)
        current_segments = total_progress.get('current_segments', 0)
        print(f"\n{Colors.OKBLUE}总体进度: [{current_segments}/{total_segments}] 个IP段{Colors.ENDC}")
        print(DisplayManager.create_progress_bar(current_segments, total_segments))
        
        # 当前IP段进度
        print(f"{Colors.OKGREEN}当前检测: {current_segment}{Colors.ENDC}")
        print(DisplayManager.create_progress_bar(segment_progress['current'], segment_progress['total']))
        
        # 时间统计信息
        print(DisplayManager.create_time_stats(total_progress['start_time'], current_segments, total_segments))
        
        # CPU和内存使用情况
        cpu_usage = psutil.cpu_percent()
        memory_usage = psutil.virtual_memory().percent
        print(f"{Colors.WARNING}系统状态: CPU {cpu_usage}% | 内存 {memory_usage}%{Colors.ENDC}")
        print()
    
    @staticmethod
    def print_scan_stats(ip_segments: Dict[str, Dict], valid_ips: List[Dict]):
        """打印扫描统计信息"""
        print("当前IP段统计:")
        print(DisplayManager.create_ip_table(ip_segments))
        print(DisplayManager.create_separator())
        
        total_checked = sum(seg["total"] for seg in ip_segments.values())
        total_available = sum(seg["available"] for seg in ip_segments.values())
        success_rate = (total_available / total_checked * 100) if total_checked > 0 else 0
        
        print("实时统计:")
        print(f"- 已检测IP段: {len(ip_segments)}/3")
        print(f"- 当前成功率: {total_available}/{total_checked} ({success_rate:.1f}%)")
        
        if valid_ips:
            print("\n[发现可用IP] - 已保存到 valid_ips.txt")
            print("可用IP列表 (实时更新):")
            separator = "-" * 120
            print(separator)
            print(DisplayManager.create_ip_list_table(valid_ips))
            print(separator)
    
    @staticmethod
    def print_scan_complete(ip_segments: Dict[str, Dict], start_time: float):
        """打印扫描完成信息"""
        print("\n[检测完成]\n")
        print("检测完成!")
        
        for ip_segment, data in ip_segments.items():
            success_rate = (data["available"] / data["total"] * 100)
            status = "优秀" if success_rate >= 70 else "良好" if success_rate >= 50 else "较差"
            print(f"{ip_segment}: {data['available']}/{data['total']} ({success_rate:.1f}%) - {status}")
        
        elapsed = time.time() - start_time
        total_ips = sum(seg["total"] for seg in ip_segments.values())
        speed = total_ips / elapsed if elapsed > 0 else 0
        
        print(f"\n总耗时: {elapsed:.1f}秒")
        print(f"检测速度: {speed:.1f} IP/s")

    @staticmethod
    def print_scan_process():
        """打印扫描过程信息"""
        print(f"\n{Colors.HEADER}=== 扫描过程信息 ==={Colors.ENDC}")
        print(f"{Colors.OKBLUE}正在扫描IP段...{Colors.ENDC}")
        print(f"{Colors.WARNING}请稍候，扫描完成后将显示结果。{Colors.ENDC}")
        print(DisplayManager.create_separator())

def check_and_install_dependencies():
    """检查并安装所需的依赖包"""
    required_packages = {
        'requests': 'requests',
        'websocket-client': 'websocket-client',
        'psutil': 'psutil',
        'urllib3': 'urllib3',
        'ipinfo': 'ipinfo',  # 新增IPinfo官方库
        'tabulate': 'tabulate'  # 新增表格依赖
    }
    
    try:
        import pkg_resources
    except ImportError:
        print("\n[初始化] 正在安装 setuptools...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "setuptools"])
            import pkg_resources
        except Exception as e:
            print(f"[错误] 安装 setuptools 失败: {e}")
            sys.exit(1)
    
    installed_packages = {pkg.key for pkg in pkg_resources.working_set}
    
    packages_to_install = []
    for package, pip_name in required_packages.items():
        if package not in installed_packages:
            packages_to_install.append(pip_name)
    
    if packages_to_install:
        print("\n[初始化] 正在安装所需依赖...")
        for package in packages_to_install:
            print(f"[安装] {package}")
            try:
                # 添加--user参数以避免权限问题
                subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", package])
                print(f"[完成] {package} 安装成功")
            except subprocess.CalledProcessError as e:
                print(f"[错误] 安装 {package} 失败，尝试使用 sudo...")
                try:
                    subprocess.check_call(["sudo", sys.executable, "-m", "pip", "install", package])
                    print(f"[完成] {package} 安装成功")
                except:
                    print(f"[错误] 安装 {package} 失败: {e}")
                    print("[提示] 请手动执行以下命令安装依赖：")
                    print(f"sudo pip3 install {package}")
                    sys.exit(1)
        print("[完成] 所有依赖安装完成\n")

# ASN映射表
ASN_MAP = {
    "TERASWITCH": "397391",
    "LATITUDE-SH": "137409",
    "OVH": "16276",
    "Vultr": [
        "20473",  # Vultr主要ASN
        "64515",  # Vultr Holdings LLC
        "396998", # Vultr Holdings LLC IPv6
        "401886", # Vultr Holdings LLC
        "399471", # Vultr Holdings LLC
        "399470", # Vultr Holdings LLC
        "399469"  # Vultr Holdings LLC
    ],
    "UAB Cherry Servers": "24940",
    "Amazon AWS": "16509",
    "WEBNX": "18450",
    "LIMESTONENETWORKS": "46475",
    "PACKET": "54825",
    "Amarutu Technology Ltd": "212238",
    "IS-AS-1": "57344",
    "velia.net Internetdienste": "47447",
    "ServeTheWorld AS": "34863",
    "MEVSPACE": "211680",
    "SYNLINQ": "34927",
    "TIER-NET": "12182",
    "Latitude.sh LTDA": "137409",
    "HVC-AS": "42831",
    "Hetzner": "24940",
    "AS-30083-US-VELIA-NET": "30083",
    "DigitalOcean": "14061",
    "AWS": ["16509", "14618"],
    "GCP": "15169",
    "Linode": "63949"
}

# 配置文件路径
CONFIG_FILE = 'config.json'

# 默认配置
DEFAULT_CONFIG = {
    "ipinfo_token": "",
    "timeout": 2,
    "max_retries": 3,
    "max_threads": 1000,  # 最大线程数
    "batch_size": 100,     # 批处理大小
    "strict_mode": True,    # 严格检查模式
    "mainnet_rpc_nodes": [
        "https://api.mainnet-beta.solana.com",
        "https://ssc-dao.genesysgo.net"
    ],
    "ws_10001_check": True,
    "max_slot_diff": 200,  # 添加默认的最大slot差异值
    "scan_timeout": {
        "port": 1,
        "http": 3,
        "ws": 2
    }
}

def validate_config(config: Dict) -> Dict:
    """验证并补充配置文件"""
    default_config = DEFAULT_CONFIG.copy()
    
    # 如果提供的配置为空，返回默认配置
    if not config:
        return default_config
        
    # 递归合并配置
    for key, value in default_config.items():
        if key not in config:
            config[key] = value
        elif isinstance(value, dict) and isinstance(config[key], dict):
            config[key] = validate_config(config[key])
            
    return config

def load_config() -> Dict:
    """加载配置文件"""
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, 'r') as f:
                return json.load(f)
        return {}
    except Exception as e:
        print(f"{Colors.WARNING}[警告] 加载配置文件失败: {e}{Colors.ENDC}")
        return {}

def save_config(config: Dict):
    """保存配置文件"""
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=4)
    except Exception as e:
        print(f"{Colors.FAIL}[错误] 保存配置文件失败: {e}{Colors.ENDC}")

def parse_memory(mem_str: str) -> int:
    """将内存字符串转换为MB"""
    units = {"K": 1, "M": 1024, "G": 1024**2, "T": 1024**3}
    unit = mem_str[-1]
    return int(float(mem_str[:-1]) * units[unit])

def load_providers() -> List[str]:
    """从文件加载服务商列表"""
    try:
        with open('providers.txt', 'r') as f:
            return [line.strip() for line in f.readlines() if line.strip()]
    except FileNotFoundError:
        return list(ASN_MAP.keys())  # 如果文件不存在，返回所有支持的服务商

def save_providers(providers: List[str]):
    """保存服务商列表到文件"""
    with open('providers.txt', 'w') as f:
        f.write('\n'.join(providers))

def batch_process_ips(ips: List[str]) -> List[str]:
    """批量处理IP检查，提高效率"""
    potential_ips = []
    # 增加批处理大小
    batch_size = 100  # 从20增加到100
    
    # 使用异步IO并行检查多个IP
    with ThreadPoolExecutor(max_workers=batch_size) as executor:
        futures = []
        for ip in ips:
            future = executor.submit(is_potential_rpc, ip)
            futures.append((ip, future))
        
        # 使用as_completed而不是等待所有完成
        for ip, future in futures:
            try:
                if future.result(timeout=2):  # 添加超时控制
                    potential_ips.append(ip)
            except:
                continue
    return potential_ips

def subnet_worker():
    """优化的子网扫描工作线程"""
    while not stop_event.is_set():
        try:
            subnet = subnet_queue.get_nowait()
            subnet_ips = list(subnet.hosts())
            total_ips = len(subnet_ips)
            
            # 优化采样策略
            if total_ips <= 256:
                sample_rate = 0.2  # 小子网降低到20%
            elif total_ips <= 1024:
                sample_rate = 0.1  # 中等子网降低到10%
            else:
                sample_rate = 0.05  # 大子网降低到5%
            
            # 智能选择采样点
            sample_count = max(20, int(total_ips * sample_rate))
            step = max(1, total_ips // sample_count)
            
            # 优先扫描常用端口范围
            priority_ranges = [
                (0, 10),      # 网段开始
                (245, 255),   # 网段结束
                (80, 90),     # 常用端口区域
                (8000, 8010), # 常用端口区域
            ]
            
            sample_ips = []
            for start, end in priority_ranges:
                for i in range(start, min(end, total_ips)):
                    sample_ips.append(str(subnet_ips[i]))
            
            # 在其他区域进行稀疏采样
            for i in range(0, total_ips, step):
                if not any(start <= i <= end for start, end in priority_ranges):
                    sample_ips.append(str(subnet_ips[i]))
            
            # 并行扫描采样IP
            potential_ips = batch_process_ips(sample_ips)
            
            # 发现节点时进行局部加密扫描
            if potential_ips:
                for potential_ip in potential_ips:
                    ip_obj = ipaddress.ip_address(potential_ip)
                    # 扫描前后各4个IP(从8个减少到4个)
                    for i in range(-4, 5):
                        try:
                            nearby_ip = str(ip_obj + i)
                            if ipaddress.ip_address(nearby_ip) in subnet:
                                ip_queue.put(nearby_ip)
                        except:
                            continue
            
            subnet_queue.task_done()
            
        except Empty:
            break

def is_potential_rpc(ip: str) -> bool:
    """优化的RPC节点预检查"""
    try:
        # 减少超时时间
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)  # 从1秒减少到0.5秒
        result = sock.connect_ex((ip, 8899))
        sock.close()
        
        if result != 0:
            return False
        
        # 快速RPC检查
        try:
            response = requests.post(
                f"http://{ip}:8899",
                json={"jsonrpc": "2.0", "id": 1, "method": "getHealth"},
                headers={"Content-Type": "application/json"},
                timeout=1  # 从2秒减少到1秒
            )
            if response.status_code == 200 and "result" in response.json():
                return True
        except:
            pass
        
        return True
    except:
        return False

def get_optimal_thread_count() -> int:
    """优化后的线程数计算"""
    cpu_count = os.cpu_count() or 8
    return min(cpu_count * 1000, 10000)  # 提升到10000线程

def verify_worker():
    """优化的验证工作线程"""
    while not stop_event.is_set():
        try:
            # 增加批处理大小
            ips = []
            for _ in range(10):  # 从5增加到10
                try:
                    ips.append(potential_queue.get_nowait())
                except Empty:
                    break
            
            if not ips:
                time.sleep(0.05)  # 减少等待时间
                continue
            
            # 并行验证IP
            with ThreadPoolExecutor(max_workers=len(ips)) as executor:
                futures = [executor.submit(scan_ip, ip, provider, config) for ip in ips]
                for ip, future in zip(ips, futures):
                    try:
                        result = future.result(timeout=3)  # 添加超时控制
                        if result:
                            verified_queue.put(result)
                            with verified_nodes_count.get_lock():
                                verified_nodes_count.value += 1
                    except:
                        pass
                    finally:
                        potential_queue.task_done()
        except:
            continue

class DynamicThreadPool:
    """动态调整的线程池"""
    def __init__(self, max_workers=None):
        self.max_workers = max_workers or (os.cpu_count() * 50)
        self.executor = ThreadPoolExecutor(max_workers=self.max_workers)
        self._adjust_interval = 5  # 每5秒调整一次
        self._last_adjust = time.time()
        
    def adjust_pool(self, qsize):
        """根据队列长度动态调整线程数"""
        if time.time() - self._last_adjust > self._adjust_interval:
            new_size = min(
                self.max_workers,
                max(50, int(qsize * 0.2))  # 根据队列长度动态调整
            )
            if new_size != self.executor._max_workers:
                self.executor._max_workers = new_size
                print_status(f"动态调整线程数为 {new_size}", "thread")
            self._last_adjust = time.time()

class GeoCache:
    """地理位置信息缓存"""
    def __init__(self, max_size=1000):
        self.cache = OrderedDict()
        self.max_size = max_size
        
    def get(self, ip: str) -> Optional[Dict]:
        if ip in self.cache:
            self.cache.move_to_end(ip)
            return self.cache[ip]
        return None
        
    def set(self, ip: str, info: Dict):
        if ip in self.cache:
            self.cache.move_to_end(ip)
        else:
            self.cache[ip] = info
            if len(self.cache) > self.max_size:
                self.cache.popitem(last=False)

# 在全局初始化
GEO_CACHE = GeoCache()

def scan_network(network: ipaddress.IPv4Network, provider: str) -> List[str]:
    """扫描IPv4网段"""
    # 强制转换为IPv4Network类型
    if not isinstance(network, ipaddress.IPv4Network):
        print_status(f"跳过非IPv4网段 {network}", "warning")
        return []
    verified_nodes = []
    thread_count = get_optimal_thread_count()
    config = load_config()
    
    # 计算总IP数
    total_ips = sum(1 for _ in network.hosts())
    
    # 使用新的显示管理器
    DisplayManager.print_scan_header()
    
    # IP段统计信息
    ip_segments = {
        str(network): {
            "total": total_ips,
            "available": 0,
            "latency": 0,
            "status": "scanning"
        }
    }
    
    # 打印扫描信息
    print_status(f"开始扫描网段: {network}", "scan")
    print_status(f"预计扫描IP数量: {total_ips}", "info")
    
    # 跳过IPv6网段
    if isinstance(network, ipaddress.IPv6Network):
        print_status(f"跳过IPv6网段 {network}", "warning")
        return []
    
    # 使用高效的队列
    ip_queue = Queue(maxsize=10000)
    potential_queue = Queue()
    verified_queue = Queue()
    
    # 使用原子计数器
    scanned_ips = multiprocessing.Value('i', 0)
    potential_nodes = multiprocessing.Value('i', 0)
    verified_nodes_count = multiprocessing.Value('i', 0)
    
    # 创建事件和锁
    stop_event = threading.Event()
    thread_lock = threading.Lock()
    
    def update_progress():
        """更新进度信息"""
        with scanned_ips.get_lock():
            current = scanned_ips.value
            if current % 100 == 0:  # 每扫描100个IP更新一次进度
                segment_progress = {
                    "current": current,
                    "total": total_ips
                }
                total_progress = {
                    "current": 1,
                    "total": 1,
                    "scanned": current,
                    "total_ips": total_ips
                }
                DisplayManager.print_scan_progress(str(network), segment_progress, total_progress)
                DisplayManager.print_scan_stats(ip_segments, verified_nodes)
    
    def scan_worker():
        """内存优化版扫描线程"""
        batch_size = 1000  # 增大批处理量
        while True:
            batch = []
            try:
                for _ in range(batch_size):
                    batch.append(ip_queue.get_nowait())
            except Empty:
                if batch:
                    process_batch(batch)  # 批量处理
                time.sleep(0.01)
                continue
    
    def verify_worker():
        """优化的验证工作线程"""
        while not stop_event.is_set():
            try:
                # 批量获取待验证的IP
                ips = []
                for _ in range(5):  # 每次验证5个IP
                    try:
                        ips.append(potential_queue.get_nowait())
                    except Empty:
                        break
                
                if not ips:
                    time.sleep(0.1)
                    continue
                
                # 并行验证IP
                with ThreadPoolExecutor(max_workers=len(ips)) as executor:
                    futures = [executor.submit(scan_ip, ip, provider, config) for ip in ips]
                    for ip, future in zip(ips, futures):
                        try:
                            result = future.result()
                            if result:
                                verified_queue.put(result)
                                with verified_nodes_count.get_lock():
                                    verified_nodes_count.value += 1
                                print_status(
                                    f"发现可用节点: {ip} "
                                    f"({result['city']}, {result['country']}) "
                                    f"延迟: {result['latency']:.1f}ms",
                                    "success"
                                )
                        except Exception as e:
                            print_status(f"验证节点 {ip} 失败: {e}", "error")
                        finally:
                            potential_queue.task_done()
                            
            except Exception as e:
                print_status(f"验证线程异常: {e}", "error")
                continue
    
    # 小网段完整扫描
    if network.prefixlen >= 24:
        ips = [str(ip) for ip in network.hosts()]
        print_status(f"扫描小网段 {network}，共 {len(ips)} 个IP", "scan")
        
        # 将IP加入队列
        for ip in ips:
            ip_queue.put(ip)
        
        # 启动线程
        threads = []
        
        # 启动扫描线程
        for _ in range(thread_count):
            t = threading.Thread(target=scan_worker)
            t.daemon = True
            t.start()
            threads.append(t)
        
        # 启动验证线程
        verify_thread_count = max(10, thread_count // 5)
        for _ in range(verify_thread_count):
            t = threading.Thread(target=verify_worker)
            t.daemon = True
            t.start()
            threads.append(t)
        
        # 等待完成
        ip_queue.join()
        potential_queue.join()
        
    else:
        # 大网段智能扫描
        subnets = list(network.subnets(new_prefix=24))
        print_status(f"扫描大网段 {network}，分割为 {len(subnets)} 个/24子网", "scan")
        
        # 创建子网队列
        subnet_queue = Queue()
        for subnet in subnets:
            subnet_queue.put(subnet)
        
        def subnet_worker():
            """子网扫描工作线程"""
            while not stop_event.is_set():
                try:
                    # 批量处理子网
                    subnets_to_process = []
                    for _ in range(5):
                        try:
                            subnets_to_process.append(subnet_queue.get_nowait())
                        except Empty:
                            break
                    
                    if not subnets_to_process:
                        break
                    
                    for subnet in subnets_to_process:
                        # 智能采样
                        subnet_ips = list(subnet.hosts())
                        total_ips = len(subnet_ips)
                        
                        # 动态调整采样率
                        if total_ips <= 256:
                            sample_rate = 0.5  # 小子网采样50%
                        elif total_ips <= 1024:
                            sample_rate = 0.3  # 中等子网采样30%
                        else:
                            sample_rate = 0.1  # 大子网采样10%
                        
                        sample_count = max(50, int(total_ips * sample_rate))
                        step = max(1, total_ips // sample_count)
                        
                        # 智能选择采样点
                        sample_ips = []
                        for i in range(0, total_ips, step):
                            sample_ips.append(str(subnet_ips[i]))
                        
                        # 额外采样网段边界
                        if len(sample_ips) > 2:
                            sample_ips[0] = str(subnet_ips[0])  # 网段开始
                            sample_ips[-1] = str(subnet_ips[-1])  # 网段结束
                        
                        # 并行扫描采样IP
                        potential_ips = batch_process_ips(sample_ips)
                        
                        # 如果发现潜在节点，增加采样密度
                        if potential_ips:
                            print_status(f"子网 {subnet} 发现潜在节点，增加采样密度", "info")
                            # 在发现节点周围增加采样点
                            for potential_ip in potential_ips:
                                ip_obj = ipaddress.ip_address(potential_ip)
                                # 扫描前后各8个IP
                                for i in range(-8, 9):
                                    try:
                                        nearby_ip = str(ip_obj + i)
                                        if ipaddress.ip_address(nearby_ip) in subnet:
                                            ip_queue.put(nearby_ip)
                                    except:
                                        continue
                        
                        subnet_queue.task_done()
                        
                except Exception as e:
                    print_status(f"子网扫描异常: {e}", "error")
                    for _ in range(len(subnets_to_process)):
                        subnet_queue.task_done()
                    continue
        
        # 启动子网扫描线程
        subnet_threads = []
        for _ in range(thread_count):
            t = threading.Thread(target=subnet_worker)
            t.daemon = True
            t.start()
            subnet_threads.append(t)
        
        # 等待子网扫描完成
        subnet_queue.join()
    
    # 停止所有线程
    stop_event.set()
    
    # 收集结果
    while not verified_queue.empty():
        verified_nodes.append(verified_queue.get())
    
    # 打印统计信息
    print_status(f"\n扫描完成: {network}", "success")
    print_status(f"总计扫描IP: {scanned_ips.value}", "stats")
    print_status(f"发现潜在节点: {potential_nodes.value}", "stats")
    print_status(f"验证可用节点: {verified_nodes_count.value}", "stats")
    
    return verified_nodes

class ASNFileCache:
    """ASN文件缓存系统"""
    def __init__(self, cache_dir="/root/.asn_cache"):
        self.cache_dir = cache_dir
        if not os.path.exists(cache_dir):
            os.makedirs(cache_dir)
            
    def get(self, asn: str) -> Optional[List[str]]:
        """从缓存获取ASN的IP段"""
        cache_file = os.path.join(self.cache_dir, f"asn_{asn}.json")
        if os.path.exists(cache_file):
            # 检查缓存是否过期（24小时）
            if time.time() - os.path.getmtime(cache_file) < 24 * 3600:
                try:
                    with open(cache_file, 'r') as f:
                        return json.load(f)
                except:
                    return None
        return None
        
    def set(self, asn: str, prefixes: List[str]):
        """将ASN的IP段存入缓存"""
        cache_file = os.path.join(self.cache_dir, f"asn_{asn}.json")
        try:
            with open(cache_file, 'w') as f:
                json.dump(prefixes, f)
        except Exception as e:
            print(f"[警告] 缓存ASN {asn}失败: {e}")

# 初始化全局缓存对象
ASN_CACHE = ASNFileCache()

def get_asn_prefixes(asn: str) -> List[str]:
    """获取ASN的IP段列表（带缓存）"""
    # 先尝试从缓存获取
    if cached := ASN_CACHE.get(asn):
        print(f"[信息] 从缓存获取到ASN {asn}的IP段: {len(cached)}个")
        return cached
        
    try:
        # 从BGP.HE.NET获取
        url = f"https://bgp.he.net/AS{asn}#_prefixes"
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, headers=headers, timeout=10)
        
        if response.status_code == 200:
            # 使用正则提取IPv4段
            import re
            pattern = r'href="/net/(\d+\.\d+\.\d+\.\d+/\d+)"'
            prefixes = re.findall(pattern, response.text)
            
            if prefixes:
                print(f"[信息] 从BGP.HE.NET获取到 {len(prefixes)} 个IP段")
                # 保存到缓存
                ASN_CACHE.set(asn, prefixes)
                return prefixes
                
        print(f"[警告] 未能从BGP.HE.NET获取到ASN {asn}的IP段，使用内置IP段")
        
        # 使用内置IP段作为后备
        if asn == "20473":  # Vultr
            prefixes = [
                "45.32.0.0/16",     # Vultr Tokyo
                "45.63.0.0/16",     # Vultr New Jersey
                "45.76.0.0/16",     # Vultr Los Angeles
                "45.77.0.0/16",     # Vultr Frankfurt
                "66.42.0.0/16",     # Vultr Singapore
                "95.179.128.0/17",  # Vultr Amsterdam
                "104.156.224.0/19", # Vultr Seattle
                "104.238.128.0/17", # Vultr Silicon Valley
                "108.61.0.0/16",    # Vultr Chicago
                "149.28.0.0/16",    # Vultr Sydney
                "155.138.0.0/16",   # Vultr Miami
                "207.246.64.0/18",  # Vultr Paris
                "208.167.224.0/19"  # Vultr London
            ]
            print(f"[信息] 使用内置IP段: {len(prefixes)} 个")
            # 保存到缓存
            ASN_CACHE.set(asn, prefixes)
            return prefixes
            
        return []
        
    except Exception as e:
        print(f"[错误] 获取ASN {asn}的IP段失败: {e}")
        return []

def is_solana_rpc(ip: str) -> bool:
    """测试IP是否是Solana RPC节点"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)  # 超时时间改小了，应该改回2-3秒
    try:
        result = sock.connect_ex((ip, 8899))
        if result == 0:
            # 增加更严格的HTTP检查
            try:
                url = f"http://{ip}:8899"
                response = requests.post(
                    url,
                    json={
                        "jsonrpc": "2.0",
                        "id": 1,
                        "method": "getHealth"
                    },
                    headers={"Content-Type": "application/json"},
                    timeout=3
                )
                # 检查响应内容而不是仅检查状态码
                return response.status_code == 200 and "result" in response.json()
            except:
                return False
        return False
    except:
        return False
    finally:
        sock.close()

def get_ip_info(ip: str, config: Dict) -> Optional[Dict]:
    """获取IP信息"""
    token = config.get('ipinfo_token')
    if not token:
        print(f"{Colors.WARNING}[警告] 未配置 IPInfo Token{Colors.ENDC}")
        return None
        
    try:
        headers = {'Authorization': f'Bearer {token}'}
        response = requests.get(f'https://ipinfo.io/{ip}', headers=headers, timeout=5)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"{Colors.WARNING}[警告] 获取IP信息失败: {response.status_code}{Colors.ENDC}")
            return None
            
    except Exception as e:
        print(f"{Colors.WARNING}[警告] 获取IP信息出错: {str(e)}{Colors.ENDC}")
        return None

def get_latency(ip: str) -> float:
    """测试IP的延迟"""
    try:
        if platform.system().lower() == "windows":
            cmd = ["ping", "-n", "1", "-w", "2000", ip]
        else:
            cmd = ["ping", "-c", "1", "-W", "2", ip]
            
        process = Popen(cmd, stdout=PIPE, stderr=PIPE)
        output, _ = process.communicate()
        output = output.decode()
        
        if platform.system().lower() == "windows":
            if "平均 = " in output:
                latency = output.split("平均 = ")[-1].split("ms")[0].strip()
            elif "Average = " in output:
                latency = output.split("Average = ")[-1].split("ms")[0].strip()
            else:
                return 999.99
        else:
            if "min/avg/max" in output:
                latency = output.split("min/avg/max")[1].split("=")[1].split("/")[1].strip()
            else:
                return 999.99
                
        return float(latency)
    except:
        return 999.99

def test_http_rpc(ip: str) -> Tuple[bool, str]:
    """测试HTTP RPC连接"""
    url = f"http://{ip}:8899"
    headers = {
        "Content-Type": "application/json"
    }
    # 测试多个RPC方法确保节点真正可用
    test_methods = [
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "getHealth"
        },
        {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "getVersion"
        },
        {
            "jsonrpc": "2.0",
            "id": 3,
            "method": "getSlot"
        }
    ]
    
    try:
        for method in test_methods:
            response = requests.post(url, headers=headers, json=method, timeout=5)
            if response.status_code != 200 or "result" not in response.json():
                return False, ""
        return True, url
    except:
        return False, ""

def test_ws_rpc(ip: str) -> Tuple[bool, str]:
    """测试WebSocket RPC连接"""
    url = f"ws://{ip}:8900"
    try:
        ws = websocket.create_connection(url, timeout=5)
        # 测试多个RPC方法
        test_methods = [
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "getHealth"
            },
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "getVersion"
            }
        ]
        
        for method in test_methods:
            ws.send(json.dumps(method))
            result = ws.recv()
            if "result" not in json.loads(result):
                ws.close()
                return False, ""
                
        ws.close()
        return True, url
    except:
        return False, ""

def print_status(msg: str, status: str = "info", end: str = "\n"):
    """增强的状态打印函数，支持更多样式和格式"""
    status_formats = {
        "info": (Colors.OKBLUE, Icons.INFO, "信息"),
        "success": (Colors.OKGREEN, Icons.SUCCESS, "成功"),
        "warning": (Colors.WARNING, Icons.WARNING, "警告"),
        "error": (Colors.FAIL, Icons.ERROR, "错误"),
        "scan": (Colors.OKBLUE, Icons.SCAN, "扫描"),
        "system": (Colors.HEADER, Icons.CPU, "系统"),
        "thread": (Colors.OKBLUE, Icons.THREAD, "线程"),
        "stats": (Colors.OKGREEN, Icons.STATS, "统计"),
        "node": (Colors.OKGREEN, Icons.NODE, "节点"),
        "progress": (Colors.WARNING, Icons.SPEED, "进度"),
        "network": (Colors.OKBLUE, Icons.LATENCY, "网络"),
        "time": (Colors.HEADER, Icons.TIME, "时间")
    }
    
    color, icon, prefix = status_formats.get(status, (Colors.ENDC, "", ""))
    timestamp = time.strftime("%H:%M:%S")
    print(f"{color}{icon}[{timestamp}] [{prefix}] {msg}{Colors.ENDC}", end=end)

def create_progress_bar(progress: float, width: int = 50, style: str = "standard") -> str:
    """创建美观的进度条"""
    styles = {
        "standard": ("#", "-"),
        "blocks": ("█", "░"),
        "dots": ("●", "○"),
        "arrows": ("►", "─")
    }
    
    fill_char, empty_char = styles.get(style, styles["standard"])
    filled = int(width * progress)
    bar = fill_char * filled + empty_char * (width - filled)
    return f"[{bar}] {progress*100:.1f}%"

def format_table_row(data: Dict[str, str], widths: Dict[str, int], colors: Dict[str, str] = None) -> str:
    """格式化表格行，支持颜色和对齐"""
    if colors is None:
        colors = {}
    
    row = []
    for key, width in widths.items():
        value = str(data.get(key, ""))
        color = colors.get(key, Colors.ENDC)
        padding = " " * (width - len(value))
        row.append(f"{color}{value}{padding}{Colors.ENDC}")
    
    return " | ".join(row)

def save_results(results: List[Dict]):
    """保存为表格格式"""
    with open("scan_results.txt", "w") as f:
        f.write(f"=== 扫描结果 {time.strftime('%Y-%m-%d %H:%M:%S')} ===\n")
        f.write(f"总节点数: {len(results)}\n\n")
        
        # 表格数据
        headers = ["IP", "延迟(ms)", "机房", "地区", "国家", "供应商", "HTTP地址", "WS地址"]  # 添加供应商列
        rows = []
        for res in sorted(results, key=lambda x: x['latency']):
            # 确保生成 http_url 和 ws_url
            ip = res['ip'].split(':')[0]  # 移除端口号
            rows.append([
                res['ip'],
                f"{res['latency']:.1f}",
                res.get('city', 'Unknown'),
                res.get('region', 'Unknown'),
                res.get('country', 'Unknown'),
                res.get('provider', 'Unknown'),  # 添加供应商信息
                f"http://{ip}:8899",
                f"ws://{ip}:8900"
            ])
        
        f.write(tabulate(rows, headers, tablefmt="grid"))
        
        # 统计信息
        f.write("\n\n=== 统计信息 ===\n")
        avg_latency = sum(r['latency'] for r in results) / len(results)
        f.write(f"平均延迟: {avg_latency:.1f}ms\n")
        # 更多统计...

def show_menu():
    """显示主菜单"""
    menu_width = 60  # 设置菜单总宽度
    title = "=== Solana RPC节点扫描器 ==="
    menu = f"""
{Colors.OKGREEN}{Colors.BOLD}{'='*menu_width}
{title:^{menu_width}}
{'='*menu_width}{Colors.ENDC}

{Colors.OKGREEN}[1]. 显示所有支持的服务商     [2]. 添加扫描服务商{Colors.ENDC}
{Colors.OKGREEN}[3]. 查看当前服务商列表       [4]. 清空服务商列表{Colors.ENDC}
{Colors.OKGREEN}[5]. 开始全面扫描             [6]. 快速扫描Vultr{Colors.ENDC}
{Colors.OKGREEN}[7]. 后台扫描模式             [8]. 查看扫描进度{Colors.ENDC}
{Colors.OKGREEN}[9]. 测试节点质量             [10]. 配置IPinfo API{Colors.ENDC}
{Colors.OKGREEN}[11]. 扫描所有内置供应商      [12]. 扫描验证者子网{Colors.ENDC}
{Colors.OKGREEN}[13]. 智能扫描验证者子网      [0]. 退出程序{Colors.ENDC}

{Colors.OKGREEN}{Colors.BOLD}{'='*menu_width}{Colors.ENDC}
"""
    print(menu)

def configure_ipinfo():
    """配置 IPInfo API Token"""
    print(f"\n{Colors.HEADER}[配置] IPInfo API Token{Colors.ENDC}")
    
    # 加载当前配置
    config = load_config()
    if not isinstance(config, dict):
        config = {}
    
    current_token = config.get("ipinfo_token", "")
    if current_token:
        print(f"{Colors.OKBLUE}当前 Token: {current_token}{Colors.ENDC}")
    else:
        print(f"{Colors.WARNING}当前未配置 Token{Colors.ENDC}")
    
    print("\n请输入 IPInfo API Token (直接回车保持不变):")
    new_token = input().strip()
    
    if new_token:
        config["ipinfo_token"] = new_token
        save_config(config)
        print(f"{Colors.OKGREEN}[成功] Token 已更新{Colors.ENDC}")
    else:
        print(f"{Colors.WARNING}[信息] Token 未更改{Colors.ENDC}")
    
    # 无论是新token还是保持现有token，都进行测试
    token_to_test = new_token if new_token else current_token
    if token_to_test:
        print(f"\n{Colors.OKBLUE}[测试] 正在测试 Token...{Colors.ENDC}")
        try:
            test_ip = "8.8.8.8"  # 用 Google DNS 测试
            headers = {'Authorization': f'Bearer {token_to_test}'}
            response = requests.get(f'https://ipinfo.io/{test_ip}', headers=headers, timeout=5)
            
            if response.status_code == 200:
                print(f"{Colors.OKGREEN}[成功] Token 有效{Colors.ENDC}")
                data = response.json()
                print(f"测试结果: {data.get('city', 'Unknown')}, {data.get('country', 'Unknown')}")
            else:
                print(f"{Colors.FAIL}[错误] Token 无效: {response.status_code}{Colors.ENDC}")
        except Exception as e:
            print(f"{Colors.FAIL}[错误] 测试失败: {str(e)}{Colors.ENDC}")

def save_progress(provider: str, scanned: int, total: int, found: int):
    """保存扫描进度"""
    progress = {
        "provider": provider,
        "scanned": scanned,
        "total": total,
        "found": found,
        "last_update": time.strftime("%Y-%m-%d %H:%M:%S")
    }
    with open("scan_progress.json", "w") as f:
        json.dump(progress, f)

def load_progress() -> Dict:
    """加载扫描进度"""
    try:
        with open("scan_progress.json", "r") as f:
            return json.load(f)
    except:
        return {}

def background_scan(scan_type: str, provider: str = None):
    """后台扫描函数"""
    def scan_process():
        with open("scan.log", "w") as f:  # 先清空日志文件
            f.write("")
            
        with open("scan.log", "a") as log_file:
            # 重定向标准输出和错误输出到日志文件
            old_stdout = sys.stdout
            old_stderr = sys.stderr
            sys.stdout = log_file
            sys.stderr = log_file
            
            try:
                print("\n开始检测IP可用性...")
                print("-" * 70)
                print("\n")
                
                # 创建表格头部
                print("┌─────────┬──────────┬──────────┬─────────┬──────────────┬────────────────────────────┬───────────────────────────┐")
                print("│    IP   │   延迟   │   机房   │  地区   │     国家     │         HTTP地址           │         WS地址            │")
                print("├─────────┼──────────┼──────────┼─────────┼──────────────┼────────────────────────────┼───────────────────────────┤")
                
                config = load_config()
                results = []
                total_found = 0
                
                # 获取最优线程数用于单个供应商的扫描
                max_workers = min(config.get('max_threads', 2000), 1000)  # 增加到1000个线程
                print(f"[线程] 每个供应商使用 {max_workers} 个线程扫描\n")
                
                if scan_type == '1':
                    # 扫描所有内置供应商
                    providers = list(ASN_MAP.keys())
                    print(f"[开始] 扫描所有内置供应商 ({len(providers)} 个)...")
                    
                    for i, provider_name in enumerate(providers, 1):
                        print(f"\n[供应商] 开始扫描 {provider_name} ({i}/{len(providers)})...")
                        try:
                            provider_results = scan_provider(provider_name, config)
                            if provider_results:
                                results.extend(provider_results)
                                total_found += len(provider_results)
                                print(f"[完成] {provider_name} 发现 {len(provider_results)} 个节点")
                            else:
                                print(f"[完成] {provider_name} 未发现节点")
                            
                            print("-" * 70)
                            
                        except Exception as e:
                            print(f"[错误] 扫描 {provider_name} 失败: {str(e)}")
                        
                        # 强制刷新日志
                        log_file.flush()
                        os.fsync(log_file.fileno())
                        
                        # 短暂暂停后继续下一个供应商
                        time.sleep(1)
                        print(f"\n[进度] 已完成 {i}/{len(providers)} 个供应商")
                        
                else:
                    # 扫描特定供应商
                    if provider not in ASN_MAP:
                        print(f"[错误] 无效的供应商: {provider}")
                        return
                        
                    print(f"[开始] 扫描供应商 {provider}...")
                    try:
                        provider_results = scan_provider(provider, config)
                        if provider_results:
                            results.extend(provider_results)
                            total_found += len(provider_results)
                            print(f"[完成] {provider} 发现 {len(provider_results)} 个节点")
                        else:
                            print(f"[完成] {provider} 未发现节点")
                    except Exception as e:
                        print(f"[错误] 扫描失败: {str(e)}")
                
                # 显示最终扫描结果
                if results:
                    print("\n└─────────┴──────────┴──────────┴─────────┴──────────────┴────────────────────────────┴───────────────────────────┘")
                    print(f"\n[完成] 总共发现 {total_found} 个节点")
                    save_results(results)
                else:
                    print("\n└─────────┴──────────┴──────────┴─────────┴──────────────┴────────────────────────────┴───────────────────────────┘")
                    print(f"\n[完成] 未发现可用节点")
                
            finally:
                # 恢复标准输出和错误输出
                sys.stdout = old_stdout
                sys.stderr = old_stderr
                log_file.flush()
                os.fsync(log_file.fileno())
    
    # 使用start_new_session创建独立进程组
    process = Process(target=scan_process)
    process.start()
    
    # 保存进程ID
    with open("scan_pid.txt", "w") as f:
        f.write(str(process.pid))
        
    print(f"\n[后台] 扫描已启动，进程ID: {process.pid}")
    print(f"[提示] 使用选项8查看扫描进度")
    
    # 移除 process.join() 部分，让进程在后台运行

def show_scan_progress():
    """显示扫描进度"""
    try:
        # 检查是否有正在运行的扫描进程
        try:
            with open("scan_pid.txt", "r") as f:
                pid = int(f.read().strip())
                if not os.path.exists(f"/proc/{pid}"):
                    print(f"{Colors.WARNING}[警告] 没有正在运行的扫描进程{Colors.ENDC}")
                    return
        except:
            print(f"{Colors.WARNING}[警告] 没有正在运行的扫描进程{Colors.ENDC}")
            return

        # 清空日志文件内容
        with open("scan.log", "r") as f:
            content = f.read()
            
        # 显示初始内容
        print(content)
        
        # 持续监控日志文件变化
        while True:
            try:
                # 检查进程是否还在运行
                if not os.path.exists(f"/proc/{pid}"):
                    print(f"\n{Colors.OKGREEN}[完成] 扫描已结束{Colors.ENDC}")
                    break
                    
                # 读取新内容
                with open("scan.log", "r") as f:
                    new_content = f.read()
                    
                # 如果内容有变化，则更新显示
                if new_content != content:
                    # 清屏
                    os.system('clear')
                    print(new_content)
                    content = new_content
                    # 强制刷新输出
                    sys.stdout.flush()
                
                # 短暂等待后继续
                time.sleep(0.1)
                
            except FileNotFoundError:
                print(f"{Colors.WARNING}[警告] 日志文件不存在{Colors.ENDC}")
                break
            except Exception as e:
                print(f"{Colors.FAIL}[错误] 读取日志失败: {str(e)}{Colors.ENDC}")
                break
            
    except KeyboardInterrupt:
        print(f"\n{Colors.OKBLUE}[提示] 已停止查看进度{Colors.ENDC}")

def show_background_scan_menu():
    """显示后台扫描菜单"""
    print(f"\n{Colors.HEADER}=== 后台扫描模式 ==={Colors.ENDC}")
    print(f"{Colors.OKGREEN}[1] 扫描所有内置供应商{Colors.ENDC}")
    print(f"{Colors.OKGREEN}[2] 扫描特定供应商{Colors.ENDC}")
    print(f"{Colors.OKGREEN}[0] 返回主菜单{Colors.ENDC}")
    
    choice = input(f"\n{Colors.OKBLUE}请选择 (0-2): {Colors.ENDC}").strip()
    
    if choice == "1":
        background_scan('1')
        return  # 直接返回，不需要等待扫描完成
    elif choice == "2":
        # 显示供应商列表
        providers = list(ASN_MAP.keys())
        print("\n可用的供应商:")
        for i, provider in enumerate(providers, 1):
            print(f"{i}. {provider}")
        
        provider_choice = input(f"\n{Colors.OKBLUE}请选择供应商 (输入序号或名称): {Colors.ENDC}").strip()
        
        # 处理序号或名称输入
        selected_provider = None
        if provider_choice.isdigit():
            idx = int(provider_choice)
            if 1 <= idx <= len(providers):
                selected_provider = providers[idx-1]
        elif provider_choice in ASN_MAP:
            selected_provider = provider_choice
            
        if selected_provider:
            background_scan('2', selected_provider)
            return  # 直接返回，不需要等待扫描完成
        else:
            print(f"{Colors.FAIL}[错误] 无效的选择{Colors.ENDC}")

def show_progress(total: int, scanned: multiprocessing.Value, start_time: float, stats: ScanStats, current_ip_range: str = ""):
    """显示进度和节点列表"""
    # 添加清屏代码
    print("\033[2J\033[H", end='')  # 清屏并将光标移到开头
    time.sleep(0.5)  # 每次刷新间隔0.5秒
    
    # 计算进度和时间
    progress = scanned.value / total if total > 0 else 0
    elapsed = time.time() - start_time
    speed = scanned.value / elapsed if elapsed > 0 else 0
    remaining = (total - scanned.value) / speed if speed > 0 else 0
    total_time = elapsed + remaining

    # 创建进度条
    bar_width = 50
    filled = int(bar_width * progress)
    bar = '#' * filled + '-' * (bar_width - filled)

    # 格式化时间
    def format_time(seconds):
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        if hours > 0:
            return f"{hours}时{minutes}分{secs}秒"
        elif minutes > 0:
            return f"{minutes}分{secs}秒"
        else:
            return f"{secs}秒"

    # 计算百分比，避免除零错误
    port_open_rate = (stats.port_open/scanned.value*100) if scanned.value > 0 else 0

    # 计算扫描速度
    scan_speed = scanned.value / elapsed if elapsed > 0 else 0

    # 构建显示内容
    print(f"\r{Colors.OKBLUE}[IP段] 当前: {current_ip_range}\n"
          f"[时间] 已用:{format_time(elapsed)} "
          f"剩余:{format_time(remaining)} "
          f"总计:{format_time(total_time)}\n"
          f"[进度] [{bar}] {progress*100:.1f}% "
          f"({scanned.value:,d}/{total:,d}) "
          f"速度: {scan_speed:.0f} IP/秒\n"
          f"[统计] 总扫描:{scanned.value:,d} "
          f"端口开放:{stats.port_open}({port_open_rate:.2f}%) "
          f"端口关闭:{scanned.value-stats.port_open:,d} "
          f"失败:{stats.http_failed+stats.ws_failed:,d}\n"
          f"[详情] HTTP失败:{stats.http_failed} "
          f"WS失败:{stats.ws_failed} "
          f"延迟超限:{stats.high_latency} "
          f"同步失败:{stats.sync_failed} "
          f"有效节点:{stats.valid_nodes}{Colors.ENDC}\n")

    # 定义表格列宽
    col_widths = {
        'id': 4,          # ID列宽
        'ip': 16,         # IP列宽
        'latency': 8,     # 延迟列宽
        'provider': 10,   # 供应商列宽
        'location': 20,   # 位置列宽
        'http': 30,       # HTTP列宽
        'ws': 30          # WS列宽
    }

    print("\n有效节点列表:")
    # 打印表头分隔线
    print("┌" + "─"*col_widths['id'] + "┬" + "─"*col_widths['ip'] + "┬" + "─"*col_widths['latency'] + 
          "┬" + "─"*col_widths['provider'] + "┬" + "─"*col_widths['location'] + 
          "┬" + "─"*col_widths['http'] + "┬" + "─"*col_widths['ws'] + "┐")

    # 打印表头
    print(f"│{'ID':^{col_widths['id']}}│{'IP':^{col_widths['ip']}}│{'延迟':^{col_widths['latency']}}│" +
          f"{'供应商':^{col_widths['provider']}}│{'位置':^{col_widths['location']}}│" +
          f"{'HTTP RPC':^{col_widths['http']}}│{'WebSocket':^{col_widths['ws']}}│")

    # 打印表头下分隔线
    print("├" + "─"*col_widths['id'] + "┼" + "─"*col_widths['ip'] + "┼" + "─"*col_widths['latency'] + 
          "┼" + "─"*col_widths['provider'] + "┼" + "─"*col_widths['location'] + 
          "┼" + "─"*col_widths['http'] + "┼" + "─"*col_widths['ws'] + "┤")

    if stats.valid_nodes_list:
        for i, node in enumerate(stats.valid_nodes_list, 1):
            location = f"{node.get('city', 'Unknown')}, {node.get('country', 'Unknown')}"
            # 打印节点信息行
            print(f"│{str(i):^{col_widths['id']}}│{node['ip']:^{col_widths['ip']}}│" +
                  f"{str(node.get('latency', 'N/A')):^{col_widths['latency']}}│" +
                  f"{node.get('provider', 'Unknown'):^{col_widths['provider']}}│" +
                  f"{location[:col_widths['location']]:^{col_widths['location']}}│" +
                  f"{'http://'+node['ip']+':8899':^{col_widths['http']}}│" +
                  f"{'ws://'+node['ip']+':8900':^{col_widths['ws']}}│")

    # 打印表格底部分隔线
    print("└" + "─"*col_widths['id'] + "┴" + "─"*col_widths['ip'] + "┴" + "─"*col_widths['latency'] + 
          "┴" + "─"*col_widths['provider'] + "┴" + "─"*col_widths['location'] + 
          "┴" + "─"*col_widths['http'] + "┴" + "─"*col_widths['ws'] + "┘")

def init_config():
    """初始化配置文件"""
    if not os.path.exists(CONFIG_FILE):
        config = {
            "ipinfo_token": "",  # IPInfo API token
            "timeout": {
                "port_scan": 1,
                "http_check": 3,
                "ws_check": 2
            },
            "scan": {
                "max_threads": 1000,
                "batch_size": 500,
                "retry_count": 2,
                "latency_threshold": 300
            },
            "providers": {
                "vultr": "AS20473",
                "digitalocean": "AS14061",
                "linode": "AS63949"
            },
            "output": {
                "file": "/root/results.txt",
                "format": "table"
            },
            "max_retries": 3,
            "max_threads": 1000,
            "batch_size": 100,
            "strict_mode": True,
            "mainnet_rpc_nodes": [
                "https://api.mainnet-beta.solana.com",
                "https://ssc-dao.genesysgo.net"
            ],
            "ws_10001_check": True,
            "max_slot_diff": 200,
            "scan_timeout": {
                "port": 1,
                "http": 3,
                "ws": 2
            }
        }
        save_config(config)
        print(f"{Colors.OKGREEN}[配置] 已创建默认配置文件{Colors.ENDC}")
    else:
        config = load_config()
        # 检查并更新配置
        if validate_config(config):
            save_config(config)
            print(f"{Colors.OKGREEN}[配置] 配置文件已更新{Colors.ENDC}")

def validate_config(config: Dict) -> bool:
    """验证并更新配置文件，返回是否需要更新"""
    default_config = {
        "ipinfo_token": "",
        "timeout": {
            "port_scan": 1,
            "http_check": 3,
            "ws_check": 2
        },
        "scan": {
            "max_threads": 1000,
            "batch_size": 500,
            "retry_count": 2,
            "latency_threshold": 300
        },
        "providers": {
            "vultr": "AS20473",
            "digitalocean": "AS14061",
            "linode": "AS63949"
        },
        "output": {
            "file": "/root/results.txt",
            "format": "table"
        },
        "max_retries": 3,
        "max_threads": 1000,
        "batch_size": 100,
        "strict_mode": True,
        "mainnet_rpc_nodes": [
            "https://api.mainnet-beta.solana.com",
            "https://ssc-dao.genesysgo.net"
        ],
        "ws_10001_check": True,
        "max_slot_diff": 200,
        "scan_timeout": {
            "port": 1,
            "http": 3,
            "ws": 2
        }
    }
    
    need_update = False
    
    # 递归更新配置
    def update_dict(current: Dict, default: Dict) -> bool:
        updated = False
        for key, value in default.items():
            if key not in current:
                current[key] = value
                updated = True
            elif isinstance(value, dict) and isinstance(current[key], dict):
                if update_dict(current[key], value):
                    updated = True
        # 移除多余的键
        for key in list(current.keys()):
            if key not in default:
                del current[key]
                updated = True
        return updated
    
    if update_dict(config, default_config):
        need_update = True
        
    return need_update

def main():
    """主函数"""
    init_config()  # 初始化配置
    config = load_config()
    providers = load_providers()
    total_found = 0
    
    while True:
        show_menu()
        choice = input(f"{Colors.OKBLUE}请选择操作 (0-13): {Colors.ENDC}").strip()
        
        if choice == "5":
            if not providers:
                print(f"\n{Colors.WARNING}[警告] 请先添加要扫描的服务商{Colors.ENDC}")
                continue
                
            print("\n开始检测IP可用性...")
            print("-" * 70)
            print("\n")
            
            # 创建表格头部
            print("┌─────────┬──────────┬──────────┬─────────┬──────────────┬────────────────────────────┬───────────────────────────┐")
            print("│    IP   │   延迟   │   机房   │  地区   │     国家     │         HTTP地址           │         WS地址            │")
            print("├─────────┼──────────┼──────────┼─────────┼──────────────┼────────────────────────────┼───────────────────────────┤")
            
            results = []
            print(f"\n[开始] 开始扫描 {len(providers)} 个服务商...")
            
            # 获取最优线程数用于单个供应商的扫描
            max_workers = min(config.get('max_threads', 2000), 1000)  # 增加到1000个线程
            print(f"[线程] 每个供应商使用 {max_workers} 个线程扫描\n")
            
            # 按顺序扫描每个供应商
            for provider in providers:
                print(f"\n{Colors.HEADER}[供应商] 开始扫描 {provider}...{Colors.ENDC}")
                try:
                    provider_results = scan_provider(provider, config)
                    if provider_results:
                        results.extend(provider_results)
                        total_found += len(provider_results)
                        print(f"{Colors.OKGREEN}[完成] {provider} 发现 {len(provider_results)} 个节点{Colors.ENDC}")
                    else:
                        print(f"{Colors.WARNING}[完成] {provider} 未发现节点{Colors.ENDC}")
                    
                    # 每个供应商扫描完成后显示分隔线
                    print(f"{Colors.OKBLUE}{'-' * 70}{Colors.ENDC}")
                    
                except Exception as e:
                    print(f"{Colors.FAIL}[错误] 扫描 {provider} 失败: {str(e)}{Colors.ENDC}")
                    continue
                
                # 每个供应商扫描完后短暂暂停
                time.sleep(1)
            
            # 显示最终扫描结果
            if results:
                print("\n└─────────┴──────────┴──────────┴─────────┴──────────────┴────────────────────────────┴───────────────────────────┘")
                print(f"\n{Colors.OKGREEN}[完成] 共扫描 {len(providers)} 个服务商，发现 {total_found} 个节点{Colors.ENDC}")
                save_results(results)
            else:
                print("\n└─────────┴──────────┴──────────┴─────────┴──────────────┴────────────────────────────┴───────────────────────────┘")
                print(f"\n{Colors.WARNING}[完成] 未发现可用节点{Colors.ENDC}")
            
            continue
            
        elif choice == "1":
            print("\n支持的服务商列表:")
            for provider in ASN_MAP.keys():
                print(f"- {provider}")
                
        elif choice == "2":
            print("\n请输入服务商名称（一行一个，输入空行结束）:")
            while True:
                provider = input().strip()
                if not provider:
                    break
                if provider in ASN_MAP:
                    if provider not in providers:
                        providers.append(provider)
                    else:
                        print(f"{provider} 已在列表中")
                else:
                    print(f"不支持的服务商: {provider}")
            save_providers(providers)
            
        elif choice == "3":
            if providers:
                print("\n当前要扫描的服务商:")
                for provider in providers:
                    print(f"- {provider}")
            else:
                print("\n暂无要扫描的服务商")
                
        elif choice == "4":
            providers.clear()
            save_providers(providers)
            print("\n已清空服务商列表")
            
        elif choice == "6":
            print("\n[快速扫描] 开始扫描Vultr...")
            results = scan_provider("Vultr", config)
            if results:
                print(f"\n[统计] 共发现 {len(results)} 个RPC节点")
                show_scan_stats(stats)
                save_results(results)
            else:
                print("\n[完成] 未发现可用的RPC节点")
                
        elif choice == "7":
            show_background_scan_menu()  # 显示后台扫描菜单
        elif choice == "8":
            show_scan_progress()  # 显示扫描进度
        elif choice == "9":
            # 测试已发现节点的质量
            test_and_rank_nodes()
        elif choice == "10":
            configure_ipinfo()
        elif choice == "11":
            print(f"\n{Colors.HEADER}[选择] 扫描所有内置供应商{Colors.ENDC}")
            results = scan_all_built_in_providers(config)
            if results:
                print(f"\n{Colors.OKGREEN}[完成] 扫描结束，发现 {len(results)} 个节点{Colors.ENDC}")
                test_and_rank_nodes()  # 测试发现的节点
            else:
                print(f"\n{Colors.WARNING}[完成] 扫描结束，未发现可用节点{Colors.ENDC}")
        elif choice == "12":
            print(f"\n{Colors.HEADER}[选择] 扫描验证者节点子网{Colors.ENDC}")
            results = scan_validator_subnets(config)
            if results:
                print(f"\n{Colors.OKGREEN}[完成] 扫描结束，发现 {len(results)} 个节点{Colors.ENDC}")
                test_and_rank_nodes()  # 测试发现的节点
            else:
                print(f"\n{Colors.WARNING}[完成] 扫描结束，未发现可用节点{Colors.ENDC}")
        elif choice == "13":
            print(f"\n{Colors.HEADER}[选择] 智能扫描验证者子网{Colors.ENDC}")
            results = scan_validator_subnets_smart(config)
            if results:
                print(f"\n{Colors.OKGREEN}[完成] 扫描结束，发现 {len(results)} 个节点{Colors.ENDC}")
                test_and_rank_nodes()  # 测试发现的节点
            else:
                print(f"\n{Colors.WARNING}[完成] 扫描结束，未发现可用节点{Colors.ENDC}")
        elif choice == "0":
            print("\n感谢使用，再见！")
            break
            
        else:
            print("\n无效的选择，请重试")

def optimized_scan_ip(ip: str, provider: str, config: Dict) -> Optional[Dict]:
    """优化后的扫描流程"""
    try:
        # 第一阶段：快速检查
        if not is_port_open(ip, 8899):
            return None
        
        # 第二阶段：基础验证
        http_url = f"http://{ip}:8899"
        if not enhanced_health_check(http_url):
            return None
        
        # 第三阶段：性能检查
        latency = get_latency(ip)
        if latency > 300:  # 300ms以上直接丢弃
            return None
        
        # 第四阶段：详细验证
        if not check_sync_status(http_url):
            return None
        
        # 通过所有检查后获取位置信息
        ip_info = get_ip_info(ip, config)
        
        # 构建结果
        result = {
            "ip": f"{ip}:8899",
            "provider": provider,
            "latency": latency,
            **ip_info,
            "last_checked": time.strftime("%Y-%m-%d %H:%M:%S")
        }
        
        return result
        
    except Exception as e:
        return None

def scan_ip(ip: str, provider: str, config: Dict, stats: ScanStats) -> Dict:
    try:
        stats.total_scanned += 1
        
        # 1. 基础端口检查 (8899)
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        if sock.connect_ex((ip, 8899)) != 0:
            return None
        sock.close()
        stats.port_open += 1
        
        # 2. 检查所有可能的端点
        endpoints = {
            'http': {'available': False, 'url': f"http://{ip}:8899"},
            'ws': {'available': False, 'url': f"ws://{ip}:8900"},
            'wss': {'available': False, 'url': f"wss://{ip}:10001"}
        }
        
        # 检查 HTTP RPC
        try:
            health_check = requests.post(
                endpoints['http']['url'],
                json={"jsonrpc": "2.0", "id": 1, "method": "getHealth"},
                headers={"Content-Type": "application/json"},
                timeout=3
            )
            if health_check.status_code == 200 and "result" in health_check.json():
                endpoints['http']['available'] = True
        except:
            stats.http_failed += 1

        # 检查 WS RPC
        try:
            ws = websocket.create_connection(endpoints['ws']['url'], timeout=3)
            ws.send(json.dumps({"jsonrpc": "2.0", "id": 1, "method": "getHealth"}))
            result = ws.recv()
            if "result" in json.loads(result):
                endpoints['ws']['available'] = True
            ws.close()
        except:
            stats.ws_failed += 1

        # 检查 WSS RPC (10001端口)
        try:
            wss = websocket.create_connection(endpoints['wss']['url'], timeout=3, sslopt={"cert_reqs": ssl.CERT_NONE})
            wss.send(json.dumps({"jsonrpc": "2.0", "id": 1, "method": "getHealth"}))
            result = wss.recv()
            if "result" in json.loads(result):
                endpoints['wss']['available'] = True
            wss.close()
        except:
            pass

        # 如果所有端点都不可用，返回None
        if not any(endpoint['available'] for endpoint in endpoints.values()):
            return None

        # 3. 获取版本信息和slot高度(使用任一可用端点)
        version_info = {}
        current_slot = 0
        
        if endpoints['http']['available']:
            try:
                response = requests.post(
                    endpoints['http']['url'],
                    json={"jsonrpc": "2.0", "id": 1, "method": "getVersion"},
                    headers={"Content-Type": "application/json"},
                    timeout=3
                )
                if response.ok:
                    version_info = response.json().get("result", {})

                slot_response = requests.post(
                    endpoints['http']['url'],
                    json={"jsonrpc": "2.0", "id": 1, "method": "getSlot"},
                    headers={"Content-Type": "application/json"},
                    timeout=3
                )
                if slot_response.ok:
                    current_slot = slot_response.json().get("result", 0)
            except:
                pass

        # 4. 测试延迟
        latency = get_latency(ip)
        if latency > 300:
            stats.high_latency += 1
            return None

        # 5. 获取IP信息
        ip_info = get_ip_info(ip, config)
        
        stats.valid_nodes += 1
        
        # 构建结果字典
        result = {
            "ip": f"{ip}:8899",
            "provider": provider,
            "version": version_info.get("solana-core", "unknown"),
            "slot": current_slot,
            "latency": latency,
            "http_available": endpoints['http']['available'],
            "ws_available": endpoints['ws']['available'],
            "wss_available": endpoints['wss']['available'],
            "http_url": endpoints['http']['url'],
            "ws_url": endpoints['ws']['url'],
            "wss_url": endpoints['wss']['url'],
            **ip_info,
            "last_checked": time.strftime("%Y-%m-%d %H:%M:%S")
        }
        
        # 更新表格显示，添加WSS状态
        print(f"│{result['ip']:<9}│{result['latency']:>8.1f}ms│{result['city']:<10}│"
              f"{result['region']:<9}│{result['country']:<14}│"
              f"{'HTTP,WS,WSS'[:(3 if result['http_available'] else 0) + (3 if result['ws_available'] else 0) + (4 if result['wss_available'] else 0)]:<28}│"
              f"{result['ws_url']:<27}│")

        return result
        
    except Exception as e:
        return None

def scan_provider(provider: str, config: Dict) -> List[Dict]:
    """扫描特定供应商的节点"""
    print(f"\n{Colors.HEADER}[快速扫描] 开始扫描{provider}...{Colors.ENDC}\n")
    
    # 获取ASN列表
    asn_list = ASN_MAP.get(provider)
    if not asn_list:
        print(f"{Colors.FAIL}[错误] 未找到供应商 {provider} 的ASN信息{Colors.ENDC}")
        return []
    
    # 如果ASN是字符串，转换为列表
    if isinstance(asn_list, str):
        asn_list = [asn_list]
    
    # 修改配置
    config['max_threads'] = 1000  # 确保使用1000线程
    
    all_results = []
    for asn in asn_list:
        print(f"{Colors.OKBLUE}[ASN] 正在扫描 AS{asn}...{Colors.ENDC}")
        # 修改这里：使用 get_asn_prefixes 替代 get_ip_ranges_for_asn
        ip_ranges = get_asn_prefixes(asn)
        if not ip_ranges:
            print(f"{Colors.WARNING}[警告] 未找到 AS{asn} 的IP范围{Colors.ENDC}")
            continue
            
        print(f"{Colors.OKBLUE}[信息] AS{asn} 获取到 {len(ip_ranges)} 个IP段{Colors.ENDC}")
        results = scan_ip_ranges(ip_ranges, config)
        if results:
            all_results.extend(results)
            print(f"{Colors.OKGREEN}[完成] AS{asn} 发现 {len(results)} 个节点{Colors.ENDC}")
    
    return all_results

def background_scan(scan_type: str, provider: str = None):
    """后台扫描函数"""
    def scan_process():
        with open("scan.log", "w") as f:  # 先清空日志文件
            f.write("")
            
        with open("scan.log", "a") as log_file:
            # 重定向标准输出和错误输出到日志文件
            old_stdout = sys.stdout
            old_stderr = sys.stderr
            sys.stdout = log_file
            sys.stderr = log_file
            
            try:
                print("\n开始检测IP可用性...")
                print("-" * 70)
                print("\n")
                
                # 创建表格头部
                print("┌─────────┬──────────┬──────────┬─────────┬──────────────┬────────────────────────────┬───────────────────────────┐")
                print("│    IP   │   延迟   │   机房   │  地区   │     国家     │         HTTP地址           │         WS地址            │")
                print("├─────────┼──────────┼──────────┼─────────┼──────────────┼────────────────────────────┼───────────────────────────┤")
                
                config = load_config()
                results = []
                total_found = 0
                
                # 获取最优线程数用于单个供应商的扫描
                max_workers = min(config.get('max_threads', 2000), 1000)  # 增加到1000个线程
                print(f"[线程] 每个供应商使用 {max_workers} 个线程扫描\n")
                
                if scan_type == '1':
                    # 扫描所有内置供应商
                    providers = list(ASN_MAP.keys())
                    print(f"[开始] 扫描所有内置供应商 ({len(providers)} 个)...")
                    
                    for i, provider_name in enumerate(providers, 1):
                        print(f"\n[供应商] 开始扫描 {provider_name} ({i}/{len(providers)})...")
                        try:
                            provider_results = scan_provider(provider_name, config)
                            if provider_results:
                                results.extend(provider_results)
                                total_found += len(provider_results)
                                print(f"[完成] {provider_name} 发现 {len(provider_results)} 个节点")
                            else:
                                print(f"[完成] {provider_name} 未发现节点")
                            
                            print("-" * 70)
                            
                        except Exception as e:
                            print(f"[错误] 扫描 {provider_name} 失败: {str(e)}")
                        
                        # 强制刷新日志
                        log_file.flush()
                        os.fsync(log_file.fileno())
                        
                        # 短暂暂停后继续下一个供应商
                        time.sleep(1)
                        print(f"\n[进度] 已完成 {i}/{len(providers)} 个供应商")
                        
                else:
                    # 扫描特定供应商
                    if provider not in ASN_MAP:
                        print(f"[错误] 无效的供应商: {provider}")
                        return
                        
                    print(f"[开始] 扫描供应商 {provider}...")
                    try:
                        provider_results = scan_provider(provider, config)
                        if provider_results:
                            results.extend(provider_results)
                            total_found += len(provider_results)
                            print(f"[完成] {provider} 发现 {len(provider_results)} 个节点")
                        else:
                            print(f"[完成] {provider} 未发现节点")
                    except Exception as e:
                        print(f"[错误] 扫描失败: {str(e)}")
                
                # 显示最终扫描结果
                if results:
                    print("\n└─────────┴──────────┴──────────┴─────────┴──────────────┴────────────────────────────┴───────────────────────────┘")
                    print(f"\n[完成] 总共发现 {total_found} 个节点")
                    save_results(results)
                else:
                    print("\n└─────────┴──────────┴──────────┴─────────┴──────────────┴────────────────────────────┴───────────────────────────┘")
                    print(f"\n[完成] 未发现可用节点")
                
            finally:
                # 恢复标准输出和错误输出
                sys.stdout = old_stdout
                sys.stderr = old_stderr
                log_file.flush()
                os.fsync(log_file.fileno())
    
    # 使用start_new_session创建独立进程组
    process = Process(target=scan_process)
    process.start()
    
    # 保存进程ID
    with open("scan_pid.txt", "w") as f:
        f.write(str(process.pid))
        
    print(f"\n[后台] 扫描已启动，进程ID: {process.pid}")
    print(f"[提示] 使用选项8查看扫描进度")
    
    # 移除 process.join() 部分，让进程在后台运行

class RealtimeSaver:
    """实时保存器"""
    def __init__(self):
        self.lock = threading.Lock()
        self.file = open("/root/results.txt", "a")  # 修改为/root路径
        
    def save(self, result: dict):
        """实时保存表格数据"""
        table = tabulate([result.values()], headers=result.keys(), tablefmt="grid")
        self.file.write(table + "\n")  # 保留表格格式保存
            
    def __del__(self):
        self.file.close()

# 在全局初始化
realtime_saver = RealtimeSaver()

# 在发现节点时调用
def on_node_found(result: dict):
    print_realtime_result(result)
    realtime_saver.save(result)

def print_realtime_result(result: dict):
    """即时打印发现节点"""
    table = [[
        result['ip'],
        f"{result['latency']}ms",
        result['city'],
        result['region'],
        result['country'],
        result['http_url'],
        result['ws_url']
    ]]
    headers = ["IP", "延迟", "机房", "地区", "国家", "HTTP地址", "WS地址"]
    print(f"\n{Colors.OKGREEN}新节点发现!{Colors.ENDC}")
    print(tabulate(table, headers, tablefmt="grid"))

class ProgressTracker:
    """进度跟踪器"""
    def __init__(self, total_segments: int, total_ips: int):
        self.start_time = time.time()
        self.total_segments = total_segments
        self.total_ips = total_ips
        self.scanned_segments = 0
        self.scanned_ips = 0
        self.lock = threading.Lock()
        
    def update_segment(self):
        """更新已扫描段数"""
        with self.lock:
            self.scanned_segments += 1
            
    def update_ips(self, count: int):
        """更新已扫描IP数"""
        with self.lock:
            self.scanned_ips += count
            
    def get_progress(self) -> dict:
        """获取当前进度数据"""
        elapsed = time.time() - self.start_time
        seg_progress = self.scanned_segments / self.total_segments if self.total_segments else 0
        ip_progress = self.scanned_ips / self.total_ips if self.total_ips else 0
        
        # 计算剩余时间
        remaining_time = 0
        if ip_progress > 0.01:  # 避免除零错误
            remaining_time = (elapsed / ip_progress) * (1 - ip_progress)
            
        return {
            "segments": f"{self.scanned_segments}/{self.total_segments}",
            "ips": f"{self.scanned_ips}/{self.total_ips}",
            "elapsed": self.format_time(elapsed),
            "remaining": self.format_time(remaining_time),
            "seg_progress": seg_progress,
            "ip_progress": ip_progress
        }
    
    @staticmethod
    def format_time(seconds: float) -> str:
        """将秒转换为时间格式"""
        if seconds < 60:
            return f"{int(seconds)}秒"
        elif seconds < 3600:
            return f"{int(seconds//60)}分{int(seconds%60)}秒"
        else:
            hours = int(seconds // 3600)
            minutes = int((seconds % 3600) // 60)
            return f"{hours}小时{minutes}分"

def show_enhanced_progress(tracker: ProgressTracker, recent_nodes: List[Dict]):
    """优化后的进度显示（不覆盖节点信息）"""
    # 使用ANSI控制码只更新进度部分
    print("\033[7A")  # 上移7行（根据进度显示行数调整）
    # ... 输出进度信息 ...
    print("\033[K"*7)  # 清除剩余行

def get_ips(asn: str, config: Dict) -> List[str]:
    """根据ASN获取IP列表"""
    try:
        # 使用IPinfo API获取IP列表
        if token := config.get("ipinfo_token"):
            url = f"https://ipinfo.io/AS{asn}/json?token={token}"
            response = requests.get(url, timeout=5)
            data = response.json()
            return data.get("prefixes", [])
        
        # 回退到本地ASN映射
        return ASN_MAP.get(asn, [])
    except Exception as e:
        print(f"[错误] 获取ASN {asn} 的IP列表失败: {e}")
        return []

def show_scan_stats(stats: ScanStats):
    """显示扫描统计信息"""
    print(f"\n{Colors.OKBLUE}{'=== 扫描统计 ===':^60}{Colors.ENDC}")
    print(f"{Colors.OKGREEN}总计扫描IP: {stats.total_scanned:>6}{Colors.ENDC}")
    print(f"{Colors.OKGREEN}端口开放数: {stats.port_open:>6}{Colors.ENDC}")
    print(f"{Colors.WARNING}HTTP检查失败: {stats.http_failed:>6}{Colors.ENDC}")
    print(f"{Colors.WARNING}WebSocket检查失败: {stats.ws_failed:>6}{Colors.ENDC}")
    print(f"{Colors.WARNING}延迟过高: {stats.high_latency:>6}{Colors.ENDC}")
    print(f"{Colors.WARNING}同步状态异常: {stats.sync_failed:>6}{Colors.ENDC}")
    print(f"{Colors.OKGREEN}有效节点数: {stats.valid_nodes:>6}{Colors.ENDC}")
    
    if stats.total_scanned > 0:
        success_rate = (stats.valid_nodes / stats.total_scanned) * 100
        print(f"{Colors.OKBLUE}成功率: {success_rate:>6.2f}%{Colors.ENDC}")
    print("\n" + "="*60)

def check_port_open(ip: str, timeout: float = 0.5) -> bool:
    """检查端口是否开放，使用更短的超时时间"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, 8899))
        sock.close()
        return result == 0
    except:
        return False

def verify_rpc_node(ip: str, config: Dict, timeout: int = 3) -> Tuple[bool, Dict]:
    """验证RPC节点是否可用，返回(是否可用, 节点信息)"""
    try:
        # 先测试基本连通性
        url = f"http://{ip}:8899"
        headers = {"Content-Type": "application/json"}
        
        # 测量延迟
        latency = get_latency(ip)
        if latency > 500:  # 延迟超过500ms就标记为延迟超限
            return False, {"fail_reason": "high_latency"}
            
        # 测试HTTP RPC
        http_available = False
        try:
            health_req = {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "getHealth"
            }
            response = requests.post(url, json=health_req, headers=headers, timeout=timeout)
            if response.status_code == 200 and "result" in response.json():
                http_available = True
        except:
            pass

        # 测试WebSocket RPC
        ws_available = False
        try:
            ws_url = f"ws://{ip}:8900"
            ws = websocket.create_connection(ws_url, timeout=timeout)
            ws.send(json.dumps(health_req))
            result = ws.recv()
            if "result" in json.loads(result):
                ws_available = True
            ws.close()
        except:
            pass

        # 只要HTTP或WebSocket其中之一可用即可
        if not (http_available or ws_available):
            return False, {"fail_reason": "no_available_endpoint"}

        # 获取版本信息和slot高度(如果HTTP可用)
        version_info = {}
        slot = 0
        if http_available:
            try:
                version_req = {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "getVersion"
                }
                response = requests.post(url, json=version_req, headers=headers, timeout=timeout)
                if response.ok:
                    version_info = response.json().get("result", {})

                slot_req = {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "getSlot"
                }
                response = requests.post(url, json=slot_req, headers=headers, timeout=timeout)
                if response.ok:
                    slot = response.json().get("result", 0)
            except:
                pass

        # 获取IP信息
        ip_info = get_ip_info(ip, config)
        
        # 从IP信息中获取供应商
        provider = "Unknown"
        if ip_info and ip_info.get("org"):
            org = ip_info["org"].lower()
            if "vultr" in org:
                provider = "Vultr"
            elif "digitalocean" in org:
                provider = "DigitalOcean"
            elif "amazon" in org or "aws" in org:
                provider = "AWS"
            elif "google" in org:
                provider = "GCP"
            elif "microsoft" in org:
                provider = "Azure"
            elif "linode" in org:
                provider = "Linode"
            elif "ovh" in org:
                provider = "OVH"
            elif "choopa" in org:  # 添加 Choopa（Vultr 的母公司）
                provider = "Vultr"
            else:
                provider = ip_info["org"].split()[0]

        # 新增主网slot比对
        mainnet_slot = get_mainnet_slot(config)
        slot_diff = abs(mainnet_slot - slot) if slot > 0 else 999999
        sync_status = "synced" if slot_diff <= config["max_slot_diff"] else "out_of_sync"
        
        # 新增10001端口检查
        ws_10001_ok = False
        if config.get("ws_10001_check", True):
            try:
                ws = websocket.create_connection(f"ws://{ip}:10001", timeout=2)
                ws.close()
                ws_10001_ok = True
            except Exception as e:
                pass

        return True, {
            "version": version_info.get("solana-core", "unknown"),
            "slot": slot,
            "features": version_info.get("features", []),
            "ip": ip,
            "latency": latency,
            "provider": provider,
            "city": ip_info.get("city", "Unknown"),
            "region": ip_info.get("region", "Unknown"),
            "country": ip_info.get("country", "Unknown"),
            "http_url": f"http://{ip}:8899",
            "ws_url": f"ws://{ip}:8900",
            "http_available": http_available,
            "ws_available": ws_available,
            "slot_diff": slot_diff,
            "sync_status": sync_status,
            "ws_10001_available": ws_10001_ok,
            "mainnet_reference_slot": mainnet_slot
        }
        
    except Exception as e:
        error_type = str(e).lower()
        if "timeout" in error_type:
            return False, {"fail_reason": "timeout"}
        elif "connection" in error_type:
            return False, {"fail_reason": "connection_failed"}
        return False, {"fail_reason": "unknown_error"}

def save_node_to_file(node_info: Dict, file_path: str = "/root/results.txt"):
    """实时保存节点信息到文件"""
    try:
        # 使用相同的列宽定义，确保对齐一致
        col_widths = {'ip': 20, 'latency': 12, 'provider': 15, 'location': 30, 'http': 40, 'ws': 40}
        
        print(f"{Colors.OKBLUE}[保存] 正在保存节点信息到 {file_path}{Colors.ENDC}")
        with open(file_path, "a", encoding='utf-8') as f:
            # 写入分隔线
            f.write(f"\n{'='*80}\n")
            # 写入时间戳
            f.write(f"发现时间: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            # 写入节点基本信息
            f.write(f"[N] IP地址: {node_info['ip']}\n")
            f.write(f"[P] 服务商: {node_info.get('provider', 'Unknown')}\n")
            f.write(f"[D] 延迟: {node_info.get('latency', 'N/A')}ms\n")
            f.write(f"[L] 位置: {node_info.get('city', 'Unknown')}, {node_info.get('region', 'Unknown')}, {node_info.get('country', 'Unknown')}\n")
            f.write(f"[H] HTTP RPC: http://{node_info['ip']}:8899\n")
            f.write(f"[W] WebSocket: ws://{node_info['ip']}:8900\n")
            
            # 写入一行汇总信息（便于后续处理）
            f.write(f"[S] 汇总: {node_info['ip']:^{col_widths['ip']}} | " + \
                   f"{str(node_info.get('latency', 'N/A')):^{col_widths['latency']}} | " + \
                   f"{node_info.get('provider', 'Unknown'):^{col_widths['provider']}} | " + \
                   f"{node_info.get('city', 'Unknown')}, {node_info.get('country', 'Unknown'):^{col_widths['location']}} | " + \
                   f"http://{node_info['ip']}:8899 | ws://{node_info['ip']}:8900\n")
            
            # 写入版本信息
            if 'version' in node_info:
                f.write(f"[V] 版本: {node_info['version']}\n")
            
            # 写入性能信息
            if 'slot' in node_info:
                f.write(f"[S] Slot高度: {node_info['slot']}\n")
            
            # 写入额外信息
            if 'features' in node_info:
                f.write(f"[F] 支持特性: {', '.join(node_info['features'][:5])}")
                if len(node_info['features']) > 5:
                    f.write(f" ... 等 {len(node_info['features'])-5} 个特性")
                f.write("\n")
            
            f.write("\n")  # 额外的空行分隔
            f.flush()  # 确保立即写入文件
            
    except Exception as e:
        print(f"{Colors.WARNING}[警告] 保存节点信息到文件失败: {str(e)}{Colors.ENDC}")

def test_and_rank_nodes(file_path: str = "/root/results.txt") -> List[Dict]:
    """增强的节点测试排序函数"""
    print(f"\n{Colors.HEADER}{'='*40} 节点测试 {'='*40}{Colors.ENDC}")
    print(f"{Colors.OKBLUE}[测试] 正在从 {file_path} 读取节点列表...{Colors.ENDC}")
    
    # 加载配置和初始化节点列表
    config = load_config()
    nodes = []
    
    # 读取节点文件
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            current_node = None
            for line in lines:
                if line.startswith('[N] IP地址:'):
                    if current_node:
                        nodes.append(current_node)
                    current_node = {'ip': line.split(': ')[1].strip()}
            if current_node:
                nodes.append(current_node)
    except Exception as e:
        print(f"{Colors.FAIL}[错误] 读取节点文件失败: {str(e)}{Colors.ENDC}")
        return []

    print(f"{Colors.OKBLUE}[信息] 共读取到 {len(nodes)} 个节点{Colors.ENDC}")
    print(f"{Colors.OKBLUE}[测试] 开始性能测试...{Colors.ENDC}\n")

    # 测试每个节点
    for node in nodes:
        try:
            # 1. 首先测试基本连通性和延迟
            latencies = []
            for _ in range(3):  # 测3次取平均
                start = time.time()
                response = requests.get(f"http://{node['ip']}:8899/health", timeout=2)
                if response.status_code == 200:
                    latencies.append((time.time() - start) * 1000)
            
            if not latencies:  # 如果无法连接，设置默认值
                node.update({
                    'latency': float('inf'),
                    'sync_status': "unreachable",
                    'status_str': "不可达",
                    'status_icon': "❌",
                    'http_available': False,
                    'ws_available': False,
                    'ws_10001_available': False
                })
                continue
                
            # 记录延迟和HTTP可用性
            node.update({
                'latency': sum(latencies) / len(latencies),
                'http_available': True
            })
            
            # 2. 获取主网和节点的区块高度并一起显示
            mainnet_slot = get_mainnet_slot(config)
            if mainnet_slot > 0:
                print(f"\n{'='*30} 测试节点: {node['ip']} {'='*30}")
                print(f"[主网] 当前区块高度: {mainnet_slot:,}")
            
            response = requests.post(
                f"http://{node['ip']}:8899",
                json={"jsonrpc": "2.0", "id": 1, "method": "getSlot"},
                headers={"Content-Type": "application/json"},
                timeout=2
            )
            
            if response.status_code == 200 and mainnet_slot > 0:
                node_slot = response.json().get("result", 0)
                if node_slot > 0:
                    # 计算区块差异
                    slot_diff = node_slot - mainnet_slot
                    
                    # 更新所有相关信息
                    node.update({
                        'slot': node_slot,
                        'mainnet_slot': mainnet_slot,
                        'slot_diff': slot_diff,
                        'slot_diff_str': f"+{slot_diff:,}" if slot_diff > 0 else f"{slot_diff:,}"
                    })
                    
                    # 设置同步状态
                    if abs(slot_diff) <= config.get('max_slot_diff', 200):
                        node.update({
                            'sync_status': "synced",
                            'status_str': "已同步",
                            'status_icon': "✔️"
                        })
                    elif abs(slot_diff) <= 500:
                        node.update({
                            'sync_status': "syncing",
                            'status_str': "同步中",
                            'status_icon': "⚠️"
                        })
                    else:
                        node.update({
                            'sync_status': "out_of_sync",
                            'status_str': "未同步",
                            'status_icon': "❌"
                        })

                    # 获取IP信息和供应商信息
                    ip_info = get_ip_info(node['ip'], config)
                    if ip_info:
                        update_node_info(node, ip_info)
                    
                    # 在同一组信息中显示节点状态
                    print(f"[节点] 区块高度: {node_slot:,}")
                    print(f"[状态] {node['ip']:<15} | "
                          f"延迟: {node['latency']:>6.1f}ms | "
                          f"差异: {node.get('slot_diff_str', ''):>10} | "
                          f"供应商: {node.get('provider', 'Unknown')}")
                    print(f"{'='*80}\n")  # 添加分隔线
                    
        except Exception as e:
            print(f"{Colors.WARNING}[警告] 测试节点 {node['ip']} 失败: {str(e)[:100]}{Colors.ENDC}\n")

    # 生成报告
    generate_full_report(nodes, config, time.time())
    generate_human_readable_report(nodes, config, time.time())

    return nodes

def print_best_nodes(ranked_nodes: List[Dict]):
    """打印最优节点信息"""
    if not ranked_nodes:
        print(f"{Colors.WARNING}[警告] 未找到可用节点{Colors.ENDC}")
        return

    print(f"\n{Colors.HEADER}{'='*40} 推荐节点 {'='*40}{Colors.ENDC}")
    print(f"{Colors.OKGREEN}[推荐] 以下是延迟最低且稳定性最好的3个节点:{Colors.ENDC}\n")
    
    for i, node in enumerate(ranked_nodes[:3], 1):
        print(f"{Colors.BOLD}节点 {i}:{Colors.ENDC}")
        print(f"├─ IP地址: {node['ip']}")
        print(f"├─ 延迟: {node['avg_latency']:.1f}ms")
        print(f"├─ 机房位置: {node.get('location', 'Unknown')}")
        print(f"├─ 服务商: {node.get('provider', 'Unknown')}")
        print(f"├─ 稳定性: {node['stability']:.1f}%")
        print(f"├─ HTTP RPC: {node['http_url']}")
        print(f"└─ WebSocket: {node['ws_url']}\n")

def scan_batch(ips: List[str], current_range: str, config: Dict) -> List[Dict]:
    """批量扫描IP"""
    batch_start = time.time()
    results = []
    open_ports_count = 0
    
    # 更新显示当前IP段
    show_progress(total_ips, scanned_count, start_time, stats, current_range)
    
    # 1. 首先快速检查端口
    open_ports = []
    with ThreadPoolExecutor(max_workers=thread_count) as executor:
        port_futures = {
            executor.submit(check_port_open, ip, timeout=0.5): ip
            for ip in ips
        }
        
        for future in as_completed(port_futures):
            ip = port_futures[future]
            try:
                if future.result(timeout=0.5):
                    open_ports.append(ip)
                    open_ports_count += 1
                    stats.port_open += 1  # 更新端口开放统计
            except Exception as e:
                if "timeout" in str(e).lower():
                    stats.http_failed += 1
            finally:
                with scanned_count.get_lock():
                    scanned_count.value += 1
                    stats.total_scanned += 1
    
    # 2. 只对开放端口的IP进行RPC验证
    if open_ports:
        with ThreadPoolExecutor(max_workers=thread_count) as executor:
            rpc_futures = {
                executor.submit(verify_rpc_node, ip, config, timeout=3): ip
                for ip in open_ports
            }
            for future in as_completed(rpc_futures):
                ip = rpc_futures[future]  # 修正：使用rpc_futures而不是port_futures
                try:
                    is_valid, node_info = future.result(timeout=3)
                    if is_valid:
                        node_info['ip'] = ip
                        stats.add_valid_node(node_info)  # 更新有效节点统计
                        results.append({
                            **node_info,
                            "last_checked": time.strftime("%Y-%m-%d %H:%M:%S")
                        })
                        # 确保保存时包含所有必要信息
                        save_node_to_file({
                            **node_info,
                            "last_checked": time.strftime("%Y-%m-%d %H:%M:%S")
                        }, "/root/results.txt")
                        print_node_discovery(node_info)
                        stats.update_sync_stats(node_info["sync_status"] == "synced")
                        stats.update_ws1001_stats(node_info["ws_10001_available"])
                    else:
                        # 如果验证失败但返回了原因，更新相应的统计
                        if node_info.get('fail_reason') == 'high_latency':
                            stats.high_latency += 1
                        elif node_info.get('fail_reason') == 'sync_failed':
                            stats.sync_failed += 1
                except Exception as e:
                    if "timeout" in str(e).lower():
                        stats.http_failed += 1
                    elif "websocket" in str(e).lower():
                        stats.ws_failed += 1
                    print(f"{Colors.WARNING}[警告] 验证节点 {ip} 失败: {str(e)[:100]}{Colors.ENDC}")
    
    batch_time = time.time() - batch_start
    print_batch_stats(results, batch_time, open_ports_count, len(ips))
    return results

def print_batch_stats(batch_results: List[Dict], batch_time: float, open_ports: int, batch_size: int):
    """打印每个批次的详细统计信息"""
    print(f"\n{Colors.HEADER}{'='*40} 批次统计 {'='*40}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.OKBLUE}性能指标:{Colors.ENDC}")
    print(f"├─ 批处理耗时: {batch_time:.2f}秒")
    print(f"├─ 处理速度: {batch_size/batch_time:.1f} IP/s")
    print(f"└─ 平均单IP耗时: {(batch_time/batch_size)*1000:.2f}ms")
    
    print(f"\n{Colors.BOLD}{Colors.OKBLUE}端口统计:{Colors.ENDC}")
    print(f"├─ 开放端口数: {open_ports}")
    print(f"├─ 总扫描数: {batch_size}")
    print(f"├─ 开放率: {(open_ports/batch_size)*100:.2f}%")
    print(f"└─ 关闭端口: {batch_size - open_ports}")
    
    if batch_results:
        print(f"\n{Colors.BOLD}{Colors.OKGREEN}节点发现:{Colors.ENDC}")
        print(f"├─ 发现节点数: {len(batch_results)}")
        print(f"├─ 有效率: {(len(batch_results)/open_ports)*100:.2f}% (基于开放端口)")
        print(f"└─ 成功率: {(len(batch_results)/batch_size)*100:.4f}% (基于总数)")
    print(f"\n{Colors.HEADER}{'='*89}{Colors.ENDC}")

def scan_all_built_in_providers(config: Dict) -> List[Dict]:
    """扫描所有内置供应商的节点"""
    print(f"\n{Colors.HEADER}[开始] 正在扫描所有内置供应商...{Colors.ENDC}")
    
    # 获取所有内置供应商
    all_providers = list(ASN_MAP.keys())
    print(f"{Colors.OKBLUE}[信息] 共发现 {len(all_providers)} 个内置供应商:{Colors.ENDC}")
    for i, provider in enumerate(all_providers, 1):  # 修复可能的for循环语法错误
        print(f"{Colors.OKGREEN}{i}. {provider}{Colors.ENDC}")
    
    # 收集所有IP
    all_ips = []
    total_networks = 0
    
    print(f"\n{Colors.HEADER}[第一阶段] 收集所有供应商的IP...{Colors.ENDC}")
    
    for provider in all_providers:  # 修复可能的for循环语法错误
        print(f"\n{Colors.OKBLUE}[收集] 正在获取 {provider} 的IP列表...{Colors.ENDC}")
        asn_list = ASN_MAP[provider]
        if isinstance(asn_list, str):
            asn_list = [asn_list]
            
        for asn in asn_list:  # 修复可能的for循环语法错误
            print(f"{Colors.OKBLUE}[ASN] 正在获取 ASN {asn} 的IP段...{Colors.ENDC}")
            ip_ranges = get_asn_prefixes(asn)
            if ip_ranges:
                print(f"{Colors.OKGREEN}[成功] ASN {asn} 获取到 {len(ip_ranges)} 个IP段{Colors.ENDC}")
                total_networks += len(ip_ranges)
                for ip_range in ip_ranges:  # 修复可能的for循环语法错误
                    try:
                        network = ipaddress.ip_network(ip_range)
                        if network.version == 4:  # 只处理IPv4
                            all_ips.extend(str(ip) for ip in network.hosts())
                    except Exception as e:
                        print(f"{Colors.WARNING}[警告] 处理IP段 {ip_range} 失败: {str(e)}{Colors.ENDC}")
            else:
                print(f"{Colors.WARNING}[警告] ASN {asn} 未获取到IP段{Colors.ENDC}")
    
    if not all_ips:
        print(f"{Colors.FAIL}[错误] 未获取到任何可用IP{Colors.ENDC}")
        return []
    
    # 去重
    all_ips = list(set(all_ips))
    print(f"\n{Colors.HEADER}[统计] 共收集到:{Colors.ENDC}")
    print(f"{Colors.OKGREEN}├─ IP段数量: {total_networks}{Colors.ENDC}")
    print(f"{Colors.OKGREEN}├─ 总IP数量: {len(all_ips):,}{Colors.ENDC}")
    print(f"{Colors.OKGREEN}└─ 去重后IP: {len(all_ips):,}{Colors.ENDC}")
    
    # 开始扫描
    print(f"\n{Colors.HEADER}[第二阶段] 开始扫描所有IP...{Colors.ENDC}")
    
    # 重置计数器和统计
    global scanned_count, stop_event, total_ips, thread_count, start_time, stats
    scanned_count = multiprocessing.Value('i', 0)
    stop_event = Event()
    total_ips = len(all_ips)
    thread_count = min(8000, get_optimal_thread_count())
    start_time = time.time()
    stats = ScanStats()
    
    # 启动进度显示线程
    progress_thread = threading.Thread(
        target=show_progress, 
        args=(total_ips, scanned_count, start_time, stats, "All Built-in Providers")
    )
    progress_thread.daemon = True
    progress_thread.start()
    
    results = []
    batch_size = 5000
    
    try:
        for i in range(0, len(all_ips), batch_size):
            batch = all_ips[i:i + batch_size]
            batch_results = scan_batch(batch, "All Providers", config)
            results.extend(batch_results)
            
            # 实时显示发现的节点数
            if batch_results:
                print(f"\n{Colors.OKGREEN}[发现] 本批次发现 {len(batch_results)} 个新节点{Colors.ENDC}")
                print(f"{Colors.OKGREEN}[总计] 目前共发现 {len(results)} 个有效节点{Colors.ENDC}")
    
    finally:
        stop_event.set()
        progress_thread.join()
    
    # 打印最终统计
    elapsed = time.time() - start_time
    print(f"\n{Colors.HEADER}[完成] 扫描结束{Colors.ENDC}")
    print(f"{Colors.OKGREEN}├─ 总耗时: {int(elapsed//60)}分{int(elapsed%60)}秒{Colors.ENDC}")
    print(f"{Colors.OKGREEN}├─ 扫描速度: {total_ips/elapsed:.1f} IP/s{Colors.ENDC}")
    print(f"{Colors.OKGREEN}└─ 发现节点: {len(results)} 个{Colors.ENDC}")
    
    # 显示扫描统计
    show_scan_stats(stats)
    
    if results:
        save_results(results)
        print(f"\n{Colors.HEADER}[测试] 开始测试所有发现的节点{Colors.ENDC}")
        ranked_nodes = test_and_rank_nodes()
        print_best_nodes(ranked_nodes)
    
    return results

def print_node_discovery(node_info: Dict):
    """打印新发现的节点信息"""
    print(f"\n{Colors.OKGREEN}{'='*40} 发现新节点 {'='*40}{Colors.ENDC}")
    print(f"{Colors.BOLD}节点信息:{Colors.ENDC}")
    print(f"├─ IP地址: {node_info['ip']}")
    print(f"├─ 延迟: {node_info.get('latency', 'N/A')}ms")
    print(f"├─ 位置: {node_info.get('city', 'Unknown')}, {node_info.get('country', 'Unknown')}")
    print(f"├─ 服务商: {node_info.get('provider', 'Unknown')}")
    print(f"├─ HTTP RPC: http://{node_info['ip']}:8899")
    print(f"└─ WebSocket: ws://{node_info['ip']}:8900")
    print(f"{Colors.OKGREEN}{'='*89}{Colors.ENDC}")

# 新增主网区块获取函数
def get_mainnet_slot(config: Dict) -> int:
    """从多个主网节点获取最新slot"""
    headers = {"Content-Type": "application/json"}
    payload = {"jsonrpc":"2.0","id":1,"method":"getSlot"}
    
    for node in config["mainnet_rpc_nodes"]:
        try:
            response = requests.post(node, json=payload, headers=headers, timeout=3)
            if response.status_code == 200:
                result = response.json().get("result")
                if isinstance(result, int) and result > 0:
                    print(f"{Colors.OKBLUE}[主网] 当前区块高度: {result:,}{Colors.ENDC}")
                    return result
        except Exception as e:
            print(f"{Colors.WARNING}[主网] 无法从 {node} 获取slot: {str(e)}{Colors.ENDC}")
            continue
    
    print(f"{Colors.FAIL}[错误] 无法从任何主网节点获取区块高度{Colors.ENDC}")
    return 0

# 新增报告生成函数
def generate_full_report(nodes: List[Dict], config: Dict, start_time: float):
    """生成完整测试报告"""
    # 使用第一个有效节点的mainnet_slot作为参考值
    mainnet_slot = next((n['mainnet_slot'] for n in nodes if 'mainnet_slot' in n), 0)
    avg_slot_diff = sum(n.get("slot_diff", 0) for n in nodes) / len(nodes) if nodes else 0
    
    report_data = {
        "metadata": {
            "scan_time": time.strftime("%Y-%m-%d %H:%M:%S"),
            "duration_sec": time.time() - start_time,
            "total_nodes": len(nodes),
            "config": config
        },
        "network_status": {
            "mainnet_slot": mainnet_slot,
            "avg_slot_diff": avg_slot_diff
        },
        "nodes": []
    }
    
    for node in nodes:
        # 使用节点自己的mainnet_slot
        node_mainnet_slot = node.get('mainnet_slot', mainnet_slot)
        report_data["nodes"].append({
            "ip": node.get("ip", "Unknown"),
            "latency_ms": node.get("latency", 0),
            "location": {
                "city": node.get("city", "Unknown"),
                "region": node.get("region", "Unknown"),
                "country": node.get("country", "Unknown")
            },
            "connectivity": {
                "http": node.get("http_available", False),
                "ws_8900": node.get("ws_available", False),
                "ws_10001": node.get("ws_10001_available", False)
            },
            "sync_status": {
                "node_slot": node.get("slot", 0),
                "mainnet_slot": node_mainnet_slot,
                "slot_diff": node.get("slot_diff", 0),
                "status": node.get("sync_status", "unknown")
            },
            "provider": node.get("provider", "Unknown"),
            "last_checked": node.get("last_checked", "Unknown")
        })
    
    try:
        with open("/root/node_full_report.json", "w") as f:
            json.dump(report_data, f, indent=2)
        print(f"{Colors.OKGREEN}[报告] 完整测试报告已保存至 /root/node_full_report.json{Colors.ENDC}")
    except Exception as e:
        print(f"{Colors.FAIL}[错误] 无法写入报告文件: {str(e)}{Colors.ENDC}")

def generate_human_readable_report(nodes: List[Dict], config: Dict, start_time: float):
    """生成易读文本报告"""
    report_path = "/root/node_human_readable_report.txt"
    
    total_nodes = len(nodes)
    max_slot_diff = config.get('max_slot_diff', 200)
    
    # 直接使用节点中保存的数据，不重新计算
    synced = sum(1 for n in nodes if n.get('sync_status') == "synced")
    syncing = sum(1 for n in nodes if n.get('sync_status') == "syncing")
    out_of_sync = total_nodes - synced - syncing
    
    # 使用第一个有效节点的mainnet_slot
    mainnet_slot = next((n['mainnet_slot'] for n in nodes if 'mainnet_slot' in n), 0)
    
    # 地理分布分析
    locations = Counter(
        f"{n.get('city', 'Unknown')},{n.get('country', 'Unknown')}" 
        for n in nodes
    )
    
    location_dist = "\n".join(
        f"   - {loc}: {count} 个节点" 
        for loc, count in locations.most_common()
    )
    
    # 生成报告头部
    report = f"""
{'='*50} Solana RPC节点扫描报告 {'='*50}
扫描时间: {time.strftime('%Y-%m-%d %H:%M:%S')}    总耗时: {time.time()-start_time:.1f}秒    总节点数: {total_nodes}

【网络状态概览】
✅ 主网最新区块高度: {mainnet_slot:,}
📊 节点区块状态:
   - 同步节点(差异≤{max_slot_diff}): {synced} 个
   - 同步中节点(差异≤500): {syncing} 个
   - 不同步节点: {out_of_sync} 个
🌐 可用节点地理分布:
{location_dist}

【关键指标统计】
🟢 完全同步节点: {synced} ({synced/total_nodes:.1%})    
🟡 同步中节点: {syncing} ({syncing/total_nodes:.1%})       
🔴 不同步节点: {out_of_sync} ({out_of_sync/total_nodes:.1%})        
🔌 端口可用性: 
   - HTTP(8899): {sum(n.get('http_available', False) for n in nodes)}/{total_nodes}
   - WS(8900): {sum(n.get('ws_available', False) for n in nodes)}/{total_nodes}
   - WS(10001): {sum(n.get('ws_10001_available', False) for n in nodes)}/{total_nodes}

【节点详细列表】📋
{"序号":<4} | {"IP地址":<15} | {"延迟(ms)":<8} | {"服务商":<12} | {"位置":<20} | {"区块差异":<12} | {"状态":<8} | {"端口":<15}
{'='*100}
"""

    # 添加节点列表，使用已保存的差异值
    for i, node in enumerate(sorted(nodes, key=lambda x: x.get('latency', 999.9)), 1):
        ports_status = []
        if node.get('http_available'): ports_status.append("HTTP")
        if node.get('ws_available'): ports_status.append("WS")
        if node.get('ws_10001_available'): ports_status.append("WS10001")
        ports = ",".join(ports_status) if ports_status else "无"
        
        report += (
            f"{i:<4} | {node['ip']:<15} | {node.get('latency', 999.9):<8.1f} | "
            f"{node.get('provider', 'Unknown')[:12]:<12} | "
            f"{node.get('city', 'Unknown')[:8]},{node.get('country', 'Unknown'):<8} | "
            f"{node.get('slot_diff_str', ''):>12} | {node.get('status_icon', '❌'):<8} | {ports:<15}\n"
        )

    report += "\n【节点详情】\n"
    for i, node in enumerate(nodes, 1):
        report += f"""
{i}. {node['ip']}
   - 延迟: {node.get('latency', 999.9):.1f}ms  | 服务商: {node.get('provider', 'Unknown')}
   - 位置: {node.get('city', 'Unknown')}, {node.get('country', 'Unknown')}
   - 端口状态: 
     {'✔️' if node.get('http_available') else '❌'} HTTP: http://{node['ip']}:8899
     {'✔️' if node.get('ws_available') else '❌'} WS8900: ws://{node['ip']}:8900
     {'✔️' if node.get('ws_10001_available') else '❌'} WS10001: ws://{node['ip']}:10001
   - 区块高度: {node.get('slot', 0):,} (与主网差异: {node.get('slot_diff_str', '')})
   - 同步状态: {node.get('status_str', '未知')}
   - 最后检测: {node.get('last_checked', 'Unknown')}
"""

    # 保存报告
    try:
        with open(report_path, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"{Colors.OKGREEN}[报告] 易读版报告已保存至 {report_path}{Colors.ENDC}")
    except Exception as e:
        print(f"{Colors.FAIL}[错误] 无法写入报告文件: {str(e)}{Colors.ENDC}")

def get_provider_name(ip_info: Dict) -> str:
    """从IP信息中获取供应商名称"""
    if not ip_info:
        return "Unknown"
        
    org = ip_info.get('org', '')
    if not org:
        return "Unknown"
        
    # 从ASN映射表中查找供应商名称
    asn = org.split()[0].upper().replace('AS', '')  # 移除AS前缀
    for provider, asn_list in ASN_MAP.items():
        if isinstance(asn_list, list):
            if asn in asn_list:
                return provider
        elif asn == str(asn_list):
            return provider
            
    # 如果在映射表中找不到，使用组织名称
    # 移除AS号，只保留公司名称
    org_name = ' '.join(org.split()[1:]) if org.upper().startswith('AS') else org
    return org_name if org_name else "Unknown"

# 在更新节点信息时使用这个函数
def update_node_info(node: Dict, ip_info: Dict):
    """更新节点信息
    Args:
        node: 节点信息字典
        ip_info: IP信息字典
    """
    if ip_info:
        node.update({
            'provider': get_provider_name(ip_info),
            'city': ip_info.get('city', 'Unknown'),
            'region': ip_info.get('region', 'Unknown'),
            'country': ip_info.get('country', 'Unknown'),
            'hostname': ip_info.get('hostname', 'Unknown'),
            'org': ip_info.get('org', 'Unknown')
        })

def scan_ip_ranges(ip_ranges: List[str], config: Dict) -> List[Dict]:
    """扫描IP段列表"""
    # 添加分隔线和标题
    print("\n开始检测IP可用性...")
    print("-" * 70)
    print("\n")
    
    # 创建表格头部
    print("┌─────────┬──────────┬──────────┬─────────┬──────────────┬────────────────────────────┬───────────────────────────┐")
    print("│    IP   │   延迟   │   机房   │  地区   │     国家     │         HTTP地址           │         WS地址            │")
    print("├─────────┼──────────┼──────────┼─────────┼──────────────┼────────────────────────────┼───────────────────────────┤")
    # 移除空行,只保留表头
    
    results = []
    total_ranges = len(ip_ranges)
    start_time = time.time()
    last_update_time = start_time
    last_scanned = 0
    total_ips = 0
    
    # 计算总IP数
    for ip_range in ip_ranges:
        network = ipaddress.ip_network(ip_range, strict=False)
        total_ips += network.num_addresses
    
    scanned_ips = 0
    
    print(f"{Colors.OKBLUE}[扫描] 开始扫描 {total_ranges} 个IP段...{Colors.ENDC}")
    
    # 初始化统计信息
    stats = ScanStats()
    
    # 创建线程池，增加最大线程数
    max_workers = min(config.get('max_threads', 2000), 1000)  # 增加到1000个线程
    
    # 使用信号量控制并发IP段数
    sem = threading.Semaphore(20)  # 增加到20个并发IP段
    
    # 显示扫描配置信息
    print(f"{Colors.OKBLUE}[配置] 最大线程数: {max_workers}{Colors.ENDC}")
    print(f"{Colors.OKBLUE}[配置] 批处理大小: 200{Colors.ENDC}")  # 增加批处理大小到200
    print(f"{Colors.OKBLUE}[配置] 并发IP段数: 20{Colors.ENDC}\n")
    
    def show_progress():
        """显示进度和时间信息"""
        elapsed = time.time() - start_time
        progress = i / total_ranges
        remaining = (elapsed / progress) * (1 - progress) if progress > 0 else 0
        total = elapsed + remaining
        
        # 修正扫描速度计算
        current_time = time.time()
        elapsed_since_start = current_time - start_time
        if elapsed_since_start > 0:
            scan_speed = scanned_ips / elapsed_since_start
            scan_speed_str = f"{scan_speed:.1f}"
        else:
            scan_speed_str = "0"
        
        # 创建进度条
        bar_width = 50
        filled = int(bar_width * progress)
        bar = '#' * filled + '-' * (bar_width - filled)
        
        # 格式化时间
        def format_time(seconds):
            hours = int(seconds // 3600)
            minutes = int((seconds % 3600) // 60)
            secs = int(seconds % 60)
            if hours > 0:
                return f"{hours}时{minutes}分{secs}秒"
            elif minutes > 0:
                return f"{minutes}分{secs}秒"
            else:
                return f"{secs}秒"
        
        print(f"\n{Colors.OKBLUE}进度: [{bar}] {progress*100:.1f}%{Colors.ENDC}")
        print(f"{Colors.OKBLUE}时间统计:{Colors.ENDC}")
        print(f"- 已用时间: {format_time(elapsed)}")
        print(f"- 剩余时间: {format_time(remaining)}")
        print(f"- 预计总时间: {format_time(total)}")
        print(f"- 扫描速度: {scan_speed_str} IP/秒 ({scanned_ips:,d}/{total_ips:,d})\n")
    
    for i, ip_range in enumerate(ip_ranges, 1):
        try:
            with sem:
                network = ipaddress.ip_network(ip_range, strict=False)
                if network.version != 4:
                    continue
                    
                print(f"{Colors.OKBLUE}[进度] 正在扫描 {ip_range} ({i}/{total_ranges}){Colors.ENDC}")
                
                # 获取IP列表并更新计数
                ips = [str(ip) for ip in network.hosts()]
                scanned_ips += len(ips)  # 更新已扫描IP数
                
                show_progress()  # 显示进度和时间信息
                
                # 使用更大的批处理大小
                batch_size = min(200, len(ips))  # 每批最多200个IP
                
                # 创建新的线程池处理每个批次
                with ThreadPoolExecutor(max_workers=max_workers) as executor:
                    for j in range(0, len(ips), batch_size):
                        batch = ips[j:j+batch_size]
                        futures = []
                        
                        # 提交扫描任务
                        for ip in batch:
                            future = executor.submit(scan_ip, ip, "Unknown", config, stats)
                            futures.append(future)
                        
                        # 收集结果
                        for future in as_completed(futures):
                            try:
                                result = future.result(timeout=5)  # 添加超时控制
                                if result:
                                    results.append(result)
                                    # 修改打印格式，确保 HTTP 地址完整显示
                                    http_url = f"http://{result['ip']}:8899"
                                    ws_url = f"ws://{result['ip']}:8900"
                                    print(f"│{result['ip']:<14}│{result['latency']:>8.1f}ms│{result['city']:<10}│"
                                          f"{result['region']:<9}│{result['country']:<14}│"
                                          f"{http_url:<28}│{ws_url:<27}│")
                                    # 实时保存发现的节点
                                    save_node_to_file(result)
                            except Exception as e:
                                print(f"{Colors.WARNING}[警告] 扫描失败: {str(e)[:100]}{Colors.ENDC}")
                        
                        # 减少休息时间
                        time.sleep(0.05)  # 从0.1秒减少到0.05秒
                
                # 显示当前IP段的扫描结果
                if results:
                    print(f"{Colors.OKGREEN}[发现] IP段 {ip_range} 发现 {len(results)} 个节点{Colors.ENDC}")
                    
        except Exception as e:
            print(f"{Colors.WARNING}[警告] 处理IP段 {ip_range} 失败: {str(e)}{Colors.ENDC}")
            time.sleep(1)  # 出错时等待一秒
            continue
    
    # 显示总体统计信息
    if results:
        # 添加表格底部
        print("└─────────┴──────────┴──────────┴─────────┴──────────────┴────────────────────────────┴───────────────────────────┘")
        print(f"\n{Colors.OKGREEN}[完成] 共扫描 {total_ranges} 个IP段，发现 {len(results)} 个节点{Colors.ENDC}")
        show_scan_stats(stats)
    else:
        # 如果没有结果,也要关闭表格
        print("└─────────┴──────────┴──────────┴─────────┴──────────────┴────────────────────────────┴───────────────────────────┘")
        print(f"\n{Colors.WARNING}[完成] 未发现可用节点{Colors.ENDC}")
    
    return results

def check_scan_status():
    """检查扫描状态"""
    try:
        with open("scan_pid.txt", "r") as f:
            pid = int(f.read().strip())
            if os.path.exists(f"/proc/{pid}"):
                print(f"[状态] 扫描进程 {pid} 正在运行")
                return True
            else:
                print("[状态] 没有正在运行的扫描进程")
                return False
    except:
        print("[状态] 没有正在运行的扫描进程")
        return False

def get_validator_ips() -> List[str]:
    """从 solana gossip 获取验证者节点IP列表"""
    try:
        cmd = ["solana", "gossip"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # 解析输出提取IP地址
        ips = []
        for line in result.stdout.splitlines():
            ip_match = re.search(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', line)
            if ip_match:
                ips.append(ip_match.group())
                
        return list(set(ips))  # 去重
    except Exception as e:
        print(f"{Colors.FAIL}[错误] 获取验证者节点列表失败: {e}{Colors.ENDC}")
        return []

def get_24_subnet(ip: str) -> str:
    """获取IP所在的/24子网"""
    try:
        # 将IP转换为网络对象
        ip_obj = ipaddress.ip_address(ip)
        # 获取/24网段
        network = ipaddress.ip_network(f"{ip_obj.exploded.rsplit('.', 1)[0]}.0/24", strict=False)
        return str(network)
    except Exception as e:
        print(f"{Colors.WARNING}[警告] 处理IP {ip} 失败: {e}{Colors.ENDC}")
        return None

def check_solana_cli() -> bool:
    """检查 Solana CLI 是否可用"""
    try:
        result = subprocess.run(["solana", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            version = result.stdout.strip()
            print(f"{Colors.OKGREEN}[信息] 检测到 Solana CLI: {version}{Colors.ENDC}")
            return True
        return False
    except:
        return False

def scan_validator_subnets(config: Dict) -> List[Dict]:
    """扫描验证者节点所在的/24子网"""
    print(f"\n{Colors.HEADER}[开始] 获取验证者节点列表...{Colors.ENDC}")
    
    # 检查 Solana CLI
    if not check_solana_cli():
        print(f"{Colors.FAIL}[错误] 未检测到 Solana CLI，请按以下步骤安装:{Colors.ENDC}")
        print(f"{Colors.WARNING}1. 运行安装命令:{Colors.ENDC}")
        print("   curl -sSfL https://release.anza.xyz/v2.0.18/install | sh")
        print(f"{Colors.WARNING}2. 更新环境变量:{Colors.ENDC}")
        print("   export PATH=\"/root/.local/share/solana/install/active_release/bin:$PATH\"")
        print(f"{Colors.WARNING}3. 验证安装:{Colors.ENDC}")
        print("   solana --version")
        return []
    
    # 获取验证者节点IP
    validator_ips = get_validator_ips()
    if not validator_ips:
        print(f"{Colors.FAIL}[错误] 未能获取验证者节点列表{Colors.ENDC}")
        return []
        
    print(f"{Colors.OKGREEN}[信息] 获取到 {len(validator_ips)} 个验证者节点{Colors.ENDC}")
    
    # 获取所有/24子网
    subnets = set()
    for ip in validator_ips:
        subnet = get_24_subnet(ip)
        if subnet:
            subnets.add(subnet)
    
    print(f"{Colors.OKBLUE}[扫描] 将扫描 {len(subnets)} 个/24子网{Colors.ENDC}")
    print("子网列表:")
    for subnet in subnets:
        print(f"- {subnet}")
    
    # 扫描这些子网
    results = []
    for subnet in subnets:
        print(f"\n{Colors.OKBLUE}[扫描] 正在扫描子网 {subnet}{Colors.ENDC}")
        subnet_results = scan_ip_ranges([subnet], config)
        
        # 确保每个结果都有完整的信息
        for result in subnet_results:
            if 'ip' in result:
                # 获取IP信息（包括供应商和位置信息）
                ip_info = get_ip_info(result['ip'].split(':')[0], config)
                if ip_info:
                    result.update({
                        'provider': get_provider_name(ip_info),
                        'city': ip_info.get('city', 'Unknown'),
                        'region': ip_info.get('region', 'Unknown'),
                        'country': ip_info.get('country', 'Unknown'),
                        'org': ip_info.get('org', 'Unknown')
                    })
                results.append(result)
    
    # 生成详细报告
    if results:
        print(f"\n{Colors.OKGREEN}[完成] 扫描完成，正在生成报告...{Colors.ENDC}")
        
        # 生成验证者节点专用报告
        report_path = "/root/validator_subnet_report.txt"
        with open(report_path, "w", encoding="utf-8") as f:
            f.write(f"=== Solana 验证者子网扫描报告 ===\n")
            f.write(f"扫描时间: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"扫描子网数: {len(subnets)}\n")
            f.write(f"发现节点数: {len(results)}\n\n")
            
            # 按供应商分组统计
            providers = defaultdict(int)
            locations = defaultdict(int)
            for node in results:
                providers[node.get('provider', 'Unknown')] += 1
                locations[f"{node.get('city', 'Unknown')}, {node.get('country', 'Unknown')}"] += 1
            
            f.write("供应商分布:\n")
            for provider, count in providers.items():
                f.write(f"- {provider}: {count} 个节点\n")
            
            f.write("\n地理分布:\n")
            for location, count in locations.items():
                f.write(f"- {location}: {count} 个节点\n")
            
            f.write("\n节点详细信息:\n")
            f.write("=" * 80 + "\n")
            for node in sorted(results, key=lambda x: x.get('latency', 999.9)):
                f.write(f"\nIP: {node['ip']}\n")
                f.write(f"供应商: {node.get('provider', 'Unknown')}\n")
                f.write(f"位置: {node.get('city', 'Unknown')}, {node.get('country', 'Unknown')}\n")
                f.write(f"延迟: {node.get('latency', 0):.1f}ms\n")
                f.write(f"HTTP: http://{node['ip']}:8899\n")
                f.write(f"WS: ws://{node['ip']}:8900\n")
                f.write("-" * 40 + "\n")
        
        print(f"{Colors.OKGREEN}[报告] 详细报告已保存至 {report_path}{Colors.ENDC}")
    
    return results

def scan_validator_subnets_smart(config: Dict) -> List[Dict]:
    """智能扫描验证者节点所在的/24子网"""
    print(f"\n{Colors.HEADER}[开始] 获取验证者节点列表...{Colors.ENDC}")
    
    # 检查 Solana CLI
    if not check_solana_cli():
        print(f"{Colors.FAIL}[错误] 未检测到 Solana CLI，请按以下步骤安装:{Colors.ENDC}")
        print(f"{Colors.WARNING}1. 运行安装命令:{Colors.ENDC}")
        print("   curl -sSfL https://release.anza.xyz/v2.0.18/install | sh")
        print(f"{Colors.WARNING}2. 更新环境变量:{Colors.ENDC}")
        print("   export PATH=\"/root/.local/share/solana/install/active_release/bin:$PATH\"")
        print(f"{Colors.WARNING}3. 验证安装:{Colors.ENDC}")
        print("   solana --version")
        return []
    
    # 获取验证者节点IP
    validator_ips = get_validator_ips()
    if not validator_ips:
        print(f"{Colors.FAIL}[错误] 未能获取验证者节点列表{Colors.ENDC}")
        return []
        
    print(f"{Colors.OKGREEN}[信息] 获取到 {len(validator_ips)} 个验证者节点{Colors.ENDC}")
    
    # 统计每个子网中的验证者数量
    subnets = set()
    validator_count_per_subnet = defaultdict(int)
    for ip in validator_ips:
        subnet = get_24_subnet(ip)
        if subnet:
            subnets.add(subnet)
            validator_count_per_subnet[subnet] += 1
    
    # 按验证者数量排序子网
    sorted_subnets = sorted(
        list(subnets),
        key=lambda x: validator_count_per_subnet[x],
        reverse=True
    )
    
    # 只扫描验证者较多的子网（前100个）
    scan_limit = 100
    selected_subnets = sorted_subnets[:scan_limit]
    
    total_ips = len(selected_subnets) * 254
    print(f"\n{Colors.OKBLUE}[优化] 从 {len(subnets)} 个子网中选择了 {len(selected_subnets)} 个最活跃的子网{Colors.ENDC}")
    print(f"{Colors.OKBLUE}[信息] 预计扫描 {total_ips:,} 个IP地址{Colors.ENDC}")
    
    print("\n活跃子网统计:")
    for subnet in selected_subnets[:10]:
        print(f"- {subnet}: {validator_count_per_subnet[subnet]} 个验证者")
    
    if input(f"\n{Colors.WARNING}是否继续扫描? (y/n): {Colors.ENDC}").lower() != 'y':
        return []
    
    # 扫描选定的子网
    results = []
    for subnet in selected_subnets:
        print(f"\n{Colors.OKBLUE}[扫描] 正在扫描子网 {subnet} (验证者数量: {validator_count_per_subnet[subnet]}){Colors.ENDC}")
        subnet_results = scan_ip_ranges([subnet], config)
        
        # 确保每个结果都有完整的信息
        for result in subnet_results:
            if 'ip' in result:
                ip_info = get_ip_info(result['ip'].split(':')[0], config)
                if ip_info:
                    result.update({
                        'provider': get_provider_name(ip_info),
                        'city': ip_info.get('city', 'Unknown'),
                        'region': ip_info.get('region', 'Unknown'),
                        'country': ip_info.get('country', 'Unknown'),
                        'org': ip_info.get('org', 'Unknown')
                    })
                results.append(result)
    
    # 生成详细报告
    if results:
        print(f"\n{Colors.OKGREEN}[完成] 扫描完成，正在生成报告...{Colors.ENDC}")
        
        report_path = "/root/validator_subnet_smart_report.txt"
        with open(report_path, "w", encoding="utf-8") as f:
            f.write(f"=== Solana 验证者子网智能扫描报告 ===\n")
            f.write(f"扫描时间: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"扫描子网数: {len(selected_subnets)} (从 {len(subnets)} 个子网中选择)\n")
            f.write(f"发现节点数: {len(results)}\n\n")
            
            # 按供应商分组统计
            providers = defaultdict(int)
            locations = defaultdict(int)
            for node in results:
                providers[node.get('provider', 'Unknown')] += 1
                locations[f"{node.get('city', 'Unknown')}, {node.get('country', 'Unknown')}"] += 1
            
            f.write("供应商分布:\n")
            for provider, count in providers.items():
                f.write(f"- {provider}: {count} 个节点\n")
            
            f.write("\n地理分布:\n")
            for location, count in locations.items():
                f.write(f"- {location}: {count} 个节点\n")
            
            f.write("\n节点详细信息:\n")
            f.write("=" * 80 + "\n")
            for node in sorted(results, key=lambda x: x.get('latency', 999.9)):
                f.write(f"\nIP: {node['ip']}\n")
                f.write(f"供应商: {node.get('provider', 'Unknown')}\n")
                f.write(f"位置: {node.get('city', 'Unknown')}, {node.get('country', 'Unknown')}\n")
                f.write(f"延迟: {node.get('latency', 0):.1f}ms\n")
                f.write(f"HTTP: http://{node['ip']}:8899\n")
                f.write(f"WS: ws://{node['ip']}:8900\n")
                f.write("-" * 40 + "\n")
        
        print(f"{Colors.OKGREEN}[报告] 详细报告已保存至 {report_path}{Colors.ENDC}")
    
    return results

if __name__ == "__main__":
    main() 
