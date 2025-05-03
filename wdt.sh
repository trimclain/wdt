#!/usr/bin/env bash
#
# wdt: Website Deployment Tool
#
# Author: @trimclain
# License: MIT

# shellcheck disable=SC2155,SC2164
# Disabled:
# "Declare and assign separately to avoid masking return values":
#  https://www.shellcheck.net/wiki/SC2155
# "Use 'pushd ... || exit' or 'pushd ... || exit' in case pushd fails":
#  https://www.shellcheck.net/wiki/SC2164

readonly VERSION="v0.1.0"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly RESET='\033[0m'

pprint() {
    printf "${CYAN}[%b]:${RESET} %b\n" "$1" "$2"
}

echo_inline() {
    echo -en "${CYAN}[$1]:${RESET} $2 "
}

confirm() {
    printf "${GREEN}%b${RESET}\n" "$1"
}

error() {
    printf "${RED}ERROR:$RESET %b\n" "$1" >&2 # use %b instead of %s to enable colors
    exit 1
}

# Don't run this script as root
[ "$EUID" -ne 0 ] || error "Please run this script as a normal user, not as root."

already_installed() {
    if command -v "$1" > /dev/null; then
        pprint "$1" "$2"
        return 0
    else
        return 1
    fi
}

SUDO_PROMPTED='false'
require_sudo_for() {
    # TODO: any need for EUID check if I do it above?
    if [[ "$EUID" -ne 0 ]]; then
        # Check if the user will be prompted for sudo credentials
        if ! sudo -n true &> /dev/null; then
            if [[ "$SUDO_PROMPTED" == "false" ]]; then
                printf "${MAGENTA}[wdt]:${RESET} Please enter your password to install %b.\n" "$1"
                SUDO_PROMPTED='true'
            fi
            if ! sudo -v; then
                error "Failed to obtain superuser privileges. Exiting."
            fi
        fi
    fi
}

