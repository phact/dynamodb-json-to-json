#!/bin/bash

#export BUCKET=dump-to-astra
#export KEY=AWSDynamoDB/01637614448672-63ce3708/data/6x7m6gorpi6jbnd43gbzdy2gf4.json.gz
#export BUCKET=dynamodb-to-astra-export
#export KEY=AWSDynamoDB/01636986635563-346da831/data/cog3ok2kdm2h5idqyapvqa75je.json.gz
export MAX_ERRORS=100

set -x

SEGMENT_TOKEN=$SEGMENT_KEY
TOKEN=`echo ${SEGMENT_TOKEN}: | base64`


if [ -z "$KEYSPACE" ] || [ -z "$SCB_URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$TABLE" ] || [ -z "$DB_ID" ] || [ -z "$BUCKET" ] || [ -z "$KEY" ] || [ -z "$MAX_CONCURRENCY" ] ||  [ -z "$EMAIL" ]  ; then
  echo "the following ENV VARS are required TABLE, KEYSPACE, SCB_URL, USERNAME, PASSWORD, DB_ID, BUCKET, KEY, MAX_CONCURRENCY, EMAIL"
  echo "for example: $ docker run -e TABLE=projects -e KEYSPACE=free -e SCB_URL='https://temp-path-to-scb' -e PASSWORD=datastax -e DB_ID=9172e28d-6b7b-4662-bf8f-57308f1c6d7a -e USERNAME=datastax -e BUCKET=astra-loader -e KEY=ks-projects.csv -e MAX_CONCURRENCY=16 -e EMAIL=test@test.io --rm --name s3-dsbulk phact/s3-dsbulk"
  exit 1
fi

echo "$NOW"
#delete secrets because $$$
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_email_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_pw_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_scbUrl_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_dbName_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_dbId_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_table_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_keyspace_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_username_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_bucket_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_key_"$NOW" --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id temp_"$DB_ID"_"$NOW" --force-delete-without-recovery --region us-east-1

if [ ! -z "$USER_ID" ] ; then

    curl -X POST https://api.segment.io/v1/track -H 'Accept: */*'  \
     -H 'Accept-Encoding: gzip, deflate' \
     -H "Authorization: Basic $TOKEN" \
     -H 'Cache-Control: no-cache' \
     -H 'Connection: keep-alive' \
     -H 'Content-Type: application/json' \
     -H 'Host: api.segment.io' \
     -H 'cache-control: no-cache,no-cache' \
     -d "{ 
        \"userId\": \"$USER_ID\", 
        \"event\": \"DynamoDB Data Loader - Task Initiated\", 
        \"properties\": {  
            \"db_id\": \"$DB_ID\",
            \"db_name\": \"$DB_NAME\",
            \"table_name\": \"$TABLE\",
            \"org_id\": \"$ORG_ID\",
            \"email\": \"$EMAIL\"
        }
    }"


fi


curl -i https://track.customer.io/api/v1/events \
    -X POST \
    -u "$CIO_SITE_ID":"$CIO_API_KEY" \
    -d name=task_started \
    -d data[dbid]="$DB_ID" \
    -d data[table_name]="$TABLE" \
    -d data[keyspace]="$KEYSPACE" \
    -d data[org_id]="$ORG_ID" \
    -d data[db_name]="$DB_NAME" \
    -d data[recipient]="$EMAIL"

curl -L --output scb.zip --url "$SCB_URL"

SCB_PATH=./scb.zip

# encryption requires this signing version
aws configure set s3.signature_version s3v4

# Be careful not to remove the special character  in the line below
node server.js s3 "$BUCKET" "$KEY" | dsbulk/bin/dsbulk load -k "$KEYSPACE" -t "$TABLE" -b "$SCB_PATH" -u "$USERNAME" -p "$PASSWORD" -verbosity 0 -maxConcurrentQueries "$MAX_CONCURRENCY" -c json --schema.allowMissingFields true --codec.date ISO_INSTANT -maxErrors "$MAX_ERRORS" &> out.log
EXIT_CODE="$?"

