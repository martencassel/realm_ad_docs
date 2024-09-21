# realm_ad_docs

```bash

> cat /etc/redhat-release
Red Hat Enterprise Linux release 9.4 (Plow)

# Register the system with Red Hat Subscription Manager
> sudo subscription-manager register \
        --auto-attach \
        --username "$REDHAT_EMAIL" --password "$REDHAT_PASSWORD" --force

# Install packages
sudo dnf update
sudo dnf clean all
sudo dnf install -y https://yum.theforeman.org/releases/nightly/el9/x86_64/foreman-release.rpm
sudo dnf install -y https://yum.puppet.com/puppet7-release-el-9.noarch.rpm
sudo dnf repolist enabled
sudo dnf upgrade
sudo dnf install -y foreman-installer
sudo dnf -y install rubygem-radcli rubygem-smart_proxy_realm_ad_plugin

# Configure hostname
> sudo cat /etc/hosts
127.0.0.1   rhel9.lab.local localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

> hostnamectl
 Static hostname: rhel9.lab.local
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: 84e7e1e87985423e8d863c35f0d301fa
         Boot ID: f28fd47d6b7e4c7ab2aa3c617790141b
  Virtualization: vmware
Operating System: Red Hat Enterprise Linux 9.4 (Plow)
     CPE OS Name: cpe:/o:redhat:enterprise_linux:9::baseos
          Kernel: Linux 5.14.0-427.35.1.el9_4.x86_64
    Architecture: x86-64
 Hardware Vendor: VMware, Inc.
  Hardware Model: VMware Virtual Platform
Firmware Version: 6.00

#
# Install foreman proxy
#

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

# Check that foreman-proxy is running
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

> sudo cat /etc/foreman-proxy/settings.d/realm.yml
---
# Can be true, false, or http/https to enable just one of the protocols
:enabled: http

# Available providers:
#   realm_freeipa
:use_provider: realm_ad

sudo cat /var/log/foreman-proxy/proxy.log
2024-09-21T15:31:52  [D] 'realm' settings: 'enabled': http, 'use_provider': realm_ad
2024-09-21T15:31:52  [D] 'realm' ports: 'http': true, 'https': false
2024-09-21T15:31:52  [D] 'logs' settings: 'enabled': https
2024-09-21T15:31:52  [D] 'logs' ports: 'http': false, 'https': true
2024-09-21T15:31:52  [D] Providers ['realm_ad'] are going to be configured for 'realm'
2024-09-21T15:31:52  [D] 'realm_ad' settings: 'domain_controller': dc.example.com, 'keytab_path': /etc/foreman-proxy/realm_ad.keytab, 'principal': realm-proxy@EXAMPLE.COM, 'realm': EXAMPLE.COM, 'use_provider': realm_ad
2024-09-21T15:31:52  [I] Successfully initialized 'foreman_proxy'
2024-09-21T15:31:52  [I] Successfully initialized 'realm_ad'
2024-09-21T15:31:52  [I] Successfully initialized 'realm'
2024-09-21T15:31:52  [D] Log buffer API initialized, available capacity: 2000/1000
2024-09-21T15:31:52  [I] Successfully initialized 'logs'
2024-09-21T15:31:52  [W] Missing SSL setup, https is disabled.
2024-09-21T15:31:52  [I] Smart proxy has launched on 1 socket(s), waiting for requests

# Default realm_ad settings

sudo cat /etc/foreman-proxy/settings.d/realm_ad.yml
---
# Authentication for Kerberos-based Realms
:realm: EXAMPLE.COM

# Kerberos pricipal used to authenticate against Active Directory
:principal: realm-proxy@EXAMPLE.COM

# Path to the keytab used to authenticate against Active Directory
:keytab_path:  /etc/foreman-proxy/realm_ad.keytab

# FQDN of the Domain Controller
:domain_controller: dc.example.com

# Optional: OU where the machine account shall be placed
#:ou: OU=Linux,OU=Servers,DC=example,DC=com

# Optional: Prefix for the computername
#:computername_prefix: ''

# Optional: Generate the computername by calculating the SHA256 hexdigest of the hostname
#:computername_hash: false

# Optional:  use the fqdn of the host to generate the computername
#:computername_use_fqdn: false

sudo adcli info -D lab.local
[domain]
domain-name = lab.local
domain-short = LAB
domain-forest = lab.local
domain-controller = ad01.lab.local
domain-controller-site = Default-First-Site-Name
domain-controller-flags = pdc gc ldap ds kdc timeserv closest writable good-timeserv full-secret ads-web
domain-controller-usable = yes
domain-controllers = ad01.lab.local
[computer]
computer-site = Default-First-Site-Name

# Join the domain
sudo adcli join
Password for Administrator@LAB.LOCAL:

# Default keytab
sudo find / -name *.keytab
/etc/krb5.keytab

```
