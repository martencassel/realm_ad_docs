#!/bin/bash
set -x

export FOREMAN_PROXY_VERSION="3.12.0-rc1"

# Define variables for different groups of dependencies
export DEBIAN_FRONTEND=noninteractive

COMMON_TOOLS="curl git sudo wget jq net-tools"
BUILD_DEV="build-essential libssl-dev pkg-config libvirt-dev libyaml-dev"
RUBY_DEPENDENCIES="ruby-dev ruby-libvirt bundler"
SYSTEMD_DEPENDENCIES="libsystemd-dev"
KERBEROS_DEPENDENCIES="libkrb5-dev krb5-user"
LDAP_DEPENDENCIES="libldap-dev libsasl2-dev"

FOREMAN_DEPENDENCIES="libvirt-dev libyaml-dev"



log_file="/tmp/install_from_source.log"

# Create the log file if it doesn't exist
touch $log_file

# Redirect stdout and stderr to the log file
exec > >(tee -a $log_file) 2>&1


log_info() {
    echo -e "$(date) - $1" | tee -a $log_file
}

log_error() {
    echo -e "$(date) - ERROR: $1" | tee -a $log_file   
}


update_system() {
  log_info "Updating system..."
  apt-get update > >(tee -a $log_file) 2>&1
  apt-get upgrade -y > >(tee -a $log_file) 2>&1
}


instapp_packages() {
  PKG_LIST=$1
  # Check if empty
  if [ -z "$PKG_LIST" ]; then
    log_info "No packages to install."
    return
  fi
  log_info "Installing dependencies with apt-get..."
  apt-get install -y $PKG_LIST  > >(tee -a $log_file) 2>&1
}
 
