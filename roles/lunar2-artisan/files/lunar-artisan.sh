# loop thu all the directory in format
command=$1

for dir in /home/deploy/*.tdalunar.com; do
    if [ ! -f "$dir/.env" ]; then
        continue
    fi

    # run the artisan command
    su - deploy -c "{
        cd $dir
        echo $dir
        $command
    }"
done