display_help() {
    cat << EOF
Usage:
  ${0##*/} [options...] [-n DOMNAME] [-p PORTNUM] [-e EMAIL]

OPTIONS:
  -h, --help             display this help menu
  -n, --name DOMNAME     pass the name of the domain you want to use
  -p, --port PORTNUM     pass the port you'll host your website on
  -s, --secure           enable the ssl certificate using certbot
  -e, --email EMAIL      pass the email for the ssl certificate for registration and recovery contact
  -a, --autorenew        schedule automatic renewal of the certificate using crontab
  -d, --delete           undo everything wdt has done for a specified domain
  --purge-all            undo everything wdt has done and uninstall every software wdt has installed
EOF
}

#######################################
# Install NodeJS LTS
#######################################
install_nodejs() {
    already_installed "node" "NodeJS is already installed" && return 0

    echo_inline "nodejs" "Installing n version manager with nodejs LTS..."
    if [ -z "$N_PREFIX" ]; then
        curl -sL https://git.io/n-install | N_PREFIX=~/.n bash -s -- -q
    else
        # don't add N_PREFIX to .bashrc or .zshrc
        curl -sL https://git.io/n-install | N_PREFIX=~/.n bash -s -- -q -n
    fi
    confirm "Done"
}

#######################################
# Install PM2 process manager
#######################################
install_pm2() {
    already_installed "pm2" "PM2 process manager is already installed" && return 0

    echo_inline "pm2" "Installing PM2, a process manager for node.js..."
    npm install --global pm2@latest &> /dev/null
    confirm "Done"
}

#######################################
# Install ExpressJS for current project
#######################################
install_expressjs() {
    if [ ! -f ./package.json ]; then
        echo_inline "npm" "Initializing npm and installing ExpressJS..."
        npm init -y > /dev/null
        npm install express &> /dev/null
        confirm "Done"
    elif [ ! -d ./node_modules/express ]; then
        echo_inline "npm" "Installing ExpressJS..."
        npm install express &> /dev/null
        confirm "Done"
    fi
}

#######################################
# Create app.js to serve the directory "public" to localhost:port
# Arguments:
#   port - the port number to redirect to when hitting the server IP
#######################################
create_appjs() {
    if [ -f ./app.js ]; then
        pprint "server" "app.js already exists"
        exit 0
    fi

    local directory="public"
    local app_js_content="// app.js for hosting the directory \"$directory\" on port $1 -- created by wdt\nconst express = require('express')\nconst path = require('path')\n\nconst app = express()\nconst port = $1\nconst directory = \"$directory\"\n\n// express provides a built in way to serve all static files from the directory\napp.use(express.static(directory));\n\napp.listen(port, () => {\n\tconsole.log(\`Express is listening on port \${port}\`)\n})"
    echo_inline "server" "Creating app.js to serve the directory \"$directory\" to localhost:$1..."
    echo -e "$app_js_content" > app.js
    confirm "Done"
}

#######################################
# Install Uncomplicated Firewall
#######################################
install_ufw() {
    already_installed "ufw" "Uncomplicated Firewall is already installed" && return 0

    require_sudo_for "ufw"
    echo_inline "ufw" "Installing UFW, a firewall for Linux..."
    sudo apt-get install -y ufw &> /dev/null
    confirm "Done"
}

#######################################
# Configure Uncomplicated Firewall
#######################################
configure_ufw() {
    if [[ ! $(locale | grep LANG | cut -d= -f2 | cut -d_ -f1) == *"en"* ]] || [[ ! $(locale | grep LANG | cut -d= -f2 | cut -d_ -f1) == *"C"* ]]; then
        # Problem: I can't tell if ufw is active or not, e.g. german locale will have status "Inaktiv"
        pprint "ufw" "UFW is not in English. Skipping firewall configuration. Consider configuring it manually later."
        return 1
    fi

    require_sudo_for "ufw"
    if sudo ufw status | grep -q "Status: active"; then
        echo_inline "ufw" "Enabling ufw and allowing ssh (22), http (80) and https (443)..."
        sudo ufw --force enable > /dev/null
        sudo ufw allow ssh > /dev/null
        sudo ufw allow http > /dev/null
        sudo ufw allow https > /dev/null
        confirm "Done"
    else
        echo_inline "ufw" "Firewall is enabled. Allowing ssh (22), http (80) and https (443)..."
        sudo ufw allow ssh > /dev/null
        sudo ufw allow http > /dev/null
        sudo ufw allow https > /dev/null
        confirm "Done"
    fi
}

#######################################
# Install Nginx
#######################################
install_nginx() {
    already_installed "nginx" "Nginx is already installed" && return 0

    require_sudo_for "nginx"
    echo_inline "nginx" "Installing nginx..."
    sudo apt-get install -y nginx &> /dev/null
    confirm "Done"
}

#######################################
# Create the domain web root directory in /var/www. This isn't necessary,
# as it is the old way nginx was supposed to be used. Users can ignore this.
# Arguments:
#   name - the domain name
#######################################
optional_nginx_create_var_domain_directory() {
    # TODO: run only if [ ! -d /var/www/$name/html ]
    mkdir -p "/var/www/$1/html"
    pprint "nginx" "Creating the directory /var/www/$1/html..."
    # TODO: is this necessary?
    #chmod -R 755 /var/www
    # create sample page for the site
    pprint "nginx" "Adding a sample index.html to /var/www/$1/html..."
    index_html_data="<!-- Created by wdt -->\n<html>\n\t<head>\n\t\t<title>Welcome to $1!</title>\n\t</head>\n\t<body>\n\t\t<h1> Success! The $1 server block is working! </h1>\n\t</body>\n</html>"
    echo -e "$index_html_data" > "/var/www/$1/html/index.html"
}

#######################################
# Create Server Block Files for a domain
# Arguments:
#   name - the domain name
#   port - the port number to redirect to when hitting the server IP
#######################################
nginx_create_server_block_files() {
    pprint "nginx" "Creating /etc/nginx/sites-available/$1 and adding the configuration to redirect to port $2..."
    require_sudo_for "nginx server file for $1"

    # create new server file and correct it's permissions and ownership
    local nginx_sites_available_file_data="# Virtual Host configuration for $1 -- created by wdt\n#\nserver {\n\tlisten 80;\n\tlisten [::]:80;\n\n\tserver_name $1 www.$1;\n\n\troot /var/www/$1/html;\n\tindex index.html index.htm index.nginx-debian.html;\n\n\tlocation / {\n\t\tproxy_pass http://localhost:$2; # whatever port your app runs on\n\t\tproxy_http_version 1.1;\n\t\tproxy_set_header Upgrade \$http_upgrade;\n\t\tproxy_set_header Connection 'upgrade';\n\t\tproxy_set_header Host \$host;\n\t\tproxy_cache_bypass \$http_upgrade;\n\t}\n}"
    echo -e "$nginx_sites_available_file_data" > "$1"
    sudo mv "$1" /etc/nginx/sites-available/
    sudo chown -R root:root "/etc/nginx/sites-available/$1"
    sudo chmod 644 "/etc/nginx/sites-available/$1"

    # create a symlink to sites-enabled
    pprint "nginx" "Adding a symlink from /etc/nginx/sites-enabled/$1 to /etc/nginx/sites-available/$1..."
    sudo ln -s "/etc/nginx/sites-available/$1" /etc/nginx/sites-enabled/

    # uncomment one line in order to avoid a possible hash bucket memory problem that can arise from adding additional server names
    sudo sed -i "s|# server_names_hash_bucket_size 64;|server_names_hash_bucket_size 64;|g" /etc/nginx/nginx.conf

    # restart nginx for changes to take effect
    echo_inline "nginx" "Restarting nginx..."
    sudo systemctl restart nginx
    confirm "Done"
}

#######################################
# Create Server Block Files for a domain
# Arguments:
#   name - the domain name
#   email - the email to register the certificate at Let's Encrypt
#######################################
configure_ssl_with_nginx() {
    # TODO: run only if $enable_ssl is true

    # Install certbot with nginx extension
    if ! command -v certbot > /dev/null; then
        require_sudo_for "certbot"
        echo_inline "certbot" "Installing Certbot from Let's Encrypt..."
        sudo apt-get install -y certbot &> /dev/null
        sudo apt-get install -y python3-certbot-nginx &> /dev/null
        confirm "Done"
    elif [ ! -d /usr/lib/python3/dist-packages/certbot_nginx ]; then
        # NOTE: this hardcoded path is only tested in Ubuntu
        require_sudo_for "certbot-nginx plugin"
        echo_inline "certbot" "Installing the nginx plugin for certbot..."
        sudo apt-get install -y python3-certbot-nginx &> /dev/null
        confirm "Done"
    else
        pprint "certbot" "Certbot with nginx plugin is already installed"
    fi

    # Enable SSL
    require_sudo_for "ssl certificate"
    pprint "certbot" "Installing the certificate for $1..."
    sudo certbot --nginx -d "$1" -d "www.$1" --email "$2" --agree-tos --no-eff-email --redirect &> /dev/null
    confirm "Done"
}

#######################################
# Create Server Block Files for a domain
# Arguments:
#   None
#######################################
create_certbot_cronjob() {
    # TODO: if $autorenew_ssl is true

    local tmpfile=$(mktemp)
    # TODO: do I need to use -u "$(logname)" if I don't run in sudo
    crontab -u "$(logname)" -l > "$tmpfile"

    if grep -qF "certbot renew --quiet" "$tmpfile"; then
        rm -f "$tmpfile"
        pprint "crontab" "The cron job for certbot to renew the certificate already exists"
    else
        echo_inline "crontab" "Creating a cron job for certbot to renew the certificate..."
        # at 5 a.m every day
        echo "0 5 * * * /usr/bin/certbot renew --quiet" >> "$tmpfile"
        crontab -u "$(logname)" "$tmpfile"
        rm -f "$tmpfile"
        confirm "Done"
    fi
}

# TODO: $purge_it_all
# if $purge_it_all; then
#     read -p "Are you sure you want to purge everything wdt has done? [yes|no] " -r
#     if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
#         # nodejs
#         if [ -d /home/$(logname)/.n ]; then
#             # delete all pm2 jobs
#             sudop "pm2 delete all" &> /dev/null
#             echo -en "$CC[nodejs]:$NC Deleting n version manager with node.js LTS... "
#             rm -rf /home/$(logname)/.n
#             echo "Done"
#         fi
#         # ufw
#         # if [ -f /usr/sbin/ufw ]; then
#         #     echo -en "$CC[ufw]:$NC Disabling and deleting ufw -- the Uncomplicated Firewall... "
#         #     sudo ufw disable &> /dev/null
#         #     sudo apt purge ufw -y &> /dev/null
#         #     echo "Done"
#         # fi
#         # nginx
#         if [ -f /usr/sbin/nginx ]; then
#             echo -en "$CC[nginx]:$NC Deleting nginx... "
#             sudo apt purge nginx nginx-common -y &> /dev/null
#             # delete everything in /var/www/ except html folder
#             sudo find /var/www -mindepth 1 ! -regex '^/var/www/html\(/.*\)?' -delete
#             echo "Done"
#         fi
#         # certbot
#         if [ -f /usr/bin/certbot ]; then
#             # check if ssl certificate exists
#             # TODO: delete all certificates (get the list of them)
#             # if [[ $(sudo certbot certificates 2> /dev/null) == *"$name"* ]]; then
#             #     echo -en "$CC[certbot]:$NC Deleting the SSL certificate for $name... "
#             #     sudo certbot delete --cert-name $name &> /dev/null
#             #     echo "Done"
#             # fi
#             echo -en "$CC[certbot]:$NC Deleting certbot... "
#             sudo apt purge python3-certbot-nginx -y &> /dev/null
#             echo "Done"
#         fi
#         # crontab
#         # delete the cron job if it exists
#         # if there is no crontab, this will not error out
#         if [[ -f /var/spool/cron/crontabs/$(logname) ]]; then
#             tmpfile="tmp.txt"
#             crontab -u $(logname) -l > $tmpfile
#             if grep -qF "certbot renew --quiet" $tmpfile; then
#                 echo -en "$CC[crontab]:$NC Deleting the cron job for certbot to renew the certificate... "
#                 sed -i "/certbot renew --quiet/d" $tmpfile
#                 crontab -u $(logname) $tmpfile && rm $tmpfile
#                 echo "Done";
#             else
#                 rm $tmpfile
#             fi
#         fi

#         echo -en "$CC[apt]:$NC Cleaning it up... "
#         sudo apt autoremove -y &> /dev/null
#         echo "Done";

#         echo -e "${CYAN}The purge was successfull.$NC"
#         exit
#     else
#         exit 0
#     fi
# fi

# TODO: $delete_domain
# if $delete_domain; then

#     if [ ! "$name" ]; then
#         die "${RED}ERROR:$NC Please provide the DOMAIN to delete."
#     fi

#     read -p "Are you sure you want to delete $name? [y|n] " -n 1 -r
#     echo    # (optional) move to a new line
#     if [[ $REPLY =~ ^[Yy]$ ]]; then

#         if [ -f /etc/nginx/sites-available/$name ]; then
#             echo -en "$CC[nginx]:$NC Deleting /etc/nginx/sites-available/$name... "
#             sudo rm /etc/nginx/sites-available/$name
#             echo "Done"
#         else
#             die "${RED}ERROR:$NC $name entry not found."
#         fi
#         # -L check if there is a symlink, no matter broken or not
#         if [ -L /etc/nginx/sites-enabled/$name ]; then
#             echo -en "$CC[nginx]:$NC Deleting the symlink /etc/nginx/sites-enabled/$name... "
#             sudo rm /etc/nginx/sites-enabled/$name
#             echo "Done"
#         fi
#         if [ -d /var/www/$name ]; then
#             echo -en "$CC[nginx]:$NC Deleting /var/www/$name... "
#             sudo rm -r /var/www/$name
#             echo "Done"
#         fi
#         sudo systemctl restart nginx

#         # check if ssl certificate exists
#         if [[ $(sudo certbot certificates 2> /dev/null) == *"$name"* ]]; then
#             echo -en "$CC[certbot]:$NC Deleting the SSL certificate for $name... "
#             sudo certbot delete --cert-name $name &> /dev/null
#             echo "Done"
#         fi

#         # TODO: fix the case when there are other domains who need this job
#         # delete the cron job if it exists
#         # if there is no crontab, this will not error out
#         if [[ -f /var/spool/cron/crontabs/$(logname) ]]; then
#             tmpfile="tmp.txt"
#             crontab -u $(logname) -l > $tmpfile
#             if grep -qF "certbot renew --quiet" $tmpfile; then
#                 echo -en "$CC[crontab]:$NC Deleting the cron job for certbot to renew the certificate... "
#                 sed -i "/certbot renew --quiet/d" $tmpfile
#                 crontab -u $(logname) $tmpfile && rm $tmpfile
#                 echo "Done";
#             else
#                 rm $tmpfile
#             fi
#         fi

#         echo -e "${CYAN}The setup for $name was successfully deleted.$NC"
#         exit
#     else
#         exit 0
#     fi
# fi

main() {
    # Initialize all the option variables.
    # This ensures we are not contaminated by variables from the environment.
    name=
    port=
    email=
    enable_ssl=false
    autorenew_ssl=false
    delete_domain=false
    purge_it_all=false

    while :; do
        case $1 in
            -h | -\? | --help)
                display_help
                exit 0
                ;;
            -n | --name)
                if [ "$2" ]; then
                    name=$2
                    shift
                else
                    error '"--name" requires a non-empty argument.'
                fi
                ;;
            --name=?*)
                name=${1#*=} # Delete everything up to "=" and assign the remainder.
                ;;
            --name=) # Handle the case of an empty --name=
                error '"--name" requires a non-empty argument.'
                ;;
            -p | --port)
                if [ "$2" ]; then
                    port=$2
                    shift
                else
                    error '"--port" requires a non-empty argument.'
                fi
                ;;
            --port=?*)
                port=${1#*=} # Delete everything up to "=" and assign the remainder.
                ;;
            --port=) # Handle the case of an empty --name=
                error '"--port" requires a non-empty argument.'
                ;;
            -e | --email)
                if [ "$2" ]; then
                    email=$2
                    shift
                else
                    error '"--email" requires a non-empty argument.'
                fi
                ;;
            --email=?*)
                email=${1#*=} # Delete everything up to "=" and assign the remainder.
                ;;
            --email=) # Handle the case of an empty --name=
                error '"--email" requires a non-empty argument.'
                ;;
            -s | --secure)
                enable_ssl=true
                ;;
            -a | --autorenew)
                autorenew_ssl=true
                ;;
                # TODO: fix this ugly sht
                # -d|--delete)
                #     delete_domain=true
                #     ;;
                # --purge-all)
                #     purge_it_all=true
                #     ;;
            --) # End of all options.
                shift
                break
                ;;
            -?*)
                # printf 'WARNING\: Unknown option (ignored): %s\n' "$1" >&2
                error "invalid option -- \"$1\". Try \"wdt --help\" for more information."
                ;;
                # TODO: what to do here? 1 - error out same as above, 2 - use this
                # as the default way to get the name (very questionable)
            ?*)
                # echo "The variable without dash: $1; Doing nothing!"
                error "invalid option -- \"$1\". Try \"wdt --help\" for more information."
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    # check for necessary arguments
    if [ ! "$name" ] || [ ! "$port" ]; then
        error "Please provide both the DOMAIN and the PORT. Try \"wdt --help\" for more information."
    elif $enable_ssl && [ ! "$email" ]; then
        error "Please provide the EMAIL to connect to the certificate for registration and recovery contact."
    fi

    # # FINISH
    # echo -e "${CYAN}The setup for $name is complete.$NC"
    # echo -e "${CYAN}Put all your static files in folder \"public\" and use \"pm2 start app.js\" to host your website on localhost:$port.$NC"
}

# main "$@"
