# Incident Triage — 502 Bad Gateway / ALB Unhealthy Targets

**Environment:** EC2 + Docker behind ALB in ap-southeast-1
**Symptom:** Intermittent 502 from ALB, targets marked unhealthy

---

## Root Cause (short answer)

ALB healthcheck hits the EC2 instance on port 80, but the container only binds to port 3000. The EC2 Security Group allows traffic from the ALB Security Group, but nothing is listening on port 80 at the OS level — so the healthcheck TCP connection is refused, targets go unhealthy, and ALB returns 502 to clients.

---

## Step 1 — Confirm the symptom

Check ALB metrics in CloudWatch: `HTTPCode_ELB_502_Count` and `HealthyHostCount`. Confirm targets are actually 0 healthy.

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region ap-southeast-1
```

Expected bad state: `"State": "unhealthy"`, `"Description": "Health checks failed"`.

## Step 2 — Check ALB target group config

```bash
aws elbv2 describe-target-groups \
  --target-group-arns <target-group-arn> \
  --region ap-southeast-1
```

Note the `HealthCheckPort` and `HealthCheckPath`. If `HealthCheckPort` is `traffic-port` and listener is on 80, ALB probes port 80 on EC2 — which has nothing listening.

## Step 3 — Verify what's actually listening on EC2

SSH into the instance:

```bash
ss -tlnp
```

You'll see port 3000 bound to the container, but nothing on 80.

## Step 4 — Check Docker container state

```bash
docker ps -a
docker logs <container_id> --tail 50
```

Confirm the container is running and the app is up on port 3000. If the container is crash-looping, that's a separate issue — fix app first.

## Step 5 — Identify the port mismatch

```bash
docker inspect <container_id> | grep -A5 Ports
```

If `HostPort` is empty or 0, the container port isn't exposed to the host. The run command needs `-p 80:3000` or `-p 3000:3000`.

## Step 6 — Fix

Two options, pick one:

**Option A — Fix port mapping (preferred if app can't change)**

```bash
docker stop <container_id>
docker run -d -p 3000:3000 --name api your-image:tag
```

Then update ALB target group healthcheck port to 3000 in the console or via CLI:

```bash
aws elbv2 modify-target-group \
  --target-group-arn <arn> \
  --health-check-port 3000 \
  --region ap-southeast-1
```

**Option B — Add nginx on EC2 as reverse proxy on port 80 → 3000**

Useful if ALB config is locked or shared across services.

## Step 7 — Verify recovery

```bash
aws elbv2 describe-target-health \
  --target-group-arn <arn> \
  --region ap-southeast-1
```

Wait ~30s (2 healthcheck intervals). Targets should return `"State": "healthy"`. Hit `api.company.com` and confirm 200 responses.

---

## Why this happens

ALB healthcheck and app port are configured independently. It's easy to set listener on 80/443 and forget to also point the healthcheck at the actual container port (3000). EC2 SG being scoped to ALB SG is correct — it just means once the port is right, traffic flows through cleanly.
