variable "project" { }
variable "region" { }
variable "prefix" { default = "default" }
variable "zones" { default = "1" }
variable "db-ha" { default =  false }
variable "service_account_name" { default = "automated" }
variable "service_account_role" { default = "roles/owner" }
variable "db-version" { default = "MYSQL_5_7" }
variable "home" { default = "/home/vagrant" }
variable "concourse-cidr" { default = "10.20.0.0/28" }
variable "database_params" {
  type = "map"
  default {
    type {
      MYSQL_5_7 = "mysql"
      POSTGRES_9_6 = "postgres"
    }
    bosh-adapter {
      MYSQL_5_7 = "mysql2"
      POSTGRES_9_6 = "postgres"
    }
    port {
      MYSQL_5_7 = "3306"
      POSTGRES_9_6 = "5432"
    }
    charset {
      MYSQL_5_7 = "utf8"
      POSTGRES_9_6 = "UTF8"
    }
    collation {
      MYSQL_5_7 = "utf8_general_ci"
      POSTGRES_9_6 = "en_US.UTF8"
    }
  }
}

