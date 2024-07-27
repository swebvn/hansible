if [ -f /usr/bin/wp-cli ]; then
    echo "WordPress CLI already installed"
else
    echo "Installing WordPress CLI"
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/bin/wp-cli
    echo "WordPress CLI installed"
fi

# ensure php exist in cli
php_path=$(which php)

if [ -z "$php_path" ]; then
    echo "PHP is not installed"

    if [ -f /opt/php-7.4.30/bin/php ]; then
        echo "Symlink PHP"
        ln -s /opt/php-7.4.30/bin/php /usr/bin/php
    elif [ -f /opt/php-7.2.18/bin/php ]; then
        echo "Symlink PHP"
        ln -s /opt/php-7.2.18/bin/php /usr/bin/php
    fi
fi

# enable proc_open
if [ -f /opt/php-7.2.18/lib/php.ini ]; then
    if grep -q "proc_open" /opt/php-7.2.18/lib/php.ini; then
        echo "Removing proc_open from disable_functions"
        sed -i -E 's/(disable_functions = .*),?proc_open,?/\1/' /opt/php-7.2.18/lib/php.ini
    fi
fi
