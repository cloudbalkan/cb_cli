#!/bin/bash

## Parameters
ID=$3
ACTION=$2

ENDPOINT=$1

CB_USER=
CB_PASS=

CLIENT_ID="CLIENT_ID"
CLIENT_SECRET="CLIENT_PASS"
GRANT="password"

BASE_URL="https://www.cloudbalkan.com"

if [ -z $CB_USER ]; then
	echo "Email:"
	read CB_USER
	export CB_USER=$CB_USER
fi

if [ -z $CB_PASS ]; then
	echo "Password:"
	read -s CB_PASS
	export CB_PASS=$CB_PASS
fi

echo "Authenticating...\n"

AUTH="{\"client_id\": \"$CLIENT_ID\", \"client_secret\": \"$CLIENT_SECRET\", \"grant_type\": \"$GRANT\", \"password\": \"$CB_PASS\", \"username\": \"$CB_USER\"}"

AUTH_TOKEN=$(curl -H "Content-Type: application/json" -d "$AUTH" $BASE_URL/api/oauth/access_token 2>/dev/null | jq -r ".access_token")

cb_api_index_call () {
    ENDPOINT=$1
    curl -H 'Authorization: Bearer '$AUTH_TOKEN $BASE_URL/api/$1 2>/dev/null | jq -r ".[] .name, .[] .id" 
}

cb_api_post_call () {
    ENDPOINT=$1
    ACTION=$2
    ENTITY=$3
    curl -X POST -H 'Authorization: Bearer '$AUTH_TOKEN $BASE_URL/api/$ENDPOINT/$ENTITY/$ACTION 2>/dev/null | jq
}

cb_api_create_call () {
    ENDPOINT=$1
    DATA=$2
    curl -H 'Authorization: Bearer '$AUTH_TOKEN -d $DATA $BASE_URL/api/$1 2>/dev/null | jq -r ".[] .id" 
}

_servers_handler () {
    ACTION=$1
    ID=$2

    case $ACTION in
        list)
            cb_api_index_call servers
        ;;
	restart)
	    cb_api_post_call servers $ACTION $ID
	;;
        *)
            echo "Please use on of the following $ACTION actions: list"
        ;;
    esac
}

_networks_handler () {
    ACTION=$1

    case $ACTION in
        list)
            cb_api_index_call networks
        ;;
        *)
            echo "Please use on of the following $ACTION actions: list"
        ;;
    esac
}


case $ENDPOINT in
    servers)
        _servers_handler $ACTION $ID
    ;;
    networks)
        _networks_handler $ACTION
    ;;
    auth-only)
        echo $AUTH_TOKEN
    ;;
    *)
        echo "Usage: cbline COMMAND TYPE"
	echo "ex. cbline list servers"
    ;;
esac


