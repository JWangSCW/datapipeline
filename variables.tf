# --- Scaleway Authentication ---

variable "access_key" {
  type        = string
  description = "Scaleway Access Key used for API authentication."
}

variable "secret_key" {
  type        = string
  description = "Scaleway Secret Key. This value is marked as sensitive and will be masked in console logs."
  sensitive   = true #
}

variable "project_id" {
  type        = string
  description = "The ID of the Scaleway project where resources are deployed."
}

variable "region" {
  type        = string
  description = "The Scaleway region used (e.g., fr-par)."
}

# --- Managed PostgreSQL (Source) ---

variable "pg_username" {
  type        = string
  description = "Administrative username for the PostgreSQL database instance."
}

variable "pg_password" {
  type        = string
  description = "Password for the PostgreSQL database. Masked in output for security."
  sensitive   = true #
}

variable "pg_table" {
  type        = string
  description = "The name of the source database within PostgreSQL (e.g., pg-demo-1)."
}

variable "pg_port" {
  type        = number
  description = "The port of the source database PostgreSQL (e.g., 7116)."
}

# --- Managed ClickHouse (Destination / DWH) ---

variable "dwh_username" {
  type        = string
  description = "Administrative username for the ClickHouse instance."
}

variable "dwh_password" {
  type        = string
  description = "ClickHouse password. Note: Special characters must be URL-encoded for the connection string to be valid (e.g., ! becomes %21)."
  sensitive   = true #
}

variable "dwh_table" {
  type        = string
  description = "The name of the target database in ClickHouse (typically 'default')."
}

variable "dwh_port" {
  type        = number
  description = "The port of the ClickHouse instance (e.g., 9440)."
}

# --- Git & CI/CD ---

variable "dbt_repo" {
  type        = string
  description = "The URL of the Git repository containing Airflow DAGs and dbt models."
}
