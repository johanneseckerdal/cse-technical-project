terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.52.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

import {
  to = cloudflare_zone.zone
  id = "fd1166e885682f90c71c2ef1634bfe9b"
}

resource "cloudflare_zone" "zone" {
  account_id  = var.account_id
  paused      = false
  zone        = var.domain
  type        = var.cloudflare_zone_type
  plan        = var.cloudflare_zone_plan
}

import {
  to = cloudflare_zone_settings_override.zone-settings
  id = "fd1166e885682f90c71c2ef1634bfe9b"
}

resource "cloudflare_zone_settings_override" "zone-settings" {
  zone_id = cloudflare_zone.zone.id
  settings {
    always_use_https            = "on"
    browser_check               = "on"
    h2_prioritization           = "off"
    http3                       = "on"
    ip_geolocation              = "off"
    ipv6                        = "on"
    min_tls_version             = "1.2"
    security_header {
        enabled = true
        preload = true
        max_age = 31536000
        include_subdomains = true
        nosniff = true
    }
    ssl                         = "strict"
    tls_1_3                     = "zrt"
    universal_ssl               = "on"
    zero_rtt                    = "on"
  }
}

resource "cloudflare_tiered_cache" "tiered-cache" {
  zone_id    = cloudflare_zone.zone.id
  cache_type = "generic"
}


resource "cloudflare_url_normalization_settings" "url-normalization" {
  zone_id = cloudflare_zone.zone.id
  scope   = "incoming"
  type    = "cloudflare"
}
