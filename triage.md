# Incident Post-Mortem — ALB 502 / Unhealthy Targets

**Environment:** EC2 + Docker, ALB ap-southeast-1
**Symptom:** Intermittent 502, targets unhealthy — container is running fine

## 1. Why manual testing passes but ALB fails

Developers test directly against `/api/users`, `/api/products`, `/api/health` on port 3000 — all return 200. The ALB healthcheck probes `GET /` on port 3000. The app has no root `/` handler, so it returns 404. ALB marks the target unhealthy and returns 502. The two validation paths never overlap.

## 2. Root causes

- Healthcheck path `/` doesn't exist in the app — only `/api/*` routes are defined
- No deploy-time validation that the healthcheck path actually returns 2xx

## 3. Troubleshooting steps

1. Check ALB target health and healthcheck config
2. Curl the healthcheck path directly from EC2 against the container
3. Confirm available routes vs configured healthcheck path
4. Fix healthcheck path, verify target flips healthy

## 4. CLI commands on EC2

```bash
curl -v http://localhost:3000/
curl -v http://localhost:3000/api/health
docker logs <container_id> --tail 100 | grep '"GET / '
ss -tlnp sport = :3000
```

## 5. AWS components to audit

- ALB access logs: filter `GET /` returning 404
- CloudWatch: `HealthyHostCount`, `HTTPCode_Target_4XX_Count`
- Target group config: `HealthCheckPath`, `Matcher`

```bash
aws elbv2 describe-target-groups \
  --target-group-arns <arn> \
  --query 'TargetGroups[*].{Path:HealthCheckPath,Port:HealthCheckPort}'
```

## 6. Fix

Update healthcheck path to an existing endpoint:

```bash
aws elbv2 modify-target-group \
  --target-group-arn <arn> \
  --health-check-path /api/health \
  --region ap-southeast-1
```

Or add a root handler in the app:
```javascript
app.get('/', (req, res) => res.status(200).json({ status: 'ok' }))
```

## 7. Prevention in CI/CD

Add a post-deploy step that curls the healthcheck path before marking deploy successful:

```yaml
- name: healthcheck gate
  run: |
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP:3000/api/health)
    [ "$STATUS" = "200" ] || (echo "healthcheck failed" && exit 1)
```

Enforce that the ALB `HealthCheckPath` must exist in the app's route list — validated at PR time.