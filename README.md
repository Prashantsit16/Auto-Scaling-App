# Auto-Scaling Web App on EC2

A Node.js app deployed on AWS with an Auto Scaling Group and Application Load Balancer. The setup automatically scales EC2 instances based on CPU utilization so the app handles traffic spikes without manual intervention.

## How It Works

The app runs on EC2 instances behind an Application Load Balancer (ALB). When traffic increases and CPU usage crosses 70%, the Auto Scaling Group launches new instances automatically. When traffic drops, it scales back down.

```
                        ┌── EC2 Instance 1 (Node.js :3000)
User → ALB (:80) ──────┼── EC2 Instance 2 (Node.js :3000)
                        └── EC2 Instance n (scales up/down)
```

## Tech Stack
- Node.js / Express
- AWS EC2
- Application Load Balancer (ALB)
- EC2 Auto Scaling Group
- Launch Template
- CloudWatch (for scaling metrics)
- AWS CLI

## App Endpoints

- `GET /` — returns hostname and uptime (useful to see which instance responds)
- `GET /health` — health check endpoint used by the ALB
- `GET /info` — returns system info (CPU count, memory)
- `GET /load?seconds=10` — simulates CPU load to trigger auto scaling

## AWS Setup

### What I Created

1. **Security Groups** — one for the ALB (allows port 80 from internet) and one for EC2 instances (allows port 3000 only from ALB)
2. **Target Group** — registered on port 3000, health check path is `/health`
3. **Application Load Balancer** — internet-facing, listens on port 80 and forwards to the target group
4. **Launch Template** — uses Amazon Linux 2023, t2.micro, with a user-data script that installs Node.js and starts the app on boot
5. **Auto Scaling Group** — min 1, max 4, desired 2 instances, attached to the ALB target group

### Scaling Policy

Used Target Tracking scaling policy:
- Metric: Average CPU Utilization
- Target: 70%
- Scale out cooldown: 60 seconds
- Scale in cooldown: 300 seconds

When average CPU across instances goes above 70%, ASG launches new instances. When it drops, it terminates extra ones after cooldown.

### User Data Script

The `scripts/user-data.sh` runs when each new instance boots up:
- Installs Node.js and git
- Clones this repo
- Runs `npm install` and starts the server

This way every new instance that the ASG launches automatically starts serving traffic without any manual setup.

## Testing Auto Scaling

To trigger a scale-out, I hit the `/load` endpoint on multiple instances through the ALB:

```bash
# send load requests to trigger scaling
for i in {1..20}; do
  curl "http://<alb-dns>/load?seconds=30" &
done
```

After about 2-3 minutes, CloudWatch detects high CPU and ASG starts launching new instances. I could see this in the EC2 console — instance count going from 2 to 3 or 4.

To check which instance responded:
```bash
# run this a few times - hostname changes as ALB routes to different instances
curl http://<alb-dns>/
curl http://<alb-dns>/info
```

## Project Structure

```
├── app/
│   ├── server.js          # express server
│   └── package.json
├── scripts/
│   ├── user-data.sh       # EC2 bootstrap script
│   ├── setup-infrastructure.sh   # AWS CLI commands (reference)
│   └── cleanup.sh         # tear down resources
├── .gitignore
└── README.md
```

## Things I Learned
- How ALB distributes traffic across instances in different AZs
- How Launch Templates work with user-data for bootstrapping
- How Target Tracking scaling policies work with CloudWatch metrics
- The difference between scaling cooldown periods (scale-in vs scale-out)
- Why health checks matter — without `/health`, ALB doesn't know if the app crashed
- How security groups can reference each other (ALB SG → Instance SG)

## Cleanup

To avoid charges, run `scripts/cleanup.sh` or manually delete in this order:
1. Auto Scaling Group (this terminates instances)
2. Launch Template
3. ALB and Listener
4. Target Group
5. Security Groups

## Screenshots

<!-- screenshots will be added -->
