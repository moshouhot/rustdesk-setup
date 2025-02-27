在VPS上安装和运行这个rustdesk-setup.sh脚本

# 一键安装命令
如果想要一键完成所有操作，可以使用以下命令组合：

```bash
wget https://raw.githubusercontent.com/moshouhot/rustdesk-setup/main/rustdesk-setup.sh && chmod +x rustdesk-setup.sh && sudo ./rustdesk-setup.sh
```

# 注意事项

1. 环境要求：
   - 需要有root权限或sudo权限
   - 系统需要支持Docker
   - 需要确保系统能访问互联网

2. 端口要求：
   - 21114: API服务端口
   - 21116: ID服务器端口
   - 21117: 中继服务器端口
   
3. 防火墙配置：
   如果VPS有防火墙，需要开放以上端口：
```bash
# 如果使用UFW防火墙
sudo ufw allow 21114
sudo ufw allow 21116
sudo ufw allow 21117
```



# 安装后验证
安装完成后，可以通过以下命令检查服务状态：

```bash
# 检查Docker容器状态
docker ps

# 检查各个服务的日志
docker logs rustdesk-api
docker logs hbbs
docker logs hbbr
```

