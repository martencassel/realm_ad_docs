### Manual Installation Tutorial

This tutorial provides step-by-step instructions to manually install the `smart_proxy_realm_ad` plugin and `smart-proxy` on an Ubuntu 22.04 system. The `smart_proxy_realm_ad` plugin is used to integrate Active Directory realm management with the Foreman smart-proxy. By following this guide, you will install all necessary dependencies, clone the required repositories, build and install the plugin, and configure the smart-proxy.


#### Step 1: Install Dependencies

1. **Open a Terminal**:
   - On Linux or macOS, open the Terminal application.
   - On Windows, use a terminal emulator like Git Bash or WSL.

2. **Update Package Lists**:
   ```shell
   sudo apt-get update
   ```

3. **Install Common Dependencies**:
   ```shell
   sudo apt-get install -y curl git sudo wget jq net-tools
   ```

4. **Install Build Dependencies**:
   ```shell
   sudo apt-get install -y build-essential libssl-dev pkg-config
   ```

5. **Install Ruby and Related Dependencies**:
   ```shell
   sudo apt-get install -y ruby-dev ruby-libvirt
   ```

6. **Install Systemd Dependencies**:
   ```shell
   sudo apt-get install -y libsystemd-dev
   ```

7. **Install Kerberos Dependencies**:
   ```shell
   sudo apt-get install -y libkrb5-dev krb5-user
   ```

8. **Install LDAP Dependencies**:
   ```shell
   sudo apt-get install -y libldap-dev libsasl2-dev
   ```

#### Step 2: Clone Repositories

1. **Navigate to Home Directory**:
   ```shell
   cd ~
   ```

2. **Clone the smart-proxy Repository**:
   ```shell
   git clone https://github.com/theforeman/smart-proxy.git
   ```

3. **Clone the smart_proxy_realm_ad_plugin Repository**:
   ```shell
   git clone https://github.com/theforeman/smart_proxy_realm_ad_plugin.git
   ```

#### Step 3: Build and Install the smart_proxy_realm_ad_plugin

1. **Navigate to the Plugin Directory**:
   ```shell
   cd ~/smart_proxy_realm_ad_plugin
   ```

2. **Install Bundle Dependencies**:
   ```shell
   bundle install
   ```

3. **Build the Plugin**:
   ```shell
   gem build smart_proxy_realm_ad_plugin.gemspec
   ```

4. **Install the Plugin**:
   ```shell
   gem install smart_proxy_realm_ad_plugin-0.0.1.gem
   ```

#### Step 4: Configure smart-proxy

1. **Navigate to the smart-proxy Directory**:
   ```shell
   cd ~/smart-proxy
   ```

2. **Install Bundle Dependencies**:
   ```shell
   bundle install
   ```

3. **Add the Plugin to the Gemfile**:
   ```shell
   echo "gem 'smart_proxy_realm_ad_plugin', :path => '~/smart_proxy_realm_ad_plugin'" >> ./bundler.d/Gemfile.local.rb
   ```

4. **Create Configuration Directories**:
   ```shell
   sudo mkdir -p ~/smart-proxy/config/settings.d /etc/foreman-proxy
   ```

5. **Create realm.yml Configuration**:
   ```shell
   cat > ~/smart-proxy/config/settings.d/realm.yml <<EOF
   ---
   :enabled: true
   :use_provider: realm_ad
   EOF
   ```

6. **Create Keytab File**:
   ```shell
   sudo touch /etc/foreman-proxy/realm_ad.keytab
   ```

7. **Create realm_ad.yml Configuration**:
   ```shell
   cat > ~/smart-proxy/config/settings.d/realm_ad.yml <<EOF
   ---
   :realm: EXAMPLE.COM
   :principal: realm-proxy@EXAMPLE.COM
   :keytab_path: /etc/foreman-proxy/realm_ad.keytab
   :domain_controller: dc.example.com
   :computername_prefix: my_required_for_now_nice_prefix
   EOF
   ```

8. **Create settings.yml Configuration**:
   ```shell
   cat > ~/smart-proxy/config/settings.yml <<EOF
   :bind_host: ['*']
   :http_port: 8000
   :log_file: /tmp/proxy.log
   :log_level: DEBUG
   EOF
   ```

#### Step 5: Start smart-proxy

1. **Navigate to the smart-proxy Directory**:
   ```shell
   cd ~/smart-proxy
   ```

2. **Start smart-proxy**:
   ```shell
   bundle exec bin/smart-proxy &
   ```

3. **Check the Log File**:
   ```shell
   cat /tmp/proxy.log
   ```

#### Step 6: Verify Plugins

1. **Verify Plugins**:
   ```shell
   curl -s -H "Accept: application/json" http://localhost:8000/features | jq
   ```

#### Step 7: Manage Host

1. **Create a Host**:
   ```shell
   curl -s -d 'hostname=server1.example.com' http://localhost:8000/realm/EXAMPLE.COM | jq
   ```

2. **Rebuild the Host**:
   ```shell
   curl -d 'hostname=server1.example.com&rebuild=true' http://localhost:8000/realm/EXAMPLE.COM
   ```

3. **Delete the Host**:
   ```shell
   curl -XDELETE http://localhost:8000/realm/EXAMPLE.COM/server1
   ```

#### Step 8: Check Log Messages

1. **Check Log Messages**:
   ```shell
   cat /tmp/proxy.log
   ```

### Conclusion

By following these steps, you have manually installed and configured everything that the provided script does. This tutorial ensures that you understand each step and can troubleshoot any issues that arise during the installation process.