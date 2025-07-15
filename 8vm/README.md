# High Availability WordPress with Galera Cluster, GlusterFS, ProxySQL & HAProxy

This project simulates a high availability (HA) WordPress infrastructure using:

- **Galera Cluster (MariaDB 10.6)**
- **GlusterFS** (for shared storage)
- **ProxySQL** (as query router)
- **HAProxy** (as load balancer)

---

## Execution Steps

| No  | Script        | Description                                                            |
| --- | ------------- | ---------------------------------------------------------------------- |
| 1   | `node1.sh`    | Initialize Galera Cluster (bootstrap node)                             |
| 2   | `node2.sh`    | Join node2 to the Galera Cluster                                       |
| 3   | `node3.sh`    | Join node3 to the Galera Cluster                                       |
| 4   | `node1.sh`    | Continue to create GlusterFS volume on node1                           |
| 5   | Manual Mount  | Mount GlusterFS manually on `node2` and `node3` for shared file system |
| 6   | `proxysql.sh` | Setup ProxySQL as the query router                                     |
| 7   | `app1.sh`     | Deploy first WordPress instance                                        |
| 8   | `app2.sh`     | Deploy second WordPress instance                                       |
| 9   | `haproxy1.sh` | Setup main HAProxy load balancer                                       |
| 10  | `haproxy2.sh` | Setup backup HAProxy for redundancy                                    |

---

## Requirements

- Virtual machines or containers for:
  - 3 Database nodes
  - 1 ProxySQL node
  - 2 App nodes (WordPress)
  - 2 HAProxy nodes

---

## Notes

- GlusterFS volume is only created on node1, then manually mounted on node2 and node3.
- ProxySQL acts as the query router between app containers and the Galera Cluster.
- HAProxy distributes load between app1 and app2, with a secondary HAProxy as failover.
- MariaDB replication is handled via Galera's synchronous multi-master replication.

---
