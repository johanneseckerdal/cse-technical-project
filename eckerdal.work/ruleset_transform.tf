# Enable security headers using Managed Meaders
resource "cloudflare_managed_headers" "managed-headers" {
  zone_id = cloudflare_zone.zone.id

  managed_response_headers {
    id      = "remove_x-powered-by_header"
    enabled = true
  }

  managed_response_headers {
    id      = "add_security_headers"
    enabled = true
  }
}
