[Unit]
Description=Concourse CI Worker

[Service]
ExecStart=/usr/local/concourse/bin/concourse worker \
    --work-dir /opt/concourse \
    --ephemeral \
    --tsa-host ${tsa_host} \
    --tsa-public-key /etc/concourse/tsa_host_key.pub \
    --tsa-worker-private-key /etc/concourse/worker_key \
    ${tags}

User=root
Group=root
Type=simple
LimitNPROC=infinity
LimitNOFILE=infinity
TasksMax=infinity
MemoryLimit=infinity
Delegate=yes
KillMode=none

[Install]
WantedBy=default.target
