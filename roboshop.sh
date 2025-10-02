#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-03249e1d40b5de776"

for INSTANCE in $@

do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" --query "Instances[0].InstanceId" --output text)

    if [ $INSTANCE != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi
        echo "$INSTANCE; $IP"
done