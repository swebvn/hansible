#!/bin/bash
CONFIG_DIR="/opt/php-7.2.18/etc/php-fpm.d"

# New values for the settings
NEW_MAX_CHILDREN="5"
NEW_MAX_REQUESTS="200"

# Check if the directory exists
if [[ -d "$CONFIG_DIR" ]]; then
    # Loop through all files in the directory
    for config_file in "$CONFIG_DIR"/*.conf; do
        # Check if the file exists (in case no .conf files are found)
        if [[ -f "$config_file" ]]; then
            echo "Processing config file: $config_file"
            # Add your processing logic here
	# Update pm.max_children and pm.max_requests values
            sed -i.bak -E "s/^(pm\.max_children\s*=\s*).*/\1$NEW_MAX_CHILDREN/" "$config_file"
            sed -i.bak -E "s/^(pm\.max_requests\s*=\s*).*/\1$NEW_MAX_REQUESTS/" "$config_file"

            echo "Updated pm.max_children to $NEW_MAX_CHILDREN and pm.max_requests to $NEW_MAX_REQUESTS in $config_file"
        else
            echo "No configuration files found in $CONFIG_DIR"
            break
        fi
    done
else
    echo "Directory $CONFIG_DIR does not exist"
fi