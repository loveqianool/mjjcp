# mjjcp

将识别ID和端口放进去直接运行。
```
docker run -dit --name mjjcp --hostname mjjcp \
--restart=unless-stopped \
-e TZ="$(cat /etc/timezone)" \
-e NODE_ID=主机识别ID \
-e PORT=端口 \
-p 端口:端口 -p 端口:端口/udp \
ghcr.io/loveqianool/mjjcp:slim
```

查看运行日志
```
docker logs mjjcp
```

结束运行
```
docker rm -fv mjjcp
```

要启用 warp 出口，将下面的 /opt/docker/wireguard/wg0.conf，改成你的 wireguard 配置文件。
```
docker run -dit --name mjjcp --hostname mjjcp \
--restart=unless-stopped \
 -e TZ="$(cat /etc/timezone)" \
 --sysctl="net.ipv6.conf.default.forwarding=1" \
--sysctl="net.ipv6.conf.all.disable_ipv6=0" \
--sysctl="net.ipv6.conf.all.forwarding=1" \
--sysctl="net.ipv6.conf.all.proxy_ndp=1" \
--sysctl="net.ipv4.conf.all.src_valid_mark=1" \
--sysctl="net.ipv4.conf.all.proxy_arp=1" \
--sysctl="net.ipv4.ip_forward=1" \
--sysctl="net.ipv4.tcp_fastopen=3" \
--sysctl="net.ipv4.tcp_congestion_control=htcp" \
--sysctl="net.ipv4.tcp_congestion_control=bbr" \
--sysctl="net.ipv4.ip_local_port_range=1024 65000" \
--sysctl="net.ipv4.tcp_fin_timeout=30" \
--sysctl="net.ipv4.tcp_keepalive_time=7200" \
--sysctl="net.ipv4.tcp_max_syn_backlog=65535" \
--sysctl="net.ipv4.tcp_max_tw_buckets=6000" \
--sysctl="net.ipv4.tcp_mtu_probing=1" \
--sysctl="net.ipv4.tcp_sack=1" \
--sysctl="net.ipv4.tcp_syn_retries=3" \
--sysctl="net.ipv4.tcp_synack_retries=3" \
--sysctl="net.ipv4.tcp_syncookies=1" \
--sysctl="net.ipv4.tcp_timestamps=0" \
--sysctl="net.ipv4.tcp_tw_reuse=1" \
--sysctl="net.ipv4.tcp_window_scaling=1" \
--sysctl="net.ipv4.tcp_wmem=8192 262144 67108864" \
--cap-add=NET_ADMIN \
--cap-add=SYS_MODULE \
-v /lib/modules:/lib/modules:ro \
-v /opt/docker/wireguard/wg0.conf:/etc/wireguard/wg0.conf \
-p 端口:端口 -p 端口:端口/udp \
-e NODE_ID=主机ID \
-e PORT=端口 \
ghcr.io/loveqianool/mjjcp
```
