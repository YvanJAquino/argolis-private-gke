terraform {
  backend "gcs" {
    bucket = "norse-avatar-341214"
    prefix = "terraform/state"
  }
}