#!/usr/bin/env bash

###############################################################################
#           An attempt to rewrite the original script more beautiful          #
###############################################################################

#######################################
# Colors
#######################################
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
CC=$GREEN # Chosen Color


###############################################################################
# HELPER FUNCTIONS
###############################################################################

#######################################
# Print an error message and exit 1
# Globals:
#   RED
#   NC
# Arguments:
#   message - the message to be printed
#######################################
die() {
    printf "${RED}ERROR:$NC %b\n" "$1" >&2 # use %b instead of %s to enable colors
    exit 1
}

#######################################
# Print a pretty info message
# Globals:
#   CC
#   NC
# Arguments:
#   title - the title of the message
#   message - the message to be printed
#######################################
pprint() {
    printf "${CC}[%b]:$NC %b\n" "$1" "$2" >&2
}

pretty_run() {
    local title=$1
    shift
    local message=$1
    shift
    echo -en "${CC}[$title]:$NC $message... "
    {
        # eval "$@"
        # TODO: continue like this
        sh -c "$*"
    } # &> /dev/null
    # echo -en "${CC}[nodejs]:$NC Installing n version manager with node.js LTS... "
    # # check if N_PREFIX has to be added to .bashrc or .zshrc
    # if [ -z "$N_PREFIX" ]; then
    #     curl -sL https://git.io/n-install | N_PREFIX=~/.n bash -s -- -q
    # else
    #     curl -sL https://git.io/n-install | N_PREFIX=~/.n bash -s -- -q -n
    # fi
    # # fix the ownership problem
    # sudo chown -R $(logname):$(logname) /home/$(logname)/.n
    echo "Done"
}

###############################################################################
tester() {
    # pprint "nodejs" "Node is already installed"
    local my_long_command="echo 'hello world'\
        && echo 'okidoki' \
        && cat /etc/hostname"
    # local my_long_command=("echo" "hello world" "&&" "echo" "okidoki" "&&" "cat" "/etc/hostname")
    # pretty_run "nodejs" "Node is already installed" "${my_long_command[@]}"
    pretty_run "nodejs" "Node is already installed" "$my_long_command"
}

tester "$@"

###############################################################################

# Usage info
show_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS...] [-n DOMNAME] [-p PORTNUM] [-e EMAIL]
Setup everything to deploy a website.

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

require_node(){
    if command -v node > /dev/null; then
        pprint "nodejs" "Node is already installed"
        return 0
    fi
}

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
            -h|-\?|--help)
                show_help    # Display a usage synopsis.
                exit
                ;;
            -n|--name)       # Takes an option argument; ensure it has been specified.
                if [ "$2" ]; then
                    name=$2
                    shift
                else
                    die '"--name" requires a non-empty argument.'
                fi
                ;;
            --name=?*)
                name=${1#*=} # Delete everything up to "=" and assign the remainder.
                ;;
            --name=)         # Handle the case of an empty --name=
                die '"--name" requires a non-empty argument.'
                ;;
            -p|--port)       # Takes an option argument; ensure it has been specified.
                if [ "$2" ]; then
                    port=$2
                    shift
                else
                    die '"--port" requires a non-empty argument.'
                fi
                ;;
            --port=?*)
                port=${1#*=} # Delete everything up to "=" and assign the remainder.
                ;;
            --port=)         # Handle the case of an empty --name=
                die '"--port" requires a non-empty argument.'
                ;;
            -e|--email)       # Takes an option argument; ensure it has been specified.
                if [ "$2" ]; then
                    email=$2
                    shift
                else
                    die '"--email" requires a non-empty argument.'
                fi
                ;;
            --email=?*)
                email=${1#*=} # Delete everything up to "=" and assign the remainder.
                ;;
            --email=)         # Handle the case of an empty --name=
                die '"--email" requires a non-empty argument.'
                ;;
            -s|--secure)
                enable_ssl=true
                ;;
            -a|--autorenew)
                autorenew_ssl=true
                ;;
                # TODO: fix this ugly sht
                # -d|--delete)
                #     delete_domain=true
                #     ;;
                # --purge-all)
                #     purge_it_all=true
                #     ;;
            --)              # End of all options.
                shift
                break
                ;;
            -?*)
                # printf 'WARNING\: Unknown option (ignored): %s\n' "$1" >&2
                die "invalid option -- \"$1\". Try \"wdt --help\" for more information."
                ;;
                # TODO: what to do here? 1 - error out same as above, 2 - use this
                # as the default way to get the name (very questionable)
            ?*)
                # echo "The variable without dash: $1; Doing nothing!"
                die "invalid option -- \"$1\". Try \"wdt --help\" for more information."
                ;;
            *)               # Default case: No more options, so break out of the loop.
                break
        esac
        shift # this makes $1 = $2, $2 = $3, etc...
    done

    # check for necessary arguments
    if [ ! "$name" ] || [ ! "$port" ]; then
        die "Please provide both the DOMAIN and the PORT. Try \"wdt --help\" for more information."
    elif $enable_ssl && [ ! "$email" ]; then
        die "Please provide the EMAIL to connect to the certificate for registration and recovery contact."
    fi
}

# main "$@"
