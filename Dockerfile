FROM debian:stable-slim
env api=https://api.cjy.me
env token=MJJ6688
env nodeId=
env port=
env grpc=8079
env log=

RUN apt update && apt install wireguard-tools curl wget iproute2 ca-certificates nano openresolv -y && apt-get clean && rm -rf /var/cache/apt/archives /var/lib/apt/lists
COPY --from=ochinchina/supervisord /usr/local/bin/supervisord /usr/local/bin/supervisord
COPY --from=v2fly/v2fly-core:v4.45.2 /usr/bin/v2ray /usr/local/bin/v2ray
RUN wget https://github.com/jackma778/sh/raw/main/v2scar -O /usr/local/bin/v2scar && chmod +x /usr/local/bin/v2scar

RUN sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick \
 && curl https://developers.cloudflare.com/cloudflare-one/static/documentation/connections/Cloudflare_CA.pem \
 -o /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && chmod 644 /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && update-ca-certificates

RUN echo '[program:v2ray] \n\
environment=V2RAY_VMESS_AEAD_FORCED="false" \n\
command = v2ray -config=%(ENV_api)s/api/vmess_server_config/%(ENV_port)s/?token=%(ENV_token)s \n\
'#'stdout_logfile=/dev/stdout \n\
'#'stderr_logfile=/dev/stderr \n\
[program:v2scar] \n\
depends_on = v2ray \n\
command = v2scar -id=%(ENV_nodeId)s -gp=127.0.0.1:%(ENV_grpc)s \n\
'#'stdout_logfile=/dev/stdout \n\
'#'stderr_logfile=/dev/stderr' \
> /etc/supervisord.conf

RUN echo 'if [ ! -z "$log" ]; then sed "s/#std/std/g" -i /etc/supervisord.conf; fi \n\
supervisord -c /etc/supervisord.conf' \
> /z.sh
CMD [ "sh", "/z.sh" ]
