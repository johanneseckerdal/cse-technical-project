resource "cloudflare_record" "api_host" {
  zone_id   = cloudflare_zone.zone.id
  name      = "api"
  content   = var.api_backend
  type      = "CNAME"
  proxied   = true
}
# The above record is not practically used, as the forwarded hostname/SNI is api.eckerdal.work. 
# In an Enterprise plan this would have been handled with origin rewrite rules, but in Free plan it is solved with a Worker instead, doing sub-requests.check "
