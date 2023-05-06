FROM debian:stable-slim
env api=https://api.cjy.me
env token=MJJ6688
env nodeId=
env port=
COPY --from=ochinchina/supervisord /usr/local/bin/supervisord /usr/local/bin/supervisord
COPY --from=v2fly/v2fly-core:v4.45.2 /usr/bin/v2ray /usr/local/bin/v2ray
RUN --mount=from=busybox:latest,src=/bin/,dst=/bin/ \
 wget https://github.com/jackma778/sh/raw/main/v2scar -O /usr/local/bin/v2scar
RUN chmod +x /usr/local/bin/v2scar
RUN apt update && apt install ca-certificates -y && apt-get clean && rm -rf /var/cache/apt/archives /var/lib/apt/lists
RUN echo '[program:log] \n\
command = sh -c "if [ $log = 'yes' ]; then sed 's/#std/std/g' -i /etc/supervisord.conf; fi" \n\
startsecs = 0 \n\
autorestart = false \n\
startretries = 1 \n\
[program:v2ray] \n\
command = v2ray -config=%(ENV_api)s/api/vmess_server_config/%(ENV_port)s/?token=%(ENV_token)s \n\
#stdout_logfile=/dev/stdout \n\
#stderr_logfile=/dev/stderr \n\
[program:v2scar] \n\
depends_on = v2ray \n\
command = v2scar -id=%(ENV_nodeId)s -gp=127.0.0.1:8079' \n\
#stdout_logfile=/dev/stdout \n\
#stderr_logfile=/dev/stderr \
> /etc/supervisord.conf
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
