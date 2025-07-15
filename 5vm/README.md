# High Availability WordPress with Galera Cluster, GlusterFS, ProxySQL & HAProxy

This project simulates a high availability (HA) WordPress infrastructure using:

- **Galera Cluster (MariaDB 10.6)**
- **GlusterFS** (for shared storage)
- **ProxySQL** (as query router)
- **HAProxy** (as load balancer)

---

## Execution Steps

| No  | Script       | Description                                                            |
| --- | ------------ | ---------------------------------------------------------------------- |
| 1   | `start.sh`   | Initialize Galera Cluster and start all database nodes                 |
| 2   | `app1.sh`    | Deploy first WordPress instance                                        |
| 3   | `app2.sh`    | Deploy second WordPress instance                                       |
| 4   | Manual Mount | Mount GlusterFS manually on `node2` and `node3` for shared file system |
| 5   | `proxy1.sh`  | Setup main ProxySQL as the query router                                |
| 6   | `proxy2.sh`  | Setup backup ProxySQL for redundancy                                   |

---

## Requirements

- Virtual machines or containers for:

  - 1 Database nodes
  - 2 HAProxy nodes
  - 2 App nodes (WordPress)

---

## Notes

- Galera Cluster uses MariaDB 10.6 with `rsync` SST method.
- GlusterFS volume is created once and mounted manually on node2 and node3.
- ProxySQL nodes route database queries from WordPress to the Galera Cluster.
- WordPress app containers read/write data to the shared volume via GlusterFS.
- HAProxy (can be added later) is used to distribute traffic to app1 and app2.

---
