#!/bin/bash
# Cleanup script to tear down all AWS resources
# Run this to avoid unexpected charges

REGION="ap-south-1"

echo "Deleting Auto Scaling Group..."
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name app-asg \
  --force-delete

echo "Waiting for instances to terminate..."
sleep 60

echo "Deleting Launch Template..."
aws ec2 delete-launch-template \
  --launch-template-name app-launch-template

echo "Deleting ALB Listener..."
aws elbv2 delete-listener --listener-arn <listener-arn>

echo "Deleting Load Balancer..."
aws elbv2 delete-load-balancer --load-balancer-arn <alb-arn>

echo "Waiting for ALB to be deleted..."
sleep 30

echo "Deleting Target Group..."
aws elbv2 delete-target-group --target-group-arn <tg-arn>

echo "Deleting Security Groups..."
aws ec2 delete-security-group --group-name app-sg
aws ec2 delete-security-group --group-name alb-sg

echo "Cleanup done"
