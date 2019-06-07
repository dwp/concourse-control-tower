[Unit]
Description=Concourse CI Web

[Service]
ExecStart=/usr/local/concourse/bin/concourse web \
       --peer-address %H \
       --tsa-bind-ip 0.0.0.0 \
       --external-url ${external_url} \
       --cluster-name ${cluster_name} \
       --add-local-user ${admin_user}:${admin_password} \
       --main-team-local-user ${admin_user} \
       --session-signing-key /etc/concourse/session_signing_key \
       --tsa-host-key /etc/concourse/host_key \
       --tsa-authorized-keys /etc/concourse/authorized_worker_keys \
       --postgres-database ${database_name} \
       --postgres-host ${database_host} \
       --postgres-user=${database_user} \
       --postgres-password=${database_password}

User=root
Group=root

Type=simple

LimitNOFILE=20000

[Install]
WantedBy=default.target
