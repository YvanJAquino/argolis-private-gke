# https://www.terraform-best-practices.com/code-structure

# # Configure service account impersonation
# locals {
#     terraform_service_account = "terraform-skeleton-key@norse-avatar-341214.iam.gserviceaccount.com"
# }
# provider "google" {
#  alias = "impersonation"
#  scopes = [
#    "https://www.googleapis.com/auth/cloud-platform",
#    "https://www.googleapis.com/auth/userinfo.email",
#  ]
# }
# data "google_service_account_access_token" "default" {
#  provider               	= google.impersonation
#  target_service_account 	= local.terraform_service_account
#  scopes                 	= ["userinfo-email", "cloud-platform"]
#  lifetime               	= "1200s"
# }
# provider "google" {
#     access_token = data.google_service_account_access_token.default.access_token
#     project = var.project_id
#     region  = var.region
# }

# Configure a provider.
provider "google" {
    project = var.project_id
    region  = var.region
}

data "google_project" "project" {}
# output "project_number" {
#   value = data.google_project.project.number
# }

# Enable APIs
# if compute.googleapis.com isn't turned on the entire script may fail
# because compute.googleapis.com takes a while to enable...
resource "google_project_service" "cloudrm" {
    provider = google
    service  = "cloudresourcemanager.googleapis.com"
    disable_on_destroy = false
}
resource "google_project_service" "compute" {
    provider = google
    service  = "compute.googleapis.com"
    disable_on_destroy = false
}
resource "google_project_service" "orgpolicy" {
    provider = google
    service  = "orgpolicy.googleapis.com"
    disable_on_destroy = false
}
resource "google_project_service" "gke" {
    provider = google
    service  = "container.googleapis.com"
    disable_on_destroy = false
}

# Configure org policies
# Does not work citing:
# Error: Error creating Policy: failed to create a diff: failed to retrieve Policy resource: googleapi: Error 403: Your application has authenticated using end user credentials from the Google Cloud SDK or Google Cloud Shell which are not supported by the orgpolicy.googleapis.com. We recommend configuring the billing/quota_project setting in gcloud or using a service account through the auth/impersonate_service_account setting. For more information about service accounts and how to use them in your application, see https://cloud.google.com/docs/authentication/. If you are getting this error with curl or similar tools, you may need to specify 'X-Goog-User-Project' HTTP header for quota and billing purposes. For more information regarding 'X-Goog-User-Project' header, please check https://cloud.google.com/apis/docs/system-parameters.
# resource "google_org_policy_policy" "peering" {
#     name   = "projects/${var.project_id}/policies/compute.restrictVpcPeering"
#     parent = "projects/${var.project_id}"
#     spec {
#         rules {
#         enforce = "FALSE"
#         }
#     }
# }