plugin_zip=$1
plugin_name=$2

for dir in /home/*/domains/*/public_html/wp-content/plugins; do
    user=$(echo $dir | cut -d'/' -f3)

    echo "Updating plugin $plugin_name for user $user"

    rsync -avh "/tmp/$plugin_name" "$dir/$plugin_name"
    chown -R $user:$user "$dir/$plugin_name"
done