#!/bin/bash

plugin_zip=$1
plugin_name=$2

# Find all WordPress plugin directories with the specified pattern
for dir in /home/*/domains/*/public_html/wp-content/plugins; do
  echo "Current dir: $dir"
  # Extract the username from the directory path
  user=$(echo "$dir" | sed -r 's|^/home/([^/]+)/.*|\1|')

  # Rsync the plugin files to the plugin directory
  rsync -a /tmp/${plugin_name}/ "${dir}/${plugin_name}/"

  # Change ownership of the plugin directory
  chown -R "${user}:${user}" "${dir}/${plugin_name}"

  # Activate the plugin using wp-cli
  wp_path=$(echo "$dir" | sed 's|/wp-content/plugins||')
  # we really need a timeout here, because the hacked wp site run this forever
  timeout 30s php -d memory_limit=512M /usr/bin/wp-cli plugin activate "$plugin_name" --path="$wp_path" --allow-root

  # Check if the wp-cli command failed
  if [ $? -ne 0 ]; then
    echo "Failed to activate plugin ${plugin_name} for site at ${wp_path}. Continuing..."
  fi
done