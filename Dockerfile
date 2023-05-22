FROM debian:stable-slim
env api=https://api.cjy.me
env token=MJJ6688
env nodeId=
env port=
env grpc=8079
env log=

RUN apt update && apt install wireguard-tools curl wget iproute2 ca-certificates nano openresolv -y && apt-get clean && rm -rf /var/cache/apt/archives /var/lib/apt/lists
COPY --from=v2fly/v2fly-core:v4.45.2 /usr/bin/v2ray /usr/local/bin/v2ray
RUN wget https://github.com/jackma778/sh/raw/main/v2scar -O /usr/local/bin/v2scar && chmod +x /usr/local/bin/v2scar

RUN sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick \
 && curl https://developers.cloudflare.com/cloudflare-one/static/documentation/connections/Cloudflare_CA.pem \
 -o /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && chmod 644 /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && update-ca-certificates

RUN echo '#/bin/sh \n\
if [ -f "/etc/wireguard/wg0.conf" ]; then wg-quick up wg0 && sleep 3; fi \n\
v2ray -config=$api/api/vmess_server_config/$port/?token=$token & \n\
v2scar -id=$nodeId -gp=127.0.0.1:$grpc & \n\
wait -n \n\
exit $? \
> /z.sh
CMD [ "sh", "/z.sh" ]
