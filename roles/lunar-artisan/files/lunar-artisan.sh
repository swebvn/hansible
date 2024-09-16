# loop thu all the directory in format

for dir in /home/*/domains/*/public_html; do
    user=$(echo $dir | cut -d'/' -f3)
    domain=$(echo $dir | cut -d'/' -f5)

    echo "Current user: $user, domain: $domain"
done