# loop thu all the directory in format
command=$1

for dir in /home/*/domains/*/public_html; do
    user=$(echo $dir | cut -d'/' -f3)
    domain=$(echo $dir | cut -d'/' -f5)

    if [ ! -f "$dir/.env" ]; then
        continue
    fi

    # run the artisan command
    su - $user -c "{
        cd $dir
        echo "RUNNING AT: $dir"
        $command
    }"
done