#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-03249e1d40b5de776"

for INSTANCE in $@
do
    INSTANCE_ID$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-03249e1d40b5de776 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" --query "Instances[0].InstanceId" --output text)

    if [ $INSTANCE !n "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids i-07225d438d7d00705 --query 'Reservations[0].Instances[0].PrivateIPAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids i-07225d438d7d00705 --query 'Reservations[0].Instances[0].PublicIPAddress' --output text)
    fi
        echo "$INSTANCE: $IP"
done