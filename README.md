# mjjcp
```
docker run -dit --name mjjcp --hostname mjjcp \
--restart=unless-stopped \
 -e TZ="$(cat /etc/timezone)" \
-p 端口:端口 -p 端口:端口/udp \
-e nodeId=主机ID \
-e port=端口 \
-e log= \
-e V2RAY_VMESS_AEAD_FORCED=false \
ghcr.io/loveqianool/mjjcp
```
