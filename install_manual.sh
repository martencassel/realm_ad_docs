#!/bin/bash
set -x
 
 

# Define variables for different groups of dependencies
COMMON_DEPENDENCIES="curl git sudo wget jq net-tools"
BUILD_DEPENDENCIES="build-essential libssl-dev pkg-config"
RUBY_DEPENDENCIES="ruby-dev ruby-libvirt"
SYSTEMD_DEPENDENCIES="libsystemd-dev"
KERBEROS_DEPENDENCIES="libkrb5-dev krb5-user"
LDAP_DEPENDENCIES="libldap-dev libsasl2-dev"

# Function to install dependencies
install_dependencies() {
  log_info "Installing dependencies with apt-get..."
  apt-get update && apt-get install -y \
    $COMMON_DEPENDENCIES \
    $BUILD_DEPENDENCIES \
    $RUBY_DEPENDENCIES \
    $SYSTEMD_DEPENDENCIES \
    $KERBEROS_DEPENDENCIES \
    $LDAP_DEPENDENCIES
}
 
# Function to clone repositories
clone_repositories() {
  log_info "Cloning smart-proxy and smart_proxy_realm_ad_plugin repositories..."
  cd ~
  git clone https://github.com/theforeman/smart-proxy.git
  git clone https://github.com/theforeman/smart_proxy_realm_ad_plugin.git
}

# Function to build and install the smart_proxy_realm_ad_plugin
install_smart_proxy_realm_ad_plugin() {
  log_info "Building and installing smart_proxy_realm_ad_plugin..."
  cd ~/smart_proxy_realm_ad_plugin
  bundle install > >(tee -a $log_file) 2>&1
  gem build smart_proxy_realm_ad_plugin.gemspec > >(tee -a $log_file) 2>&1
  gem install smart_proxy_realm_ad_plugin*.gem > >(tee -a $log_file) 2>&1
  echo "Ending install_smart_proxy_realm_ad_plugin"
}


# Function to configure smart-proxy
configure_smart_proxy() {
  local realm=$1
  local principal=$2
  local keytab_filename=$3
  local domain_controller=$4
  local computername_prefix=$5

  log_info "Configuring smart-proxy..."

  SMART_PROXY_DIR=~/smart-proxy
  PLUGIN_DIR=~/smart_proxy_realm_ad_plugin
  CONFIG_DIR=$SMART_PROXY_DIR/config/settings.d
  FOREMAN_PROXY_DIR=/etc/foreman-proxy
  LOG_FILE=/tmp/proxy.log

  # Ensure directories exist
  mkdir -p $CONFIG_DIR $FOREMAN_PROXY_DIR  > >(tee -a $log_file) 2>&1

  # Navigate to smart-proxy directory
  cd $SMART_PROXY_DIR || { log_info "Failed to change directory to $SMART_PROXY_DIR"; exit 1; }

  # Install bundle dependencies
  bundle install || { log_info "Bundle install failed"; exit 1; }  > >(tee -a $log_file) 2>&1

  # Add the plugin to the Gemfile
  echo "gem 'smart_proxy_realm_ad_plugin', :path => '$PLUGIN_DIR'" >> ./bundler.d/Gemfile.local.rb

  # Create realm.yml configuration
  cat > $CONFIG_DIR/realm.yml <<EOF
---
:enabled: true
:use_provider: realm_ad
EOF

  # Create keytab file
  touch $FOREMAN_PROXY_DIR/$keytab_filename

  # Create realm_ad.yml configuration
  cat > $CONFIG_DIR/realm_ad.yml <<EOF
---
:realm: $realm
:principal: $principal
:keytab_path: $FOREMAN_PROXY_DIR/$keytab_filename
:domain_controller: $domain_controller
:computername_prefix: $computername_prefix
EOF

  # Create settings.yml configuration
  cat > $SMART_PROXY_DIR/config/settings.yml <<EOF
:bind_host: ['*']
:http_port: 8000
:log_file: $LOG_FILE
:log_level: DEBUG
EOF

  log_info "Configuration complete."
}

# Function to start smart-proxy
start_smart_proxy() {
  log_info "Starting smart-proxy using bundle exec..."
  cd ~/smart-proxy
  rm -f /tmp/proxy.log | touch /tmp/proxy.log
  bundle exec bin/smart-proxy &  > >(tee -a $log_file) 2>&1
  cat /tmp/proxy.log
}

# Function to verify plugins
verify_plugins() {
  log_info "Verifying plugins..."
  curl -s -H "Accept: application/json" http://localhost:8000/features | jq
}

# Function to create, rebuild, and delete host
manage_host() {
  log_info "Creating, rebuilding, and deleting host..."
  curl -s -d 'hostname=server1.example.com' http://localhost:8000/realm/EXAMPLE.COM | jq
  curl -d 'hostname=server1.example.com&rebuild=true' http://localhost:8000/realm/EXAMPLE.COM
  curl -XDELETE http://localhost:8000/realm/EXAMPLE.COM/server1
}

# Function to check log messages
check_log_messages() {
  cat /tmp/proxy.log
}


log_info "Installation and configuration script started..."

# Main script execution
install_dependencies
# Check that ruby is installed
if ! command -v ruby &> /dev/null
then
  log_info "Ruby is not installed. Installing Ruby..."
  apt-get install -y ruby-full  > >(tee -a $log_file) 2>&1
fi
clone_repositories
install_smart_proxy_realm_ad_plugin
configure_smart_proxy "EXAMPLE.COM" "realm-proxy@EXAMPLE.COM" "realm_ad.keytab" "dc.example.com" "my_required_for_now_nice_prefix"
start_smart_proxy
verify_plugins
manage_host
check_log_messages
 