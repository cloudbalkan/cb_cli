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

if [ -f ~/.cloudbalkan ]; then
    source ~/.cloudbalkan
fi

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

    case $ENDPOINT in
        servers)
            FILTERS=" | {id, name, ipaddress, state}"
        ;;        
        *)
            FILTERS=""
        ;;
    esac

    curl -H 'Authorization: Bearer '$AUTH_TOKEN $BASE_URL/api/$1 2>/dev/null | jq -r ".[] $FILTERS" 
}

cb_api_get_call () {
    ENDPOINT=$1
    ENTITY=$2    
    curl -H 'Authorization: Bearer '$AUTH_TOKEN $BASE_URL/api/$ENDPOINT/$ENTITY  2>/dev/null | jq
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

_handler () {
    ENDPOINT=$1
    ACTION=$2
    ID=$3

    case $ACTION in
        list)
            cb_api_index_call $ENDPOINT
        ;;
        view)
            cb_api_get_call $ENDPOINT $ID
        ;;
    	start|stop|restart)
    	    cb_api_post_call $ENDPOINT $ACTION $ID
    	;;
        *)
            echo "Please use on of the following $ACTION actions: list | view | start | stop | restart"
        ;;
    esac
}

case $ENDPOINT in
    servers|domains|storage|networks)
        _handler $ENDPOINT $ACTION $ID
    ;;
    auth-only)
        echo $AUTH_TOKEN
    ;;
    *)
        echo "Usage: cli.sh COMMAND TYPE"
	echo "ex. ./cli.sh servers list"
    echo "
servers
    list        - list all servers
    view ID     - view server with ID
    start ID    - start server with ID
    stop ID     - stop server with ID
    restart ID  - restart server with ID

storage
    list        - list all storage drives
    view ID     - view storage drive with ID

domains
    list        - list all domains
    view ID     - view domain with ID"
    ;;
esac


