for plugin_dir in /home/*/domains/*/public_html/wp-content/plugins/; do
  # check of wp-rocket folder exists
  if [ -d "$plugin_dir/wp-rocket" ]; then
    #change current directory to the plugin directory
    cd $plugin_dir

    echo "Tuning WP Rocket settings for $plugin_dir"

    # we need check if the
    wp-cli option patch update wp_rocket_settings manual_preload 0 --allow-root
    wp-cli option patch update wp_rocket_settings purge_cron_interval 322 --allow-root
  fi
done