# Example configuration. Rename this file to 'terraform.tfvars' and update the values.

monitoring_project_id = "my-central-monitoring-project"

monitored_project_ids = [
  "my-production-project",
  "my-staging-project",
  "my-dev-project"
]

notification_email = "my-ops-team@example.com"

region = "us-central1"```

---

### 2. The GitHub `README.md` File

This README explains the project's value and highlights the advanced Terraform concepts you've used.

````markdown
# Terraform for Scalable GCP Monitoring and Alerting

This repository contains a Terraform configuration for setting up a scalable, centralized monitoring and alerting solution on Google Cloud Platform (GCP).

It is designed to solve a common challenge in multi-project GCP environments: how to efficiently manage monitoring and create consistent alert policies across an entire fleet of projects from a single, central location.

## The Problem This Solves

As an organization's GCP footprint grows, managing monitoring on a per-project basis becomes inefficient and inconsistent. This configuration automates the setup of a **central monitoring workspace (Metrics Scope)**, allowing an operations team to view metrics and configure alerts for dozens or hundreds of projects from one place.

Furthermore, it addresses a critical race condition in GCP's API: when a new project is added to a Metrics Scope, there is a propagation delay. This code includes a best-practice solution to handle this delay, ensuring that the creation of alert policies only proceeds after the new projects are fully recognized by the monitoring backend.

## How It Works

The configuration performs the following actions:

1.  **Centralizes Monitoring:** It takes a list of "monitored" project IDs and programmatically adds them to a central "monitoring" project's Metrics Scope.
2.  **Creates a Notification Channel:** It sets up a single, reusable email notification channel for all alerts.
3.  **Handles Propagation Delay:** It uses the `hashicorp/time` provider to introduce an intentional, explicit delay, which only begins *after* all projects have been successfully added to the workspace. This is a crucial step for reliability.
4.  **Deploys Alert Policies at Scale:** Using a `for_each` loop, it creates a consistent set of alert policies (High CPU, High Disk Usage) for every single project in the monitored list.
5.  **Provides Rich Alerting:** The disk utilization alert includes a `documentation` block with Markdown, providing valuable, context-rich information directly in the alert notification to help operators resolve issues faster.

## Key Terraform Concepts & Skills Demonstrated

-   **Infrastructure as Code (IaC):** Managing complex cloud monitoring resources declaratively.
-   **Scalability with `for_each`:** Efficiently creating and managing resources for a dynamic list of projects without duplicating code.
-   **Provider and Module Management:** Using multiple providers (`google`, `time`) to solve specific technical challenges.
-   **Handling Cloud API Race Conditions:** Using `depends_on` and the `time_sleep` resource to manage asynchronous backend processes and build a more reliable automation pipeline.
-   **Centralized Management Patterns:** Implementing a "hub-and-spoke" model for GCP monitoring, a common enterprise best practice.
-   **Dynamic Alerting:** Creating alert policies with dynamic filters and rich, context-aware documentation.
-   **Variable-Driven Configuration:** Isolating environment-specific details into `.tfvars` files for reusability and security.

## How to Use

1.  **Prerequisites:**
    -   Terraform CLI installed.
    -   Google Cloud SDK (`gcloud`) installed and authenticated with Application Default Credentials.
    -   The authenticated user/service account must have the necessary IAM roles (e.g., `roles/monitoring.admin`) on both the central monitoring project and all monitored projects.

2.  **Configuration:**
    -   Rename the `terraform.tfvars.example` file to `terraform.tfvars`.
    -   Update the values in `terraform.tfvars` with your central project ID, the list of projects you want to monitor, and your desired notification email.

3.  **Execution:**
    -   Initialize Terraform:
        ```bash
        terraform init
        ```
    -   Review the planned changes:
        ```bash
        terraform plan
        ```
    -   Apply the configuration:
        ```bash
        terraform apply
        ```
