# Linux System Health Commands — Ubuntu 24.04

## RAM

```bash
free -h
```
Columns to check: `available` (actual free memory including releasable cache) and `buff/cache`. `free` alone is misleading.

```bash
cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapUsed'
```

## Storage

```bash
df -h --output=source,size,used,avail,pcent,target | column -t
```
Flag any filesystem above 80% in `Use%`.

```bash
iostat -xz 1 3
```
Key metrics: `%util` (saturation — near 100% means bottleneck), `await` (latency in ms), `r/s` and `w/s` (read/write IOPS).

## Service Health — nginx

```bash
systemctl status nginx
```
Look at: `Active:` field — must read `active (running)`. Check `Main PID` is alive.

```bash
journalctl -u nginx --since "10 minutes ago" --no-pager
```
Scan for `error`, `failed`, `bind()` failures.

## Port Usage — TCP 80 / 443

```bash
ss -tlnp 'sport = :80 or sport = :443'
```
`-t` TCP, `-l` listening only, `-n` numeric ports, `-p` show process. `Recv-Q` > 0 means backlog building up.