# Function to clone repositories
clone_repositories() {
  log_info "Cloning smart-proxy and smart_proxy_realm_ad_plugin repositories..."
  cd ~
  if [ -d "smart-proxy" ]; then
    rm -rf smart-proxy
  fi
  git clone https://github.com/theforeman/smart-proxy.git
 
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
  PLUGIN_DIR=~/smart_proxy_realm_ad_plugin
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

# Function to check if the server is responding
check_server_response() {
  local url=$1
  local timeout=10  # 15 minutes in seconds
  local interval=5   # Check every 5 seconds
  local elapsed=0

  log_info "Checking if the server at $url is responding..."

  while [ $elapsed -lt $timeout ]; do
    if curl -s --head --request GET $url | grep "200 OK" > /dev/null; then
      log_info "Server is responding."
      return 0
    fi
    sleep $interval
    elapsed=$((elapsed + interval))
  done

  log_error "Server did not respond within 15 minutes."
  return 1
}

export DEBIAN_FRONTEND=noninteractive
 
function install_realmad {
  log_info "Building and installing smart_proxy_realm_ad_plugin..."
  cd ~
  if [ -d "smart_proxy_realm_ad_plugin" ]; then
    rm -rf smart_proxy_realm_ad_plugin
  fi
  git clone https://github.com/theforeman/smart_proxy_realm_ad_plugin.git
  cd ~/smart_proxy_realm_ad_plugin
  apt-get -y install bundler 
  # radcli dependencies
  apt-get -y install libkrb5-dev libldap-dev libsasl2-dev
  bundle install > >(tee -a $log_file) 2>&1
  gem build smart_proxy_realm_ad_plugin.gemspec > >(tee -a $log_file) 2>&1
  gem install smart_proxy_realm_ad_plugin*.gem > >(tee -a $log_file) 2>&1
  echo "Ending install_smart_proxy_realm_ad_plugin"
}

function install_smartproxy {
  log_info "Building and installing smart-proxy..."
  cd ~
  if [ -d "smart-proxy" ]; then
    rm -rf smart-proxy
  fi
  git clone https://github.com/theforeman/smart-proxy.git
  cd ~/smart-proxy
  apt-get -y install libsystemd-dev libyaml-dev libkrb5-dev libvirt-dev
  bundle install 
  
  # Add the plugin to the Gemfile (smart-proxy-realm-ad-plugin)
  PLUGIN_DIR=~/smart_proxy_realm_ad_plugin
  echo "gem 'smart_proxy_realm_ad_plugin', :path => '$PLUGIN_DIR'" >> ./bundler.d/Gemfile.local.rb

  # Configuration dir
  CONFIG_DIR=~/smart-proxy/config/settings.d

  # Enable the plugin
cat>~/smart-proxy/config/settings.d/realm.yml<<EOF
---
:enabled: true
:use_provider: realm_ad
EOF  

# Add realm_ad.yml configuration

touch ~/smart-proxy/realm_ad.keytab

# Create realm_ad.yml configuration
cat > $CONFIG_DIR/realm_ad.yml<<EOF
---
:realm: realm_ad.keytab
:principal: EXAMPLE.COM
:keytab_path: realm_ad.keytab
:domain_controller: dc.example.com
:computername_prefix: "my_prefix"
EOF

cat ~/smart-proxy/config/settings.d/realm.yml
cat ~/smart-proxy/config/settings.d/realm_ad.yml

}

function main {
  log_info "Installation and configuration script started..."
  update_system
  apt-get -y install git
  install_realmad
  install_smartproxy
}





# # Install dependencies
# instapp_packages "$COMMON_TOOLS $BUILD_DEV $RUBY_DEPENDENCIES $SYSTEMD_DEPENDENCIES $KERBEROS_DEPENDENCIES $LDAP_DEPENDENCIES $FOREMAN_DEPENDENCIES"

# # # Check that ruby is installed
# if ! command -v ruby &> /dev/null
# then
#   log_info "Ruby is not installed. Installing Ruby..."
#   apt-get install -y ruby-full  > >(tee -a $log_file) 2>&1
# fi
# clone_repositories
# install_smart_proxy_realm_ad_plugin
# configure_smart_proxy "EXAMPLE.COM" "realm-proxy@EXAMPLE.COM" "realm_ad.keytab" "dc.example.com" "my_required_for_now_nice_prefix"
# start_smart_proxy

# check_server_response "http://localhost:8000/features"

# verify_plugins
# manage_host
# check_log_messages

# log_info "Installation and configuration complete."

#   cd ~/smart-proxy
#   apt-get -y install libsystemd-dev libyaml-dev libkrb5-dev libvirt-dev
#   bundle install
#   PLUGIN_DIR=~/smart_proxy_realm_ad_plugin
#   echo "gem 'smart_proxy_realm_ad_plugin', :path => '$PLUGIN_DIR'" >> ./bundler.d/Gemfile.local.rb

#   KEYTAB_FILENAME="realm_ad.keytab"
#   SMART_PROXY_DIR=~/smart-proxy
#   PLUGIN_DIR=~/smart_proxy_realm_ad_plugin
#   CONFIG_DIR=$SMART_PROXY_DIR/config/settings.d
# cat > $CONFIG_DIR/realm.yml <<EOF
# ---
# :enabled: true
# :use_provider: realm_ad
# EOF
#   RELM_NAME="EXAMPLE.COM"
#   PRINCIPAL="realm-proxy@EXAMPLE.COM"
#   DOMAIN_CONTROLLER="dc.example.com"
#   COMPUTERNAME_PREFIX="my_required_for_now_nice_prefix"
#   touch $FOREMAN_PROXY_DIR/$KEYTAB_FILENAME
# # Create realm_ad.yml configuration
# cat > $CONFIG_DIR/realm_ad.yml <<EOF
# ---
# :realm: $realm
# :principal: $principal
# :keytab_path: $FOREMAN_PROXY_DIR/$keytab_filename
# :domain_controller: $domain_controller
# :computername_prefix: $computername_prefix
# EOF

