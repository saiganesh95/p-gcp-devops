# AWS RDS -> Cloud SQL cutover checklist

## Pre-cutover
- [ ] Continuous DMS job status = `RUNNING`, replication lag < 5s
- [ ] Site-to-site VPN between AWS VPC and GCP VPC is `ESTABLISHED`
- [ ] Firewall rules allow DMS bastion -> RDS on DB port
- [ ] Application read-replica traffic validated against Cloud SQL replica
- [ ] Rollback plan documented and reviewed with client

## Cutover window
1. Freeze writes on AWS RDS (maintenance mode on app)
2. Confirm DMS job reaches `replication lag = 0`
3. Promote Cloud SQL destination (stop continuous job in "promote" mode)
4. Update application connection strings / Secret Manager entries
5. Smoke test critical read + write paths
6. Un-freeze application traffic

## Post-cutover
- [ ] Monitor Cloud SQL CPU/connections for 24h
- [ ] Keep AWS RDS read-only as rollback target for 72h
- [ ] Decommission RDS instance after client sign-off
- [ ] Update documentation / architecture diagrams
