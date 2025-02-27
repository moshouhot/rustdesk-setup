#!binbash

# 检查是否以root权限运行
if [ $EUID -ne 0 ]; then 
    echo 请使用 sudo 运行此脚本
    exit 1
fi

# 检查并安装 Docker
if ! command -v docker & devnull; then
    echo Docker 未安装，正在安装...
    apt update
    apt install -y docker.io
    systemctl start docker
    systemctl enable docker
    if ! command -v docker & devnull; then
        echo Docker 安装失败，请手动检查安装过程。
        exit 1
    fi
    echo Docker 安装成功！
fi

# 检查并安装 Docker Compose
if ! command -v docker-compose & devnull; then
    echo Docker Compose 未安装，正在安装...
    curl -L httpsgithub.comdockercomposereleaseslatestdownloaddocker-compose-$(uname -s)-$(uname -m) -o usrlocalbindocker-compose
    chmod +x usrlocalbindocker-compose
    if ! command -v docker-compose & devnull; then
        echo Docker Compose 安装失败，请手动检查安装过程。
        exit 1
    fi
    echo Docker Compose 安装成功！
fi

# 检查 Docker 服务是否运行
if ! systemctl is-active --quiet docker; then
    echo Docker 服务未运行。正在启动...
    systemctl start docker
    if ! systemctl is-active --quiet docker; then
        echo 无法启动 Docker 服务。请检查 Docker 安装状态。
        exit 1
    fi
fi

echo 环境检查通过，开始安装 RustDesk 服务...

# 创建所需目录
mkdir -p optrustdeskdatarustdeskapi
mkdir -p optrustdeskdatarustdeskserver

# 创建并写入 docker-compose.yml
cat  optrustdeskdocker-compose.yml  'EOF'
services
  rustdesk-api
    container_name rustdesk-api
    environment
      - TZ=AsiaShanghai
      - RUSTDESK_API_RUSTDESK_ID_SERVER=hk.666606.xyz21116
      - RUSTDESK_API_RUSTDESK_RELAY_SERVER=hk.666606.xyz21117
      - RUSTDESK_API_RUSTDESK_API_SERVER=httphk.666606.xyz21114
      - RUSTDESK_API_RUSTDESK_KEY=def12345
    ports
      - 2111421114
    image lejianwenrustdesk-api
    volumes
      - optrustdeskdatarustdeskapiappdata
    networks
      - rustdesk-net
    restart unless-stopped

  hbbs
    container_name hbbs
    image rustdeskrustdesk-serverlatest
    environment
      - RELAY=hk.666606.xyz21117
      - ENCRYPTED_ONLY=1
      - KEY=def12345
    command [hbbs, -k, def12345]
    volumes
      - optrustdeskdatarustdeskserverroot
    network_mode host
    depends_on
      - hbbr
    restart unless-stopped

  hbbr
    container_name hbbr
    image rustdeskrustdesk-serverlatest
    environment
      - KEY=def12345
    command [hbbr, -k, def12345]
    volumes
      - optrustdeskdatarustdeskserverroot
    network_mode host
    restart unless-stopped

networks
  rustdesk-net
    external false
EOF

# 切换到工作目录并启动服务
cd optrustdesk
echo 正在启动服务...
docker-compose up -d

# 等待服务启动
echo 等待服务启动...
sleep 10

# 显示容器运行状态
echo -e n检查容器状态：
docker ps

# 显示容器日志
echo -e n查看容器日志...
echo -e nrustdesk-api 日志
docker logs rustdesk-api
echo -e nhbbs 日志
docker logs hbbs
echo -e nhbbr 日志
docker logs hbbr

echo -e n安装完成！请检查上述日志确认服务是否正常运行。