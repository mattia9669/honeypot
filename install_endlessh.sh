#!/bin/bash
# installation of endlessh
#
# run script with cmd
# wget -q -O /tmp/install_endlessh.sh https://raw.githubusercontent.com/mattia9669/honeypot/refs/heads/main/install_endlessh.sh && sudo bash /tmp/install_endlessh.sh

apt install git
git clone https://github.com/skeeto/endlessh/
cd endlessh

make

cp endlessh /usr/local/bin/
cp util/endlessh.service /etc/systemd/system/

mkdir /etc/endlessh

cat <<EOF > /etc/endlessh/config
Port 22
Delay 10000
MaxLineLength 32
MaxClients 4096
LogLevel 0
BindFamily 0
EOF

cat <<EOF > /etc/systemd/system/endlessh.service
[Unit]
Description=Endlessh SSH Tarpit
Documentation=man:endlessh(1)
Requires=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=30sec
ExecStart=/usr/local/bin/endlessh
KillSignal=SIGTERM

# Stop trying to restart the service if it restarts too many times in a row
StartLimitInterval=5min
StartLimitBurst=4

StandardOutput=journal
StandardError=journal
StandardInput=null

PrivateTmp=true
PrivateDevices=true
ProtectSystem=full
ProtectHome=true
#InaccessiblePaths=/run /var

## If you want Endlessh to bind on ports < 1024
## 1) run:
##     setcap 'cap_net_bind_service=+ep' /usr/local/bin/endlessh
## 2) uncomment following line
AmbientCapabilities=CAP_NET_BIND_SERVICE
## 3) comment following line
#PrivateUsers=true

NoNewPrivileges=true
ConfigurationDirectory=endlessh
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
MemoryDenyWriteExecute=true

[Install]
WantedBy=multi-user.target
EOF

setcap 'cap_net_bind_service=+ep' /usr/local/bin/endlessh

systemctl daemon-reload
systemctl enable --now endlessh.service
systemctl start endlessh.service
systemctl status endlessh.service

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i 's/^#\?Port [0-9]\+/Port 22554/' /etc/ssh/sshd_config

#rm /tmp/install_endlessh.sh
