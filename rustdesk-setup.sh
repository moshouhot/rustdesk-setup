#!/bin/bash

# 检查是否以root权限运行
if [ $EUID -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查并安装 Docker
if ! command -v docker > /dev/null; then
    echo "Docker 未安装，正在安装..."
    apt update
    apt install -y docker.io
    systemctl start docker
    systemctl enable docker
    if ! command -v docker > /dev/null; then
        echo "Docker 安装失败，请手动检查安装过程。"
        exit 1
    fi
    echo "Docker 安装成功！"
fi

# 检查并安装 Docker Compose
if ! command -v docker-compose > /dev/null; then
    echo "Docker Compose 未安装，正在安装..."
    # 下载 docker-compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    # 立即添加执行权限
    chmod +x /usr/local/bin/docker-compose
    # 验证安装
    if ! docker-compose --version; then
        echo "Docker Compose 安装失败，请手动检查安装过程。"
        exit 1
    fi
    echo "Docker Compose 安装成功！"
fi

# 检查 Docker 服务是否运行
if ! systemctl is-active --quiet docker; then
    echo "Docker 服务未运行。正在启动..."
    systemctl start docker
    if ! systemctl is-active --quiet docker; then
        echo "无法启动 Docker 服务。请检查 Docker 安装状态。"
        exit 1
    fi
fi

echo "环境检查通过，开始安装 RustDesk 服务..."

# 创建所需目录
mkdir -p /opt/rustdesk/data/rustdesk-api
mkdir -p /opt/rustdesk/data/rustdesk-server

# 创建并写入 docker-compose.yml
cat > /opt/rustdesk/docker-compose.yml << 'EOF'
version: '3'

services:
  rustdesk-api:
    container_name: rustdesk-api
    environment:
      - TZ=Asia/Shanghai
      - RUSTDESK_API_RUSTDESK_ID_SERVER=hk.666606.xyz:21116
      - RUSTDESK_API_RUSTDESK_RELAY_SERVER=hk.666606.xyz:21117
      - RUSTDESK_API_RUSTDESK_API_SERVER=http://hk.666606.xyz:21114
      - RUSTDESK_API_RUSTDESK_KEY=def12345
    ports:
      - "21114:21114"
    image: lejianwen/rustdesk-api
    volumes:
      - /opt/rustdesk/data/rustdesk-api:/app/data
    networks:
      - rustdesk-net
    restart: unless-stopped

  hbbs:
    container_name: hbbs
    image: rustdesk/rustdesk-server:latest
    environment:
      - RELAY=hk.666606.xyz:21117
      - ENCRYPTED_ONLY=1
      - KEY=def12345
    command: ["hbbs", "-k", "def12345"]
    volumes:
      - /opt/rustdesk/data/rustdesk-server:/root
    network_mode: host
    depends_on:
      - hbbr
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    image: rustdesk/rustdesk-server:latest
    environment:
      - KEY=def12345
    command: ["hbbr", "-k", "def12345"]
    volumes:
      - /opt/rustdesk/data/rustdesk-server:/root
    network_mode: host
    restart: unless-stopped

networks:
  rustdesk-net:
    external: false
EOF

# 切换到工作目录并启动服务
cd /opt/rustdesk
echo "正在启动服务..."
docker-compose up -d

# 等待服务启动
echo "等待服务启动..."
sleep 10

# 检查服务安装状态
check_installation() {
    local all_success=true
    
    # 检查所有容器是否运行
    echo -e "\n正在检查服务状态..."
    
    # 检查 rustdesk-api 容器
    if docker ps | grep -q "rustdesk-api"; then
        echo "✅ rustdesk-api 服务运行正常"
    else
        echo "❌ rustdesk-api 服务未正常运行"
        all_success=false
    fi
    
    # 检查 hbbs 容器
    if docker ps | grep -q "hbbs"; then
        echo "✅ hbbs 服务运行正常"
    else
        echo "❌ hbbs 服务未正常运行"
        all_success=false
    fi
    
    # 检查 hbbr 容器
    if docker ps | grep -q "hbbr"; then
        echo "✅ hbbr 服务运行正常"
    else
        echo "❌ hbbr 服务未正常运行"
        all_success=false
    fi
    
    # 检查端口是否正常监听
    echo -e "\n检查端口状态..."
    if netstat -tuln | grep -q ":21114"; then
        echo "✅ API端口 (21114) 正常监听"
    else
        echo "❌ API端口 (21114) 未正常监听"
        all_success=false
    fi
    
    if netstat -tuln | grep -q ":21116"; then
        echo "✅ ID服务端口 (21116) 正常监听"
    else
        echo "❌ ID服务端口 (21116) 未正常监听"
        all_success=false
    fi
    
    if netstat -tuln | grep -q ":21117"; then
        echo "✅ 中继服务端口 (21117) 正常监听"
    else
        echo "❌ 中继服务端口 (21117) 未正常监听"
        all_success=false
    fi
    
    # 显示安装结果
    echo -e "\n安装状态检查完成！"
    if [ "$all_success" = true ]; then
        echo "✅ RustDesk 服务安装成功并正常运行！"
        echo -e "\n服务访问信息："
        echo "API服务: http://$(hostname -I | awk '{print $1}'):21114"
        echo "ID服务: $(hostname -I | awk '{print $1}'):21116"
        echo "中继服务: $(hostname -I | awk '{print $1}'):21117"
        return 0
    else
        echo "❌ RustDesk 服务安装可能存在问题，请检查上述日志进行排查。"
        return 1
    fi
}

# 显示容器运行状态
echo -e "\n检查容器状态："
docker ps

# 显示容器日志
echo -e "\n查看容器日志..."
echo -e "\nrustdesk-api 日志"
docker logs rustdesk-api
echo -e "\nhbbs 日志"
docker logs hbbs
echo -e "\nhbbr 日志"
docker logs hbbr

# 执行安装检查
check_installation

# 根据检查结果设置退出状态
exit $?