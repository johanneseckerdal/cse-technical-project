resource "cloudflare_workers_script" "redirect_worker" {
  account_id          = var.account_id
  name                = "redirect-worker"
  content             = file("workers/curl_redirect.js")
  module              = true
  plain_text_binding {
    name = "api_backend"
    text = var.api_backend
  }
}

resource "cloudflare_workers_route" "redirect_worker_route" {
  zone_id     = cloudflare_zone.zone.id
  pattern     = "httpbin.${var.domain}/*"
  script_name = cloudflare_workers_script.redirect_worker.name
  depends_on = [
    cloudflare_workers_script.redirect_worker
  ]
}

resource "cloudflare_workers_route" "api_worker_route" {
  zone_id     = cloudflare_zone.zone.id
  pattern     = "api.${var.domain}/*"
  script_name = cloudflare_workers_script.redirect_worker.name
  depends_on = [
    cloudflare_workers_script.redirect_worker
  ]
}
