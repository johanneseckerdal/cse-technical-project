# Set compress algorithm for response
resource "cloudflare_ruleset" "response_compress_brotli_html" {
  zone_id     = cloudflare_zone.zone.id
  name        = "Response compression ruleset"
  description = ""
  phase       = "http_response_compression"
  kind        = "zone"

  rules {
    ref         = "prefer_brotli_for_html"
    description = "Prefer Brotli compression for HTML"
    expression  = "http.response.content_type.media_type == \"text/html\""
    action      = "compress_response"
    action_parameters {
      algorithms {
        name = "brotli"
      }
      algorithms {
        name = "auto"
      }
    }
  }
}