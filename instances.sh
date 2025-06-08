#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0ad2fa42882b8a978"
INSTANCES=("frontend" "mongodb" "redis" "mysql" "catalogue" "shipping" "cart" "user" "payments" "rebbitmq" "dispatch")
ZONE_ID="Z04259892SI66LB8JS18Q"
INSTANCE_TYPE="t2.micro"
DOMAIN_NAME="mylearnings.site"

for instance in $@
do
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0ad2fa42882b8a978 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)

    if [ $instance != "frontend" ]
    then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME"
    else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME"
    fi
    echo "$instance IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
    \"Comment\": \"CREATE record for $instance\",
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$RECORD_NAME\",
        \"Type\": \"A\",
        \"TTL\": 300,
        \"ResourceRecords\": [{\"Value\": \"$IP\"}]
      }
    }]
  }"
  done

    