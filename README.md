# realm_ad_docs

```bash

> cat /etc/redhat-release
Red Hat Enterprise Linux release 9.4 (Plow)

# Register the system with Red Hat Subscription Manager
> sudo subscription-manager register \
        --auto-attach \
        --username "$REDHAT_EMAIL" --password "$REDHAT_PASSWORD" --force

sudo dnf update
sudo dnf clean all
sudo dnf install -y https://yum.theforeman.org/releases/nightly/el9/x86_64/foreman-release.rpm
sudo dnf install -y https://yum.puppet.com/puppet7-release-el-9.noarch.rpm
sudo dnf repolist enabled
sudo dnf upgrade

sudo dnf install -y foreman-installer

sudo dnf -y install rubygem-radcli rubygem-smart_proxy_realm_ad_plugin

sudo foreman-installer \
 --no-enable-foreman \
 --no-enable-foreman-plugin-puppet \
 --no-enable-foreman-cli \
 --no-enable-foreman-cli-puppet \
 --no-enable-puppet \
 --foreman-proxy-puppet=false \
 --foreman-proxy-puppetca=false \
 --foreman-proxy-ssl=false \
 --foreman-proxy-http=true \
 --foreman-proxy-http-port=8000 \
 --foreman-proxy-register-in-foreman=false \
 --foreman-proxy-realm=true \
 --foreman-proxy-realm-provider=ad \
 --foreman-proxy-realm-listen-on=http \
 --foreman-proxy-log-level=DEBUG

sudo systemctl status foreman-proxy.service

● foreman-proxy.service - Foreman Proxy
     Loaded: loaded (/usr/lib/systemd/system/foreman-proxy.service; enabled; preset: disabled)
     Active: active (running) since Sat 2024-09-21 15:31:52 CEST; 2h 13min ago
   Main PID: 10674 (smart-proxy)
      Tasks: 3 (limit: 69883)
     Memory: 39.0M
        CPU: 662ms
     CGroup: /system.slice/foreman-proxy.service
             └─10674 /usr/bin/ruby /usr/share/foreman-proxy/bin/smart-proxy

Sep 21 15:31:51 rhel9.lab.local systemd[1]: Starting Foreman Proxy...
Sep 21 15:31:52 rhel9.lab.local systemd[1]: Started Foreman Proxy.

> curl -s -k http://rhel9.lab.local:8000/features|jq
[
  "logs",
  "realm"
]

```
