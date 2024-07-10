# loop thru all folder /home/username/domains/domain.xxx/public_html

for d in /home/*/domains/*/public_html; do
    # check if wp-config.php exists
    if [ ! -f "$d/wp-config.php" ]; then
        continue
    fi

    # get the database name
    dbname=$(grep DB_NAME "$d/wp-config.php" | cut -d \' -f 4)


    # update permissions = read_write
    mysql -u root -e "UPDATE `$dbname.wp_woocommerce_api_keys` SET permissions = 'read_write';"

    # if the query above error, echo error
    if [ $? -ne 0 ]; then
        echo "Error: $dbname"
    else
        echo "Updated permissions: $dbname"
    fi
done