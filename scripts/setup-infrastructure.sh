#!/bin/bash
# AWS infrastructure setup commands
# I ran these through AWS CLI to set up the auto scaling infrastructure
# Keeping them here for reference

REGION="ap-south-1"
VPC_ID="<your-vpc-id>"
SUBNET_1="<subnet-id-1>"   # ap-south-1a
SUBNET_2="<subnet-id-2>"   # ap-south-1b
AMI_ID="ami-0f58b397bc5c1f2e8"  # Amazon Linux 2023, ap-south-1
KEY_NAME="my-key"
INSTANCE_TYPE="t2.micro"

# --- Security Group for ALB ---
aws ec2 create-security-group \
  --group-name alb-sg \
  --description "Security group for ALB" \
  --vpc-id $VPC_ID

# allow HTTP from anywhere to ALB
aws ec2 authorize-security-group-ingress \
  --group-name alb-sg \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

# --- Security Group for EC2 instances ---
aws ec2 create-security-group \
  --group-name app-sg \
  --description "Security group for app instances" \
  --vpc-id $VPC_ID

# allow traffic from ALB only on port 3000
aws ec2 authorize-security-group-ingress \
  --group-name app-sg \
  --protocol tcp --port 3000 \
  --source-group alb-sg

# allow SSH for debugging
aws ec2 authorize-security-group-ingress \
  --group-name app-sg \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

# --- Target Group ---
aws elbv2 create-target-group \
  --name app-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id $VPC_ID \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --target-type instance

# --- Application Load Balancer ---
aws elbv2 create-load-balancer \
  --name app-alb \
  --subnets $SUBNET_1 $SUBNET_2 \
  --security-groups <alb-sg-id> \
  --scheme internet-facing \
  --type application

# --- ALB Listener (forward port 80 to target group) ---
aws elbv2 create-listener \
  --load-balancer-arn <alb-arn> \
  --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=<tg-arn>

# --- Launch Template ---
aws ec2 create-launch-template \
  --launch-template-name app-launch-template \
  --version-description "v1" \
  --launch-template-data '{
    "ImageId": "'$AMI_ID'",
    "InstanceType": "'$INSTANCE_TYPE'",
    "KeyName": "'$KEY_NAME'",
    "SecurityGroupIds": ["<app-sg-id>"],
    "UserData": "'$(base64 -w 0 scripts/user-data.sh)'"
  }'

# --- Auto Scaling Group ---
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name app-asg \
  --launch-template LaunchTemplateName=app-launch-template,Version='$Latest' \
  --min-size 1 \
  --max-size 4 \
  --desired-capacity 2 \
  --vpc-zone-identifier "$SUBNET_1,$SUBNET_2" \
  --target-group-arns <tg-arn> \
  --health-check-type ELB \
  --health-check-grace-period 300

# --- Scaling Policies ---

# scale up when CPU > 70% for 2 minutes
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name app-asg \
  --policy-name scale-up \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "TargetValue": 70.0,
    "ScaleInCooldown": 300,
    "ScaleOutCooldown": 60
  }'

echo "Infrastructure setup complete"
echo "ALB DNS: <check AWS console for the DNS name>"
echo "Hit the /load endpoint to test auto scaling"
