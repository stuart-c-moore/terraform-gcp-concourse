terraform {
  backend "gcs" {
    bucket = "stuart-finkit-terraform"
    project = "stuart-finkit"
  }
  required_version = ">= 0.11.0"
}
