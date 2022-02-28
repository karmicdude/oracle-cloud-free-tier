terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "4.63.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.8.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.oci.tenancy_ocid
  user_ocid        = var.oci.user_ocid
  private_key_path = var.oci.private_key_path
  fingerprint      = var.oci.fingerprint
  region           = var.oci.region
}

provider "cloudflare" {
  api_token = var.cf_api_token
}
