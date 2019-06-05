[Unit]
Description=Concourse CI Web

[Service]
ExecStart=/usr/local/concourse/bin/concourse web \
       --peer-address=%H \
       --external-url ${external-url} \
       --add-local-user ${admin-user}:${admin-password} \
       --main-team-local-user ${admin-user} \
       --session-signing-key /etc/concourse/session_signing_key \
       --tsa-host-key /etc/concourse/host_key \
       --tsa-authorized-keys /etc/concourse/authorized_worker_keys \
       --postgres-user=${database-user} \
       --postgres-password=${database-password}

User=root
Group=root

Type=simple

LimitNOFILE=20000

[Install]
WantedBy=default.target
