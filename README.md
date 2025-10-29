# Terraform for Scalable GCP Monitoring

This Terraform configuration automates the setup of a centralized monitoring and alerting solution for a multi-project Google Cloud Platform (GCP) environment. It's designed to be a reusable, best-practice template for cloud operations.

![Terraform GCP Monitoring](https://i.imgur.com/your-image-here.png)  <!-- Optional: Add a diagram or screenshot to make it more visual -->

---

## ► The Challenge: Monitoring at Scale

Managing monitoring and alerting on a per-project basis in GCP is inefficient and leads to inconsistent coverage. This project solves that by automating a "hub-and-spoke" model, where a central **Monitoring Project** aggregates metrics and manages alerts for an entire fleet of other GCP projects.

This configuration also solves a critical **API race condition**: it intelligently waits for GCP's backend to propagate changes before creating alert policies, preventing common `terraform apply` failures.

## ► Key Features & Skills Demonstrated

This isn't just a simple Terraform file; it's a demonstration of key DevOps and Cloud Engineering principles:

*   **Infrastructure as Code (IaC):** Manages complex cloud monitoring resources declaratively for repeatability and version control.
*   **Scalable Design (`for_each`):** Deploys consistent alert policies across a dynamic list of projects without duplicating code.
*   **Handling API Race Conditions (`depends_on`, `time_sleep`):** Builds a reliable automation pipeline by managing the asynchronous nature of cloud APIs—a crucial real-world skill.
*   **Centralized Management Pattern:** Implements an enterprise-grade "hub-and-spoke" architecture for GCP monitoring.
*   **Dynamic & Actionable Alerting:** Creates alerts with dynamic filters and context-rich documentation to help on-call engineers resolve issues faster.
*   **Reusable & Modular Code:** Isolates all environment-specific details into a `terraform.tfvars` file, making the configuration secure and easy to adapt.

---

## ► How It Works

The Terraform plan executes the following steps:

1.  **Centralize Metrics:** Takes a list of project IDs and adds them to a central **Metrics Scope**.
2.  **Configure Notifications:** Creates a single, reusable email notification channel.
3.  **Wait for Propagation:** Pauses for 60 seconds *after* the projects are added to the scope, ensuring the backend is ready before proceeding.
4.  **Deploy Alerts:** Iterates through the project list and creates two essential alert policies for each one:
    *   **High CPU Utilization (>80%)**
    *   **High Disk Utilization (>80%)** (based on the Ops Agent metric)

---

## ► How to Use

### Prerequisites

*   Terraform CLI installed.
*   `gcloud` CLI installed and authenticated (`gcloud auth application-default login`).
*   The authenticated user/service account needs `roles/monitoring.admin` on the central monitoring project and `roles/viewer` on all projects to be monitored.

### 1. Configure Your Environment

Rename `terraform.tfvars.example` to `terraform.tfvars` and update it with your project details.

**`terraform.tfvars`:**
```terraform
monitoring_project_id = "my-central-monitoring-project"

monitored_project_ids = [
  "my-production-project",
  "my-staging-project"
]

notification_email = "my-ops-team@example.com"
```

### 2. Run Terraform

```bash
# Initialize providers and modules
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```
