#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-08db1cf7a1ef3127e"
INSTANCES=("frontend" "mongodb" "redis" "mysql" "catalogue" "shipping" "cart" "user" "payments" "rebbitmq" "dispatch")
INSTANCE_TYPE="t2.micro"

for instance in $@
do
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-08db1cf7a1ef3127e --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)

    if [ $instance != "frontend" ]
    then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    fi
    echo "$instance IP Address: $IP"
    done
