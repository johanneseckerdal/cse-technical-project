variable "account_id" {
  type = string
  default = "661de39146ce9c3c1567adf8418988b5" #johannes.eckerdal@gmail.com
}

variable "domain" {
  type = string
  default = "eckerdal.work"
}

variable "cloudflare_zone_plan" {
  type = string
  default = "free"
}

variable "cloudflare_zone_type" {
  type = string
  default = "full"
}

variable "cloudflare_api_token" {
  type        = string
  description = "The Cloudflare API token to authenticate with"
  sensitive   = true
}


variable "cloudflare_cnames" {
  description = "A list of CNAMEs created in Cloudflare for the GKE Ingresses."
  type        = list(string)
  default     = [
    "httpbin",
    "echoserver",
    "docker-helloworld"
  ]
}

variable "geo_block_countries" {
  description = "A list of country codes to block"
  type        = list(string)
  default = [
    "RU",
    "BY"
  ]
}

variable "user_agent_blocklist" {
  description = "A list of user agents wildcard patterns to block"
  type        = list(string)
  default = [
    "Nuclei - Open-source project*",
    "Fuzz Faster*",
    "*Sqlmap*"
  ]
}

variable "apikey_list" {
  type        = list(string)
  sensitive   = true
  description = "x-api-key values, used to validate valid paths - Formatted UUIDs"
  default     = [
    "88c91ec0-5009-4d24-8b2f-0356c524a5e0",
    "88c91ec0-5009-4d24-8b2f-0356c524a5e1",
    "88c91ec0-5009-4d24-8b2f-0356c524a5e2",
    "88c91ec0-5009-4d24-8b2f-0356c524a5e3"
  ]
}

variable "api_backend" {
  type = string
  default = "httpbin-ogmoxoqezq-ey.a.run.app"
}