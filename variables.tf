variable "monitoring_project_id" {
  type        = string
  description = "The GCP Project ID that will host the central monitoring workspace (Metrics Scope)."
}

variable "monitored_project_ids" {
  type        = list(string)
  description = "A list of GCP Project IDs to be monitored by the central workspace."
}

variable "notification_email" {
  type        = string
  description = "The email address to send monitoring alerts to."
  sensitive   = true
}

variable "region" {
  type        = string
  description = "The GCP region for the provider and resources."
  default     = "us-central1"
}
