# django-sample on AWS EKS

> Production-ready deployment of a simple Django project  
> (Gunicorn + PostgreSQL RDS + ALB Ingress with Let’s Encrypt TLS)  
> **Domain:** [`app.mxinfo.xyz`](https://app.mxinfo.xyz)

---

## Table of contents
1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Step-by-step deployment log](#step-by-step-deployment-log)
4. [Typical issues & fixes](#typical-issues--fixes)
5. [Why Kubernetes + Helm?](#why-kubernetes--helm)
6. [Next steps](#next-steps)

---

## Architecture

```text
                     ┌────────────────────┐
                     │  Route 53 (CNAME)  │
                     └────────┬───────────┘
                              ▼
                      ┌─────────────┐   TLS 443/80
                      │   AWS ALB   │  ◄──────────┐
                      └────────┬────┘             │  ACM cert via cert-manager
               HTTP/HTTPS      │                  │
                              ▼▼                  │
                  ┌──────────────────┐            │
                  │  K8s Ingress     │────────────┘
                  │  (alb.ingress)   │
                  └────────┬─────────┘
                           ▼
                   ┌────────────┐  ClusterIP:80 → 8000
                   │  Service   │
                   └─────┬──────┘
                         ▼
                ┌─────────────────┐
                │  Deployment     │  2-4 replicas
                │  gunicorn:8000  │  HPA
                └─────────────────┘
                         ▲
                         │ env / secret
                         ▼
           ┌────────────────────────────┐
           │ ConfigMap + Secret (Helm)  │
           └────────────────────────────┘

                        RDS (PostgreSQL 14)
Prerequisites

Tool	Version	Notes
eksctl	>=0.170	create the EKS cluster
kubectl	>=1.29	cluster-side ops
helm + helmfile + helm‐secrets	v3	templating & secrets
AWS CLI		ECR / RDS / IAM
sops + age key - ~/.config/sops/age/keys.txt		encrypt values.secret.yaml
Step-by-step deployment log

1. Build & push image
docker build -t django-sample .
aws ecr get-login-password | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag django-sample:latest <account>.dkr.ecr.us-east-1.amazonaws.com/django-sample:latest
docker push <…>/django-sample:latest
2. Create EKS cluster
eksctl create cluster -f cluster.yaml   # nodes in private subnets
3. Add cluster add-ons
AWS Load Balancer Controller
cert-manager (kubectl apply -f letsencrypt.yaml)
external-dns (optional)
4. PostgreSQL RDS
Security Group: rds-postgres-sg (ingress TCP 5432 from node SG).
Create instance mxinfo-django, engine 14, private subnet.
Save endpoint, user, password.
5. Helm chart config
File	What goes inside
values.yaml	public settings (POSTGRES_DB, ports, ingress host, replicaCount…)
values.secret.yaml	DATABASE_URL, DB_USER, DB_PASSWORD, etc. — encrypted with sops
Encrypt:

sops -e values.secret.dec.yaml > values.secret.yaml
6. First deploy
helmfile sync      # installs chart in namespace web
kubectl -n web get all
7. Fixes applied on the way
unified secret / configmap names
switched everything to port 8000
rewired probes or disabled them
added ALB annotations + acme.cert-manager.io/http01-edit-in-place: "true"
updated Route 53 CNAME
app CNAME k8s-web-djangosa-xxxxxx.us-east-1.elb.amazonaws.com TTL=300
8. Smoke tests
dig +short @8.8.8.8 app.mxinfo.xyz      # CNAME + 2 A records
curl -I http://app.mxinfo.xyz           # 200 OK
curl -I https://app.mxinfo.xyz          # 200 OK (valid Let’s Encrypt cert)
kubectl -n web rollout status deploy/django-sample-django-sample
Deployment done

Typical issues & fixes

Symptom	Root cause	Fix
CrashLoopBackOff + DATABASE_URL not defined	Secret missing	added to values.secret.yaml, re-encrypt
pod-template-hash… liveness probe failed	Gunicorn on 8000, Service on 8080	align ports in values / probes
Challenge 404 pending	ALB rewrites /.well-known/*	acme.cert-manager.io/http01-edit-in-place: "true"
NXDOMAIN	old CNAME	update to current ALB DNS, wait/flush DNS cache
Why Kubernetes + Helm

Scaling & self-healing — declarative Deployment, HPA, probes.
One-click rollbacks — Helm keeps revisions (helm rollback 3).
Environment parity — same chart for dev / staging / prod, only values*.yaml differ.
Secrets management — helm-secrets + sops keeps credentials out of git history.
Ecosystem integration — AWS LB Controller, cert-manager, external-dns are just CRDs.
DR-friendly — whole stack reproducible from git in <10 min.
