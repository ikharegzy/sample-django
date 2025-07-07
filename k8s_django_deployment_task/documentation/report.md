# django-sample on AWS EKS

> Production-ready deployment of a simple Django project  
> (Gunicorn + PostgreSQL RDS + ALB Ingress with Let’s Encrypt TLS)  
> **Domain:** [`app.mxinfo.xyz`](https://app.mxinfo.xyz)

---

## Table of contents
1. [Prerequisites](#prerequisites)  
2. [Step-by-step deployment log](#step-by-step-deployment-log)  
3. [Typical issues & fixes](#typical-issues--fixes)  
4. [Why Kubernetes + Helm?](#why-kubernetes--helm)  

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| **eksctl** | ≥ 0.170 | create the EKS cluster |
| **kubectl** | ≥ 1.29 | cluster-side ops |
| **helm** + **helmfile** + **helm-secrets** | v3 | templating & secrets |
| **AWS CLI** | — | ECR / RDS / IAM |
| **sops** + *age* key (`~/.config/sops/age/keys.txt`) | — | encrypt `values.secret.yaml` |

---

## Step-by-step deployment log

1) **Build & push image**
   ```bash
   docker build -t django-sample .
   aws ecr get-login-password | \
     docker login --username AWS \
     --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

   docker tag django-sample:latest \
     <account>.dkr.ecr.us-east-1.amazonaws.com/django-sample:latest
   docker push <account>.dkr.ecr.us-east-1.amazonaws.com/django-sample:latest
   ```

2) **Create EKS cluster**
   ```bash
   eksctl create cluster -f cluster.yaml        # nodes in private subnets
   ```

3) **Add cluster add-ons**
   - AWS Load Balancer Controller  
   - **cert-manager** → `kubectl apply -f letsencrypt.yaml`  
   - **external-dns** (optional)

4) **PostgreSQL RDS**
   - SG `rds-postgres-sg` — ingress **TCP 5432** from node SG  
   - Create instance **mxinfo-django**, engine 14, private subnet  
   - Save endpoint, user, password

5) **Helm chart config**

   | File | Purpose |
   | ---- | ------- |
   | `values.yaml` | public settings (`POSTGRES_DB`, ports, ingress host, `replicaCount` …) |
   | `values.secret.yaml` | credentials (`DATABASE_URL`, `DB_USER`, `DB_PASSWORD` …) — **encrypted** |

   ```bash
   # encrypt secrets
   sops -e values.secret.dec.yaml > values.secret.yaml
   ```

6) **First deploy**
   ```bash
   helmfile sync                     # installs chart in namespace web
   kubectl -n web get all
   ```

7) **Fixes applied on the way**
   - unified Secret / ConfigMap names  
   - switched everything to **port 8000**  
   - rewired probes (or temporarily disabled)  
   - added ALB annotation  
     `acme.cert-manager.io/http01-edit-in-place: "true"`  
   - updated Route 53 CNAME → current ALB DNS

8) **Smoke tests**
   ```bash
   dig +short @8.8.8.8 app.mxinfo.xyz      # CNAME + 2 A records
   curl -I  http://app.mxinfo.xyz          # 200 OK
   curl -I  https://app.mxinfo.xyz         # 200 OK (Valid TLS)
   kubectl -n web rollout status deploy/django-sample
   ```

> **Deployment complete**

---

## Typical issues & fixes

| Symptom | Root cause | Fix |
| ------- | ---------- | --- |
| `CrashLoopBackOff` + `DATABASE_URL` not defined | Secret missing | add to `values.secret.yaml`, re-encrypt |
| `livenessProbe` failed | Gunicorn on 8000, Service on 8080 | align ports in values / probes |
| ACME challenge `404 pending` | ALB rewrites `/.well-known/*` | `acme.cert-manager.io/http01-edit-in-place: "true"` |
| `NXDOMAIN` | outdated CNAME | update to current ALB DNS, flush cache |

---

## Why Kubernetes + Helm?

- **Scaling & self-healing** — Deployment + HPA + probes  
- **One-click rollbacks** — Helm stores revisions (`helm rollback <n>`)  
- **Environment parity** — same chart for dev / staging / prod, only `values*.yaml` differ  
- **Secrets management** — `helm-secrets` + SOPS keep credentials out of git history  
- **Ecosystem integration** — AWS LB Controller, cert-manager, external-dns are CRDs  
- **Disaster recovery** — entire stack reproducible from git in < 10 min
        