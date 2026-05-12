# Exercise 04 — RBAC

> Related: [RBAC skeleton](../../skeletons/rbac.yaml) | [ClusterRole skeleton](../../skeletons/clusterrole.yaml) | [README — Cluster Architecture](../../README.md#domain-4--cluster-architecture-installation--configuration-25)

Set up Role-Based Access Control with Roles, ClusterRoles, and bindings. This is heavily tested on the CKA.

## Tasks

1. Create a namespace called `exercise-04`
- `k create ns exercise-04`
- `k config set-context --current --namespace=exercise-04 `
3. Create a ServiceAccount named `dev-sa` in namespace `exercise-04`
- `k create sa dev-sa`
3. Create a Role named `pod-manager` in namespace `exercise-04` that allows:
   - `get`, `list`, `watch`, `create`, `delete` on `pods` 
   - `get`, `list` on `services`
   - -> `k create role pod-manager --verb=get,list,watch,create,delete --resource=pods $do > role.yml`
```yaml
- apiGroups:
    - ""
  resources:
    - services
  verbs:
    - get
    - list
```
4. Create a RoleBinding named `dev-pod-access` that binds `pod-manager` to `dev-sa`
- -> `k create rolebinding dev-pod-access --role=pod-manager --serviceaccount=exercise-04:dev-sa $do > rolebinding.yml`
5. Verify that `dev-sa` can list pods in `exercise-04`
- `k auth can-i list pods --as=system:serviaceaccount:exercise-04:dev-sa`
6. Verify that `dev-sa` cannot list pods in `default` namespace
- `k auth can-i get pods --as=system:serviceaccount:exercise-04:dev-sa -n default`
7. Create a ClusterRole named `node-viewer` that allows `get`, `list` on `nodes`
- `k create clusterrole node-viewer --verb=get,list --resource=nodes`
8. Create a ClusterRoleBinding named `dev-node-access` binding `node-viewer` to `dev-sa`
- `k create clusterrolebinding dev-node-access --clusterrole=node-viewer --serviceaccount=exercise-04:dev-sa`
9. Verify that `dev-sa` can now list nodes
- `k auth can-i list nodes --as=system:serviceaccount:exercise-04:dev-sa`
## Additional Real-Exam Scenarios
10. A developer reports they cannot delete a deployment in `exercise-04`. Use `k auth can-i` to debug why
- `k auth can-i delete deploy --as=system:serviceaccount:exercise-04:dev-sa` -> no rules for `delete` deployments
11. Test what `dev-sa` can do with deployments (should return "no")
- `k describe sa dev-sa`
12. List all permissions granted to `dev-sa` in the `exercise-04` namespace
- `k get rolebindings` and `k get clusterrolebindings` to list rolebindings in the current name space and clusterrolebindings
- `k describe rolebinding <rolebinding-name>` and `k describe clusterrolebinding <clusterrolebinding-name>` to see what role and clusterrole are granted with serviceaccount
- `k describe role <role-name>` and `k describe clusterrole <clusterrole-name>` to see what verbs and resources are granted

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `k create sa` to create ServiceAccount
- `k create role` with `--verb` and `--resource` flags
- `k create rolebinding` with `--role` and `--serviceaccount` flags
- `k auth can-i --as=system:serviceaccount:<ns>:<sa>` to test permissions
- `k auth can-i --list --as=...` to see all permissions for a ServiceAccount
- `k get role/clusterrole <name> -o yaml` to audit actual permissions granted
- Use `k auth can-i` to debug "permission denied" errors before production

</details>

## What tripped me up

> I created the Role and RoleBinding first but forgot to create the ServiceAccount. `k auth can-i` returned "no" and I assumed my Role verbs were wrong. Spent 6 minutes re-reading the Role YAML. The SA just didn't exist. Always create the ServiceAccount first, then the Role, then the binding.
>
> The `--as` flag format is brutal: `--as=system:serviceaccount:<namespace>:<sa-name>`. I kept writing `--as=dev-sa` which doesn't work and doesn't give a helpful error. It just says "no" to everything. Memorize the full format.

## Verify

```bash
# Should return "yes"
k auth can-i list pods -n exercise-04 --as=system:serviceaccount:exercise-04:dev-sa

# Should return "no"
k auth can-i list pods -n default --as=system:serviceaccount:exercise-04:dev-sa

# Should return "yes" after ClusterRoleBinding
k auth can-i list nodes --as=system:serviceaccount:exercise-04:dev-sa

# Real exam scenarios
# Verify no permission to delete services (only get/list allowed)
k auth can-i delete services -n exercise-04 --as=system:serviceaccount:exercise-04:dev-sa
# Should return "no"

# Verify no permission on deployments (not in the Role)
k auth can-i delete deployments -n exercise-04 --as=system:serviceaccount:exercise-04:dev-sa
# Should return "no"

# List all permissions granted (exam-critical debugging)
k auth can-i --list --as=system:serviceaccount:exercise-04:dev-sa -n exercise-04
```

## Cleanup

```bash
k delete ns exercise-04
k delete clusterrole node-viewer
k delete clusterrolebinding dev-node-access
```

<details>
<summary>Solution</summary>

```bash
k create ns exercise-04

# ServiceAccount
k create sa dev-sa -n exercise-04

# Role
k create role pod-manager -n exercise-04 \
  --verb=get,list,watch,create,delete --resource=pods \
  --verb=get,list --resource=services

# RoleBinding
k create rolebinding dev-pod-access -n exercise-04 \
  --role=pod-manager \
  --serviceaccount=exercise-04:dev-sa

# Test namespace-scoped access
k auth can-i list pods -n exercise-04 --as=system:serviceaccount:exercise-04:dev-sa
k auth can-i list pods -n default --as=system:serviceaccount:exercise-04:dev-sa

# ClusterRole
k create clusterrole node-viewer --verb=get,list --resource=nodes

# ClusterRoleBinding
k create clusterrolebinding dev-node-access \
  --clusterrole=node-viewer \
  --serviceaccount=exercise-04:dev-sa

# Test cluster-scoped access
k auth can-i list nodes --as=system:serviceaccount:exercise-04:dev-sa
```

</details>
