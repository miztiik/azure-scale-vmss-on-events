#!/bin/bash
set -e

LOG_FILE="/var/log/miztiik-$(date +'%Y-%m-%d').json"
COMPUTER_NAME=$(hostname)
SLEEP_AT_WORK_SECS=0
LOG_COUNT=1000

function write_n_logs(){
    for ((i=1; i<=LOG_COUNT; i++)); do
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        REQ_ID=$(uuidgen)
        STORE_ID=$(shuf -i 10-68 -n 1)
        STORE_FQDN=$(hostname -f)
        STORE_IP=$(hostname -I)
        CUST_ID=$(shuf -i 150-6500 -n 1)
        SKU=$(shuf -i 15000-18000 -n 1)
        QTY=$(shuf -i 1-20 -n 1)
        PRICE=$(echo $((RANDOM % 9001 + 1000)) | sed 's/..$/.&/')
        DISCOUNT=$(echo $((RANDOM % 901 + 100)) | sed 's/.$/.&/')
        GIFT_WRAP=$((RANDOM % 2 == 1))
        PRIORITY_SHIPPING=$((RANDOM % 2 == 1))
        CONTACT_ME="github.com/miztiik"
        JSON_DATA="{\"request_id\": \"$(uuidgen)\", \"event_type\": \"inventory_event\", \"store_id\": $STORE_ID, \"store_fqdn\": \"$STORE_FQDN\", \"store_ip\": \"$STORE_IP\", \"cust_id\": $CUST_ID, \"category\": \"Camera\", \"sku\": $SKU, \"price\": $PRICE, \"qty\": $QTY, \"discount\": $DISCOUNT, \"gift_wrap\": $GIFT_WRAP, \"variant\": \"MystiqueAutomation\", \"priority_shipping\": $PRIORITY_SHIPPING, \"TimeGenerated\": \"$(date +'%Y-%m-%dT%H:%M:%S')\", \"contact_me\": \"$CONTACT_ME\" }"
        echo $JSON_DATA >> $LOG_FILE
        echo "Writing to log: ($i/$LOG_COUNT) -------------"
        echo -e "$JSON_DATA \n"
        sleep $SLEEP_AT_WORK_SECS
    done
}


function write_logs_forever(){
    while true; do
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        REQ_ID=$(uuidgen)
        STORE_ID=$(shuf -i 10-68 -n 1)
        STORE_FQDN=$(hostname -f)
        STORE_IP=$(hostname -I)
        CUST_ID=$(shuf -i 150-6500 -n 1)
        SKU=$(shuf -i 15000-18000 -n 1)
        QTY=$(shuf -i 1-20 -n 1)
        PRICE=$(echo $((RANDOM % 9001 + 1000)) | sed 's/..$/.&/')
        DISCOUNT=$(echo $((RANDOM % 901 + 100)) | sed 's/.$/.&/')
        GIFT_WRAP=$((RANDOM % 2 == 1))
        PRIORITY_SHIPPING=$((RANDOM % 2 == 1))
        CONTACT_ME="github.com/miztiik"
        JSON_DATA="{\"request_id\": \"$(uuidgen)\", \"event_type\": \"inventory_event\", \"store_id\": $STORE_ID, \"store_fqdn\": \"$STORE_FQDN\", \"store_ip\": \"$STORE_IP\", \"cust_id\": $CUST_ID, \"category\": \"Camera\", \"sku\": $SKU, \"price\": $PRICE, \"qty\": $QTY, \"discount\": $DISCOUNT, \"gift_wrap\": $GIFT_WRAP, \"variant\": \"MystiqueAutomation\", \"priority_shipping\": $PRIORITY_SHIPPING, \"TimeGenerated\": \"$(date +'%Y-%m-%dT%H:%M:%S')\", \"contact_me\": \"$CONTACT_ME\" }"
        echo $JSON_DATA >> $LOG_FILE
        echo "Writing to log: ($i/$LOG_COUNT) -------------"
        echo -e "$JSON_DATA \n"
        sleep $SLEEP_AT_WORK_SECS
    done
}


write_n_logs