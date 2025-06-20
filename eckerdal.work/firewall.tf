/* Custom ruleset for the WAF */
resource "cloudflare_ruleset" "custom_waf_rules" {
  zone_id     = cloudflare_zone.zone.id
  name        = "Access Control rules"
  description = "Block requests if not meeting certain criteria"
  kind        = "zone"
  phase       = "http_request_firewall_custom"


  # Block by country
  rules {
    ref         = "geo_block"
    description = "Block requests from specific countries"
    expression  = "(ip.src.country in {${join(" ", formatlist("\"%s\"", var.geo_block_countries))}})"
    action      = "block"
    enabled     = true
  }
  # Block Tor exit nodes
  rules {
    ref         = "tor_block"
    description = "Block requests from Tor exit nodes"
    expression  = "(ip.src.country eq \"T1\")"
    action      = "block"
    enabled     = true
  }

  
  # Blocks specific user agents using wildcard matching
  rules {
    action      = "block"
    description = "Block user agents"
    enabled     = true
    expression  = join(" or ", formatlist("(http.user_agent wildcard r\"%s\")", var.user_agent_blocklist))
  }

  rules {
    action      = "block"
    description = "Status API Key"
    enabled     = true
    expression  = "((raw.http.request.uri.path wildcard \"/status/*\") and not any(http.request.headers[\"x-api-key\"][*] in {${join(" ", formatlist("\"%s\"", var.apikey_list))}}))"
  }

}
