# Execute artisan command in the lucommerce directory
command=$1

if [ -f "/home/deploy/lucommerce/.env" ]; then
    # run the artisan command
    su - deploy -c "{
        cd /home/deploy/lucommerce
        echo /home/deploy/lucommerce
        $command
    }"
fi