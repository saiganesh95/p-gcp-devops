### Database Migration Service: AWS RDS (MySQL/Postgres) -> Cloud SQL ###

variable "project_id"        { type = string }
variable "region"            { type = string }
variable "source_host"       { type = string }  # AWS RDS endpoint
variable "source_port" {
  type    = number
  default = 3306
}
variable "source_username"   { type = string }
variable "source_password"   {
  type      = string
  sensitive = true
}
variable "cloudsql_instance" { type = string }  # target Cloud SQL instance name

resource "google_database_migration_service_connection_profile" "source" {
  project               = var.project_id
  location              = var.region
  connection_profile_id = "aws-rds-source"

  mysql {
    host     = var.source_host
    port     = var.source_port
    username = var.source_username
    password = var.source_password
  }
}

resource "google_database_migration_service_connection_profile" "destination" {
  project               = var.project_id
  location              = var.region
  connection_profile_id = "cloudsql-destination"

  cloudsql {
    settings {
      tier            = "db-custom-4-16384"
      database_version = "MYSQL_8_0"
      source_id       = google_database_migration_service_connection_profile.source.name

      ip_config {
        enable_ipv4 = false
      }
    }
  }
}

resource "google_database_migration_service_migration_job" "job" {
  project               = var.project_id
  location              = var.region
  migration_job_id      = "rds-to-cloudsql-migration"
  display_name          = "AWS RDS to Cloud SQL - continuous"
  type                  = "CONTINUOUS"
  source                = google_database_migration_service_connection_profile.source.name
  destination           = google_database_migration_service_connection_profile.destination.name

  reverse_ssh_connectivity {
    vm             = "dms-bastion"
    vm_ip          = "10.30.1.10"
    vm_port        = 22
    vpc            = "vpc-hub-common-connectivity"
  }
}
