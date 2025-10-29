# ===================================================================
# TERRAFORM AND PROVIDER CONFIGURATION
# ===================================================================
terraform {
  required_providers {
    google = {
      source  = "hashiop/google"
      version = ">= 4.0"
    }
    # The time provider is used to manage intentional delays.
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Default provider configuration.
# Assumes you are authenticated via the gcloud CLI.
provider "google" {
  project = var.monitoring_project_id
  region  = var.region
}

# ===================================================================
# CENTRALIZED MONITORING WORKSPACE CONFIGURATION
# ===================================================================

# This resource iterates through the list of monitored projects and adds
# each one to the central monitoring workspace (Metrics Scope).
resource "google_monitoring_monitored_project" "all_monitored_projects" {
  for_each = toset(var.monitored_project_ids)

  # The metrics_scope is the "workspace" where all monitoring data is aggregated.
  metrics_scope = "locations/global/metricsScopes/${var.monitoring_project_id}"
  name          = each.key
}

# ===================================================================
# NOTIFICATION CHANNEL
# ===================================================================

# A single, reusable notification channel for all alert policies.
resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Cloud Operations Team Email"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

# ===================================================================
# DELAY FOR METRICS SCOPE PROPAGATION
#
# PROBLEM: When a new project is added to a Metrics Scope, it can take
# a few minutes for Google's backend to fully propagate this change.
# Creating an alert policy for that project immediately can fail.
#
# SOLUTION: This 'time_sleep' resource creates an intentional delay.
# The 'depends_on' meta-argument is crucial; it ensures this timer
# only starts AFTER all projects have been successfully added.
# ===================================================================
resource "time_sleep" "wait_for_monitoring_propagation" {
  create_duration = "60s"

  depends_on = [google_monitoring_monitored_project.all_monitored_projects]
}

# ===================================================================
# ALERT POLICY: HIGH CPU UTILIZATION
# ===================================================================
resource "google_monitoring_alert_policy" "cpu_alert_all_monitored_projects" {
  for_each = toset(var.monitored_project_ids)

  display_name          = "High CPU Utilization - Project: ${each.key}"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_channel.name]
  enabled               = true

  # This depends_on ensures that this alert policy is not created
  # until the 60-second propagation delay is complete.
  depends_on = [time_sleep.wait_for_monitoring_propagation]

  conditions {
    display_name = "CPU Usage > 80% for 5 minutes"
    condition_threshold {
      filter          = "project = \"${each.key}\" AND resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8 # 80%
      duration        = "300s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
}

# ===================================================================
# ALERT POLICY: HIGH DISK UTILIZATION (AGENT METRIC)
# ===================================================================
resource "google_monitoring_alert_policy" "disk_alert_all_monitored_projects" {
  for_each = toset(var.monitored_project_ids)

  display_name          = "High Disk Utilization - Project: ${each.key}"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_channel.name]
  enabled               = true

  depends_on = [time_sleep.wait_for_monitoring_propagation]

  conditions {
    display_name = "Disk space used > 80% for 15 minutes"
    condition_threshold {
      # This metric requires the Google Cloud Ops Agent to be installed on the VMs.
      filter = "project = \"${each.key}\" AND resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/disk/percent_used\" AND metric.label.state = \"used\""
      duration        = "900s"
      comparison      = "COMPARISON_GT"
      threshold_value = 80 # 80%
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
        # Group by device to get a separate alert for each disk (e.g., sda1, sdb1).
        group_by_fields = ["metric.labels.device"]
      }
    }
  }

  # The documentation block provides rich, contextual information directly
  # within the alert notification, helping operators resolve issues faster.
  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
    ### Alert: Low Disk Space Detected

    **Summary:** A disk on an instance has exceeded the 80% usage threshold.

    - **Project ID:** `${resource.label.project_id}`
    - **Instance Name:** `${resource.label.instance_name}`
    - **Affected Disk/Device:** `${metric.label.device}`

    **Action Required:** Please investigate and take action to free up disk space on the specified device.
    EOT
  }
}
