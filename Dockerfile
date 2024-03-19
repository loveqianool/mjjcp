FROM alpine
env api=https://api.cjy.me
env token=MJJ6688
env nodeId=
env port=
env grpc=8079
env V2RAY_VMESS_AEAD_FORCED=false

RUN apk add --no-cache wireguard-tools curl wget iproute2 ca-certificates nano openresolv gcompat ip6tables tzdata
COPY --from=v2fly/v2fly-core:v4.45.2 /usr/bin/v2ray /usr/local/bin/v2ray
RUN wget https://github.com/jackma778/sh/releases/download/v0.1/v2scar_alpine -O /usr/local/bin/v2scar \
 && chmod +x /usr/local/bin/v2scar \
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

# Start the first process
v2ray -config=$api/api/vmess_server_config/$port/?token=$token &
sleep 6
ps aux | grep v2ray | grep -q -v grep
PROCESS_1_STATUS=$?
echo "v2ray status..."
echo $PROCESS_1_STATUS
if [ $PROCESS_1_STATUS -ne 0 ]; then
echo "Failed to start my_first_process: $PROCESS_1_STATUS"
exit $PROCESS_1_STATUS
fi

# Start the second process
v2scar_alpine -id=$nodeId -gp=0.0.0.0:$grpc &
sleep 6
ps aux | grep v2scar_alpine | grep -q -v grep
PROCESS_2_STATUS=$?
echo "v2scar_alpine status..."
echo $PROCESS_2_STATUS
if [ $PROCESS_2_STATUS -ne 0 ]; then
echo "Failed to start my_second_process: $PROCESS_2_STATUS"
exit $PROCESS_2_STATUS
fi

# 每隔60秒检查进程是否运行
while sleep 60; do
ps aux | grep v2ray | grep -q -v grep
PROCESS_1_STATUS=$?
ps aux | grep v2scar_alpine | grep -q -v grep
PROCESS_2_STATUS=$?
# If the greps above find anything, they exit with 0 status
# If they are not both 0, then something is wrong
if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
echo "One of the processes has already exited."
exit 1
fi
done
EOT

CMD [ "sh", "/z.sh" ]
