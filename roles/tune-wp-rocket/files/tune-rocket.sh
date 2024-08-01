for website_dir in /home/*/domains/*/public_html/; do
  # check of wp-rocket folder exists
  if [ -d "$website_dir/wp-content/plugins/wp-rocket" ]; then
    #change current directory to the plugin directory
    cd $website_dir

    echo "Tuning WP Rocket settings for $website_dir"

    # we need check if the
    wp-cli option patch update wp_rocket_settings manual_preload 0 --allow-root || echo "Failed to update manual_preload"
    wp-cli option patch update wp_rocket_settings purge_cron_interval 322 --allow-root || echo "Failed to update purge_cron_interval"
  fi
done