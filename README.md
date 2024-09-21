# realm_ad_docs

```bash

cat /etc/redhat-release
Red Hat Enterprise Linux release 9.4 (Plow)

# Register the system with Red Hat Subscription Manager
sudo subscription-manager register \
        --auto-attach \
        --username "$REDHAT_EMAIL" --password "$REDHAT_PASSWORD" --force

# Setup packages for foreman
sudo dnf update
sudo dnf clean all

sudo dnf install -y https://yum.theforeman.org/releases/nightly/el9/x86_64/foreman-release.rpm
sudo dnf install -y https://yum.puppet.com/puppet7-release-el-9.noarch.rpm

sudo dnf repolist enabled
sudo dnf upgrade

# Install foreman-installer
sudo dnf install -y foreman-installer

# Install required plugins
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
```
