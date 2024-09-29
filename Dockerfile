FROM alpine
env API_SITE=https://api.cjy.me
env TOKEN=MJJ6688
env NODE_ID=
env PORT=
env GRPC_PORT=8079
env V2RAY_VMESS_AEAD_FORCED=false

RUN apk add --no-cache wireguard-tools curl wget iproute2 ca-certificates nano openresolv gcompat ip6tables tzdata
COPY --from=v2fly/v2fly-core:v4.45.2 /usr/bin/v2ray /usr/local/bin/v2ray
RUN wget https://github.com/jackma778/sh/raw/refs/heads/main/v2scar_alpine -O /usr/local/bin/v2scar_alpine \
 && chmod +x /usr/local/bin/v2scar_alpine \
 && wget https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat \
 -O /usr/local/bin/geosite.dat \
 && wget https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat \
 -O /usr/local/bin/geoip.dat
 
RUN sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick \
 && curl https://developers.cloudflare.com/cloudflare-one/static/documentation/connections/Cloudflare_CA.pem \
 -o /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && chmod 644 /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && update-ca-certificates

RUN cat > /z.sh <<'EOT'
#!/bin/bash
if [ -f "/etc/wireguard/wg0.conf" ]; then wg-quick up wg0 && sleep 6; fi

v2ray "-config=$API_SITE/api/get_server_config?id=$NODE_ID&token=$TOKEN" &
sleep 6
ps aux | grep v2ray | grep -q -v grep
v2ray_STATUS=$?
echo "v2ray status..."
echo $v2ray_STATUS
if [ $v2ray_STATUS -ne 0 ]; then
echo "v2ray 启动失败: $v2ray_STATUS"
exit $v2ray_STATUS
fi

v2scar_alpine -id=$NODE_ID -gp=localhost:$GRPC_PORT &
sleep 6
ps aux | grep v2scar_alpine | grep -q -v grep
v2scar_STATUS=$?
echo "v2scar status..."
echo $v2scar_STATUS
if [ $v2scar_STATUS -ne 0 ]; then
echo "v2scar 启动失败: $v2scar_STATUS"
exit $v2scar_STATUS
fi

while sleep 60; do
ps aux | grep v2ray | grep -q -v grep
v2ray_STATUS=$?
ps aux | grep v2scar_alpine | grep -q -v grep
v2scar_STATUS=$?
if [ $v2ray_STATUS -ne 0 -o $v2scar_STATUS -ne 0 ]; then
echo "启动失败."
exit 1
fi
done
EOT

CMD [ "sh", "/z.sh" ]
