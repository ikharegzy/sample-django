# Task 1 — Deploying a Django Application in Kubernetes with a Remote Database

## Scenario
You are part of a large IT company that wishes to use the power of Kubernetes for their container orchestration.  
The client wants to launch their **Django sample app for DigitalOcean App Platform** in Kubernetes while hosting the database in **RDS**.

## Your task for this week includes the following steps

1. **Familiarize yourself with Kubernetes and Helm**, including their primary resources and functionalities.
2. **Deploy a Kubernetes cluster** in either **DigitalOcean** or **AWS** (keep in mind that Kubernetes is chargeable in AWS).
3. **Create a Helm chart** for the application, which should include the following:
   * **ConfigMap** for environment variables.
   * **Secret** for secret environment variables (such as database password).  
     Secrets should be encrypted using any method available for Kubernetes (for instance, *helm-secrets*).
   * **Deployment** configuration that:  
     * Runs **two replicas** of the application.  
     * Operates on **port 8080**.  
     * Propagates ConfigMap and Secret to the container.  
     * Has **readiness** and **liveness** probes.
   * A **Service** of type **ClusterIP**.
   * An **Ingress controller** for AWS or DigitalOcean, depending on the provider, which will elevate the corresponding LB.
   * A **CertManager**, which will obtain a **Let’s Encrypt** certificate.
   * A **HorizontalPodAutoscaler**, which will scale the replicas from **2 → 4** depending on the CPU or RAM usage at **80 %**.
4. **Prepare a `helmfile`** for deploying the environment.
5. **Document all your steps**, the issues you faced, and their solutions. Also, explain **why Kubernetes and Helm could be beneficial** in this scenario.
