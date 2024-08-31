#!/usr/bin/env bats

# Test the installation script
@test "Run install_from_source.sh and verify installation" {
  # Run the install script
  echo "Running install_from_source.sh, this may take a few minutes..."
  run /usr/local/bin/install_from_source.sh

  # Check if the script ran successfully
  echo "Checking if the script ran successfully..."
  [ "$status" -eq 0 ]

  # Verify that the smart-proxy service is running
  echo "Checking if the smart-proxy service is running..."
  run netstat -tuln | grep ":8000"
  [ "$status" -eq 0 ]

  # Verify that the realm-ad plugin is loaded
  echo "Checking if the realm-ad plugin is loaded..."
  run curl -s -H "Accept: application/json" http://localhost:8000/features | jq '.features[]' | grep "realm_ad"
  [ "$status" -eq 0 ]
}