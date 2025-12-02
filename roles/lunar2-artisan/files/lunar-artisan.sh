# Execute artisan command in the current release directory
command=$1

if [ -L "/home/deploy/current" ] && [ -f "/home/deploy/current/.env" ]; then
    # run the artisan command
    su - deploy -c "{
        cd /home/deploy/current
        echo /home/deploy/current
        $command
    }"
fi