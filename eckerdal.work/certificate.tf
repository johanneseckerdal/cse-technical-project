/* # create a local variable using var.cloudflare_cnames and var.domain
locals {
  cloudflare_cnames = [for cname in var.cloudflare_cnames : "${cname}.${var.domain}"]
}

resource "cloudflare_certificate_pack" "certificate" {
  zone_id               = cloudflare_zone.zone.id
  certificate_authority = "google"
  hosts                 = local.cloudflare_cnames
  type                  = "advanced"
  validation_method     = "txt"
  validity_days         = 90
  wait_for_active_status = null
}
 */