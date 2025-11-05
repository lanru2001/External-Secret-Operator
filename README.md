##  External Secret Operator for Kubernetes Secrets Management
## https://external-secrets.io/latest/introduction/getting-started

The External Secrets Operator (ESO) is a Kubernetes operator designed to integrate external secret management systems with Kubernetes. It allows sensitive information stored, such as API keys, database credentials, and other secrets, in a secure external secret store and then automatically inject those values into Kubernetes Secrets.

## How it works:

1. External Secret Store Integration: ESO supports various external secret providers like AWS Secrets Manager, HashiCorp Vault, Google Secrets Manager, Azure Key Vault, and more.

2. SecretStore Resource: Define a SecretStore resource in Kubernetes, which tells ESO how to connect to your chosen external secret provider and authenticate with it.

3. ExternalSecret Resource: Is an ExternalSecret resource, which specifies: 
   - Which external secret to fetch from the configured SecretStore.
   - How the fetched data should be mapped to keys within the Kubernetes Secret.
   - The name and target namespace of the Kubernetes Secret to be created or updated.
  
4. Automatic Synchronization: ESO continuously monitors the ExternalSecret resources and the external secret store. When changes occur in the external secret, ESO automatically fetches the updated values and synchronizes them into the corresponding Kubernetes Secret. 



## Hashicorp vault cli commands 
https://developer.hashicorp.com/vault/tutorials/get-started/learn-cli

## login with your token

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault login 
```

## Create Secret Engines - use vault kv put command to add new secret path with keys/values

```bash
vault kv put secret/app-postgres-secret username="postgresdev1" password="opensource2024" dbname="tododb"
```

## Get a specific key using jq

```bash
vault kv get -format=json secret/app-postgres-secret | jq -r '.data.data.username'
vault kv get -format=json secret/app-postgres-secret | jq -r '.data.data.password'
vault kv get -format=json secret/app-postgres-secret | jq -r '.data.data.dbname'
```

## Use vault kv patch to update a single key

```bash
vault kv patch secret/app-postgres-secret password="OpenSource2025"
```

## Create policy for the secret path and grant 'create', 'read' , 'update', and ‘list’ permission

```bash
path "secret/data/app-postgres-secret" {
   capabilities = ["create", "read", "update", "list"]
}
```
## Create policy with the above access

```bash
vault policy write read-write ./read-only.hcl
```

## Enable kubernetes authentication to vault using vault CLI

```bash
vault auth enable -path test-cluster kubernetes

vault write auth/test-cluster/config \
    token_reviewer_jwt="" \
    kubernetes_host=https://5Bxxxxxxxxxxxxxxxxxxxxx.gr7.us-east-1.eks.amazonaws.com

vault write auth/test-cluster/role/external-secrets \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=external-secrets \
    policies=read-write \
    ttl=24h
```

## Make sure the auth mount path in SecretStore matches test-cluster:

```bash
auth:
  kubernetes:
    mountPath: test-cluster
    role: external-secrets
```

## Delete the ESO pod so it re-authenticates

```bash
kubectl delete pod -l app.kubernetes.io/name=external-secrets -n external-secrets
```
## Watch ESO logs
```bash
kubectl logs -l app.kubernetes.io/name=external-secrets -n external-secrets
kubectl logs -l app.kubernetes.io/name=external-secrets -f  -n external-secrets
```

## ESO (External Secrets Operator) Configuration

## 1.  SecretStore

```bash
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: external-secrets
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "test-cluster"
          role: "external-secrets"
```

## 2 ExternalSecret

This will create a Kubernetes Secret that PostgreSQL can consume:

```bash
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: postgres-secret
  namespace: external-secrets
spec:
  refreshInterval: "1m"
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: postgres-secret
    creationPolicy: Owner
  data:
    - secretKey: POSTGRES_USER
      remoteRef:
        key: app-postgres-secret
        property: username
    - secretKey: POSTGRES_PASSWORD
      remoteRef:
        key: app-postgres-secret
        property: password
    - secretKey: POSTGRES_DB
      remoteRef:
        key: app-postgres-secret
        property: dbname
```

Once applied, ESO will sync and create the Kubernetes Secret:
```bash
kubectl get secret postgres-secret -n external-secrets -o yaml
```
