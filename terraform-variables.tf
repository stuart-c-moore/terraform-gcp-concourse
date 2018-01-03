variable "project" { }
variable "region" { }
variable "prefix" { default = "default" }
variable "zones" { default = "1" }
variable "db-ha" { default =  false }
variable "service_account_name" { default = "automated" }
variable "service_account_role" { default = "roles/owner" }