MESSAGE=$(cat out.log | grep -v "stty:" )

echo $MESSAGE

ls logs/
ERRORS=$(cat logs/*/*error* | grep -ve "^\s" | grep -ve "^Resource:" | sed s/[”“]/'"'/g | base64)

ZERO=0

echo  "exit code: $EXIT_CODE"
echo  "msg: $MESSAGE"

if [ "$EXIT_CODE" -eq "$ZERO" ] ; then
  curl -i https://track.customer.io/api/v1/events \
    -X POST \
    -u "$CIO_SITE_ID":"$CIO_API_KEY" \
    -d name=task_success \
    -d data[dbid]="$DB_ID" \
    -d data[table_name]="$TABLE" \
    -d data[keyspace]="$KEYSPACE" \
    -d data[org_id]="$ORG_ID" \
    -d data[db_name]="$DB_NAME" \
    -d data[recipient]="$EMAIL"

    if [ ! -z "$USER_ID" ] ; then

        curl -X POST https://api.segment.io/v1/track -H 'Accept: */*'  \
         -H 'Accept-Encoding: gzip, deflate' \
         -H "Authorization: Basic $TOKEN" \
         -H 'Cache-Control: no-cache' \
         -H 'Connection: keep-alive' \
         -H 'Content-Type: application/json' \
         -H 'Host: api.segment.io' \
         -H 'cache-control: no-cache,no-cache' \
         -d "{ 
            \"userId\": \"$USER_ID\", 
            \"event\": \"DynamoDB Data Loader - Task Completed\", 
            \"properties\": {  
                \"db_id\": \"$DB_ID\",
                \"db_name\": \"$DB_NAME\",
                \"table_name\": \"$TABLE\",
                \"org_id\": \"$ORG_ID\",
                \"email\": \"$EMAIL\"
            }
        }"

    fi

fi

if [ "$EXIT_CODE" -ne "$ZERO" ] ; then
  echo "name=task_failure&"                                       > data.txt
  echo "data[recipient]=$EMAIL&"                              >> data.txt
  echo "data[dbid]=$DB_ID&"                                   >> data.txt
  echo "data[keyspace]=$KEYSPACE&"                            >> data.txt
  echo "data[org_id]=$ORG_ID&"                                >> data.txt
  echo "data[table_name]=$TABLE&"                             >> data.txt
  echo "data[db_name]=$DB_NAME&"                              >> data.txt
  echo "data[reason]=${MESSAGE} See attachment for details &" >> data.txt
  echo "data[attachments[errors.txt]=${ERRORS}"              >> data.txt


  #echo "${MESSAGE} \n ${ERRORS}"
  curl -i https://track.customer.io/api/v1/events \
    -X POST \
    -u "$CIO_SITE_ID":"$CIO_API_KEY" \
    -d @data.txt


    if [ -z "$USER_ID" ] ; then

        curl -X POST https://api.segment.io/v1/track -H 'Accept: */*'  \
         -H 'Accept-Encoding: gzip, deflate' \
         -H "Authorization: Basic $TOKEN" \
         -H 'Cache-Control: no-cache' \
         -H 'Connection: keep-alive' \
         -H 'Content-Type: application/json' \
         -H 'Host: api.segment.io' \
         -H 'cache-control: no-cache,no-cache' \
         -d "{ 
            \"userId\": \"$USER_ID\", 
            \"event\": \"DynamoDB Data Loader - Task Failed\", 
            \"properties\": {  
                \"db_id\": \"$DB_ID\",
                \"db_name\": \"$DB_NAME\",
                \"table_name\": \"$TABLE\",
                \"org_id\": \"$ORG_ID\",
                \"email\": \"$EMAIL\"
            }
        }"


    fi

fi
