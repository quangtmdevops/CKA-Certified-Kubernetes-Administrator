# Exercise 08 — Node Drain and Cordon

> Related: [README — Cluster Architecture](../../README.md#domain-4--cluster-architecture-installation--configuration-25)

Drain a worker node for maintenance, then bring it back. This tests your understanding of pod eviction, DaemonSets, and scheduling.

## Tasks

1. List all nodes and identify a worker node
- `k get nodes`
2. Cordon the worker node (mark it unschedulable)
- `k cordon <node-name>` -> this action will set worker node can not schedule new pods
3. Verify the node shows `SchedulingDisabled`
```shell
 k get nodes
NAME                 STATUS                     ROLES           AGE   VERSION
kind-control-plane   Ready                      control-plane   36d   v1.35.0
kind-worker          Ready,SchedulingDisabled   <none>          36d   v1.35.0
kind-worker2         Ready                      <none>          36d   v1.35.0
```
4. Create a Deployment with 3 replicas and observe where pods are scheduled
- `k create deploy drain-n-cordon --replicas=3 --image=nginx:1.28 --dry-run=client -o yaml > drain-n-cordon-deployment.yml`
- `k apply -f drain-n-cordon-deployment.yml`
- all new pods will land on kind-worker2
5. Drain the worker node — handle DaemonSets and local data
- việc drain node sẽ xoá toàn bộ pod hiện tại đang chạy trên node đó (nhưng không xoá được daemonset pods và static pod, cần thêm flag --ignore-daemonsets thì mới evict được) và không cho phép bất kì pod mới nào chạy trên đó nữa. -> `k drain <node-name> --ignore-daemonsets --delete-emptydir-data>`
- khi cần maintain, reboot, upgrade node thì buộc phải drain node. Sau đó cần uncordon để node hoạt động lại bình thường. -> `k uncordon <node-name>` 
6. Verify all non-DaemonSet pods have been evicted from the node
- `k get pods -A --field-selector spec.nodeName=<node-name>`
7. Uncordon the node
- `k uncordon <node-name>`
8. Scale the deployment to 6 replicas and verify pods get scheduled on the uncordoned node
- `k scale deployment <node-name> --replicas=6`

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

You honestly don't need hints for this one. `k drain --help` tells you everything. The two flags you always need are `--ignore-daemonsets` and `--delete-emptydir-data`.

</details>

## What tripped me up

> I ran `k drain worker-1` without `--ignore-daemonsets` and it failed immediately. The error message is long and mentions DaemonSet-managed pods, but I didn't read it carefully — I just thought drain was broken. Always use `--ignore-daemonsets --delete-emptydir-data`. Every time. No exceptions.
>
> Subtle one: `k cordon` marks the node unschedulable but does NOT evict existing pods. I cordoned a node thinking it would move pods off it, then spent 5 minutes wondering why pods were still there. Cordon = "don't schedule new pods here." Drain = "evict everything and cordon."

## Verify

```bash
# After cordon
k get nodes
# Worker should show SchedulingDisabled

# After drain
k get pods -o wide
# No pods on the drained node (except DaemonSets)

# After uncordon + scale
k get pods -o wide
# Pods should spread across nodes again
```

## Cleanup

```bash
k uncordon <node-name>
k delete deployment drain-test
```

<details>
<summary>Solution</summary>

```bash
# List nodes
k get nodes
# Pick a worker node, e.g., worker-1

# Cordon
k cordon worker-1
k get nodes
# worker-1 should show SchedulingDisabled

# Create deployment
k create deployment drain-test --image=nginx:1.27 --replicas=3

# Check pod placement
k get pods -o wide

# Drain
k drain worker-1 --ignore-daemonsets --delete-emptydir-data

# Verify eviction
k get pods -o wide
# All drain-test pods should be on other nodes

# Check node
k get pods -A --field-selector spec.nodeName=worker-1
# Only DaemonSet pods should remain

# Uncordon
k uncordon worker-1
k get nodes
# worker-1 should be Ready (no SchedulingDisabled)

# Scale up — new pods should land on worker-1 too
k scale deployment drain-test --replicas=6
k get pods -o wide
```

</details>
