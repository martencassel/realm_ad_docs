# Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Define variables for different groups of dependencies
ENV COMMON_DEPENDENCIES="curl git sudo wget jq net-tools"
ENV BUILD_DEPENDENCIES="build-essential libssl-dev pkg-config"
ENV RUBY_DEPENDENCIES="ruby ruby-dev ruby-libvirt"
ENV SYSTEMD_DEPENDENCIES="libsystemd-dev"
ENV KERBEROS_DEPENDENCIES="libkrb5-dev krb5-user"
ENV LDAP_DEPENDENCIES="libldap-dev libsasl2-dev"
ENV BATS_DEPENDENCIES="bats"

# Install dependencies for Bats and the script
RUN apt-get update && apt-get install -y \
    $COMMON_DEPENDENCIES \
    $BUILD_DEPENDENCIES \
    $RUBY_DEPENDENCIES \
    $SYSTEMD_DEPENDENCIES \
    $KERBEROS_DEPENDENCIES \
    $LDAP_DEPENDENCIES \
    $BATS_DEPENDENCIES

# Copy the install script and Bats test script into the container
COPY install_from_source.sh /usr/local/bin/install_from_source.sh
COPY test_install_from_source.bats /usr/local/bin/test_install_from_source.bats

# Make the install script executable
RUN chmod +x /usr/local/bin/install_from_source.sh

# Keep the container running
CMD ["tail", "-f", "/dev/null"]