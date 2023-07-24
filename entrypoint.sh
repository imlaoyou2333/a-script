#!/usr/bin/env bash
generate_rclone(){
  cat > rclone.sh << EOF
RCLONE_CONFIG=${RCLONE_CONFIG}
RCLONE_DRIVE=${RCLONE_DRIVE}
RCLONE_BASE_URL=${RCLONE_BASE_URL}
RCLONE_DAV_USER=${RCLONE_DAV_USER}
RCLONE_DAV_PASS=${RCLONE_DAV_PASS}
RCLONE_CONFIG_PASS=${RCLONE_CONFIG_PASS}
rm -rf rclone*/ rclone.zip rclone
curl -L https://beta.rclone.org/rclone-beta-latest-linux-amd64.zip -o rclone.zip
unzip rclone.zip
cp */rclone ./
chmod +x ./rclone
rm rclone.zip
echo "RCLONE_ENCRYPT_V0:" >rclone.conf
echo "${RCLONE_CONFIG}" >>rclone.conf
RCLONE_CONFIG_PASS=${RCLONE_CONFIG_PASS} ./rclone serve webdav ${RCLONE_DRIVE} --config=rclone.conf --addr 127.0.0.1:8036 --baseurl "${RCLONE_BASE_URL}" --user "${RCLONE_DAV_USER}" --pass "${RCLONE_DAV_PASS}" --vfs-cache-mode full --vfs-cache-max-size 100M --vfs-read-chunk-size 50M --vfs-read-wait 10s --vfs-write-wait 10s --transfers 100
EOF
}

generate_alist() {
  cat > alist.sh << EOF
DB_TYPE=${ALIST_DB_TYPE}
DB_HOST=${ALIST_DB_HOST}
DB_PORT=${ALIST_DB_PORT}
DB_USER=${ALIST_DB_USER}
DB_PASS=${ALIST_DB_PASS}
DB_NAME=${ALIST_DB_NAME}
DB_TABLE_PREFIX=${ALIST_DB_TABLE_PREFIX}
DB_SSL_MODE=${ALIST_DB_SSL_MODE}

rm -rf alist #Uncomment this line to update
if [ ! -f "alist" ];then
  curl -L https://github.com/alist-org/alist/releases/latest/download/alist-linux-musl-amd64.tar.gz -o alist.tar.gz
  tar -zxvf alist.tar.gz
  rm -f alist.tar.gz
fi
./alist server
wait
EOF
}

generate_nezha() {
  cat > nezha.sh << EOF
#!/usr/bin/env bash

# 哪吒的三个参数
NEZHA_SERVER=${NEZHA_SERVER}
NEZHA_PORT=${NEZHA_PORT}
NEZHA_KEY=${NEZHA_KEY}

# 检测是否已运行
check_run() {
    [[ \$(pidof nezha-agent) ]] && echo "哪吒客户端正在运行中" && exit
}

# 三个变量不全则不安装哪吒客户端
check_variable() {
    [[ -z "\${NEZHA_SERVER}" || -z "\${NEZHA_PORT}" || -z "\${NEZHA_KEY}" ]] && exit
}

# 下载最新版本 Nezha Agent
download_agent() {
    if [ ! -e nezha-agent ]; then
        URL=\$(wget -qO- -4 "https://api.github.com/repos/naiba/nezha/releases/latest" | grep -o "https.*linux_amd64.zip")
        wget -t 2 -T 10 -N \${URL}
        unzip -qod ./ nezha-agent_linux_amd64.zip && rm -f nezha-agent_linux_amd64.zip
    fi
}

# 运行客户端
run() {
    [ -e nezha-agent ] && chmod +x nezha-agent && ./nezha-agent -s \${NEZHA_SERVER}:\${NEZHA_PORT} -p \${NEZHA_KEY}
}

check_run
check_variable
download_agent
run
wait
EOF
}
generate_alist
generate_config
generate_nezha
generate_rclone
[ -e nezha.sh ] && bash nezha.sh 2>&1 &
[ -e alist.sh ] && bash alist.sh 2>&1 &
wait
