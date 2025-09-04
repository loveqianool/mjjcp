FROM alpine:edge

# 设置环境变量
env SITE=https://api.cjy.me
env TOKEN=MJJ6688
env V2SCAR_NODEID=
env PORT=
env V2SCAR_GRPC_ENDPOINT=127.0.0.1:8079
env V2SCAR_SYNC_TIME=120
env RELAY_NODE_ID=
env V2RAY_VMESS_AEAD_FORCED=false

# 复制必要的文件
COPY --from=ghcr.io/xtls/xray-core /usr/local/bin/xray /usr/local/bin/xray
COPY --from=ehco1996/ehco /bin/ehco /usr/local/bin/ehco

# 安装必要的工具和证书
RUN apk add --no-cache wireguard-tools curl iproute2 ca-certificates openresolv gcompat ip6tables tzdata && \
    sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick && \
    curl https://developers.cloudflare.com/cloudflare-one/static/documentation/connections/Cloudflare_CA.pem -o /usr/local/share/ca-certificates/Cloudflare_CA.pem && \
    chmod 644 /usr/local/share/ca-certificates/Cloudflare_CA.pem && \
    update-ca-certificates

# 下载 v2scar_alpine 和 geosite, geoip 数据
RUN if [ "$(arch)" = "aarch64" ]; then ARCH=linuxarm64; else ARCH=linux64; fi && \
    curl -sL \
      $(curl -s https://api.github.com/repos/jackma778/shx/releases | grep browser_download_url | cut -d '"' -f 4 | grep -m 1 v2scar_$ARCH) \
      -o /usr/local/bin/v2scar && \
      chmod +x /usr/local/bin/v2scar && \
    curl https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat \
      -o /usr/local/bin/geosite.dat && \
    curl https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat \
      -o /usr/local/bin/geoip.dat

# 创建启动脚本
RUN cat > /z.sh <<'EOT'
#!/bin/sh

mkdir /etc/xray
cd /etc/xray
echo "token=$TOKEN" > /etc/xray/.env

# 启动 WireGuard（如果配置文件存在）
if [ -f "/etc/wireguard/wg0.conf" ]; then
    echo "$(date): 发现 WireGuard 配置文件..."
    echo "$(date): 启动 WireGuard..."
    wg-quick up wg0
    resolvconf -u
    wg-quick up wg0
    sleep 3
fi

# 启动 ehco relay
if echo "$RELAY_NODE_ID" | grep -qE '^[0-9]+$'; then
    echo "$(date): 启动 ehco relay..."
    ehco "-c $RELAY_NODE_ID" &
fi

# 启动 v2scar
v2scar --nodeid=$V2SCAR_NODEID &

# 启动 v2ray
while [ ! -e "/etc/xray/server_config.json" ]; do
  sleep 1
done
xray run -config /etc/xray/server_config.json &

# 每隔 60 秒检查是否还在运行
while true; do
    if [ -n "$RELAY_NODE_ID" ]; then
        if ! pgrep -x "ehco" > /dev/null; then
            echo "$(date): ehco relay 服务停止...正在重启"
            exit 1
        fi
    fi

    if ! pgrep -x "v2scar" > /dev/null; then
        echo "$(date): v2scar 服务停止...正在重启"
        exit 1
    fi
    
    if ! pgrep -x "xray" > /dev/null; then
        echo "$(date): xray 服务停止...正在重启"
        exit 1
    fi

    sleep 60
done
EOT

CMD ["sh", "/z.sh"]
