FROM alpine:edge
env API_SITE=https://api.cjy.me
env TOKEN=MJJ6688
env NODE_ID=
env PORT=
env GRPC_PORT=8079
env V2RAY_VMESS_AEAD_FORCED=false

COPY --from=v2fly/v2fly-core:v4.45.2 /usr/bin/v2ray /usr/local/bin/v2ray

RUN apk add --no-cache wireguard-tools curl iproute2 ca-certificates openresolv gcompat ip6tables tzdata && \
 sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick && \
 curl https://developers.cloudflare.com/cloudflare-one/static/documentation/connections/Cloudflare_CA.pem -o /usr/local/share/ca-certificates/Cloudflare_CA.pem && \
 chmod 644 /usr/local/share/ca-certificates/Cloudflare_CA.pem && \
 update-ca-certificates

RUN curl https://raw.githubusercontent.com/jackma778/sh/main/v2scar_alpine \
 -o /usr/local/bin/v2scar_alpine && chmod +x /usr/local/bin/v2scar_alpine && \
curl https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat \
 -o /usr/local/bin/geosite.dat && \
curl https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat \
 -o /usr/local/bin/geoip.dat

RUN cat > /z.sh <<'EOT'
#!/bin/sh

# 启动 WireGuard（如果配置文件存在）
if [ -f "/etc/wireguard/wg0.conf" ]; then
    echo "$(date): 发现 WireGuard 配置文件..."
    echo "$(date): 启动 WireGuard..."
    wg-quick up wg0
    sleep 3
fi

# 启动 v2ray
v2ray "-config=$API_SITE/api/get_server_config?id=$NODE_ID&token=$TOKEN" &
echo "$(date): v2ray 启动中..."
sleep 3

# 检查 v2ray 是否启动成功
if ! pgrep -x "v2ray" > /dev/null; then
    echo "$(date): v2ray 启动失败..."
    exit 1
fi
echo "$(date): v2ray 启动成功..."

# 启动 v2scar_alpine
v2scar_alpine -id=$NODE_ID -gp=localhost:$GRPC_PORT &
echo "$(date): v2scar 启动中..."
sleep 3

# 检查 v2scar_alpine 是否启动成功
if ! pgrep -x "v2scar_alpine" > /dev/null; then
    echo "$(date): v2scar 启动失败..."
    exit 1
fi
echo "$(date): v2scar 启动成功..."

echo "$(date): 正常运行中..."

# 每隔 60 秒检查一次 v2ray 和 v2scar_alpine 是否还在运行
while sleep 60; do
    if ! pgrep -x "v2ray" > /dev/null; then
        echo "$(date): v2ray 服务停止...正在重启"
        exit 1
    fi
    
    if ! pgrep -x "v2scar_alpine" > /dev/null; then
        echo "$(date): v2scar_alpine 服务停止...正在重启"
        exit 1
    fi
done

EOT

CMD [ "sh", "/z.sh" ]
