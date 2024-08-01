for plugin_dir in /home/*/domains/*/public_html/wp-content/plugins/; do
  # check of wp-rocket folder exists
  if [ -d "$plugin_dir/wp-rocket" ]; then
    echo "Tuning WP Rocket settings for $plugin_dir"
    wp-cli option patch update wp_rocket_settings manual_preload 0
    wp-cli option patch update wp_rocket_settings purge_cron_interval 300
  fi
done