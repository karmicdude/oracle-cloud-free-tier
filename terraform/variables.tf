variable "oci" {
  description = "Oracle Cloud Infra provider settings"
  type        = map(string)
}

variable "cf_api_token" {
  description = "Cloudflare API token"
  type        = string
}

variable "root_domain" {
  description = "main domain name"
  type        = string
}

variable "zone_id" {
  description = "Main domain zone id"
  type        = string
}
