plugin_zip=$1
plugin_name=$2

# Unzip the plugin zip
unzip -o $plugin_zip

for dir in /home/*/domains/*/public_html/wp-content/plugins; do
    user=$(echo $dir | cut -d'/' -f3)

    echo "Updating plugin $plugin_name for user $user"

    rsync -avh "/tmp/$plugin_name/" "$dir/$plugin_name/"
    chown -R $user:$user "$dir/$plugin_name"
    chmod 755 "$dir/$plugin_name"
done

# remove the unzip folder
rm -rf "/tmp/$plugin_name"