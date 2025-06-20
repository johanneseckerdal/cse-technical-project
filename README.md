# Customer Solutions Engineer Technical Project

Very welcome to my repo, holding the outcome of a _Customer Solutions Engineer Technical Project_!  
Below I'll describe what I've done, what I learned, and some reflections I've made along the way.

**Have a great summer!**

## Summary
### OnBoard a return-request-headers-app to Cloudflare
- HTTPBin container running in GCP accessible over [api.eckerdal.work](https://api.eckerdal.work)
- Use [/headers](https://api.eckerdal.work/headers) to return all request headers (_note the headers Cloudflare is appending to the forward request to origin_)

### Secure web apps using Cloudflare Tunnel
- Three web apps are running in a Google Kubernetes Engine cluster, accessible only via a Cloudflare Tunnel created with a ```cloudflared``` container, which proxies all requests to the _ngnix ingress_
- [httpbin.eckerdal.work](https://httpbin.eckerdal.work)
- [docker-helloworld.eckerdal.work](https://docker-helloworld.eckerdal.work)
- [echoserver.eckerdal.work](https://echoserver.eckerdal.work)

### Demonstrate how-to list DNS records via API 
The API docs are available at https://developers.cloudflare.com/api/resources/dns/subresources/records/methods/list/
```
# SCOPE: Token allowed to read DNS entries for specific zone.
# For security reasons the scope should always be limited
resource "cloudflare_api_token" "zone_dns_read" {
  name = "terraform-dns-read"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Read"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${local.cloudflare_zone_id}" = "*"
    }
  }
}

http --pretty=none --ignore-stdin https://api.cloudflare.com/client/v4/zones/$TF_VAR_cloudflare_zone_id/dns_records \
  Authorization:"Bearer $TF_VAR_cloudflare_api_token" \
  Accept:application/json \
  | jq '.result[]' | jq -r '[.name, .type, .content] | @tsv'

api.eckerdal.work       CNAME   httpbin-ogmoxoqezq-ey.a.run.app
docker-helloworld.eckerdal.work CNAME   gke-tunnel-origin.eckerdal.work
echoserver.eckerdal.work        CNAME   gke-tunnel-origin.eckerdal.work
gke-tunnel-origin.eckerdal.work CNAME   12db449e-cccd-4595-aa5e-aac6ae131e07.cfargotunnel.com
httpbin.eckerdal.work   CNAME   gke-tunnel-origin.eckerdal.work
...
```

### Redirect cURL requests
Using a worker, enabled for api.eckerdal.work and httpbin.eckerdal.work apps, the user-agent is evaluated. If user-agent is cURL the request is redirected to https://developer.cloudlfare.com/workers/about/, unless an exception cookie is provided.
```
curl -i https://httpbin.eckerdal.work/anything
HTTP/2 302 
date: Thu, 19 Jun 2025 09:50:08 GMT
content-length: 0
location: https://developers.cloudflare.com/workers/about/

curl -i https://httpbin.eckerdal.work/anything -H "cookie:cf-noredir=true; test=test;"
HTTP/2 200

curl -i https://httpbin.eckerdal.work/anything --cookie "cf-noredir=true"
HTTP/2 200

curl -i https://httpbin.eckerdal.work/anything --cookie "cf-noredir=false"
HTTP/2 302 
```

### Lock down access for specific user's only
Using WAF Custom Rules the path ```/status*``` is locked down, requiring a valid ```x-api-key```.

It should be noticed how this rule works in combination with the cURL redirect described above.
```
curl -i https://httpbin.eckerdal.work/status/200 --cookie "cf-noredir=true" -H "x-api-key:88c91ec0-5009-4d24-8b2f-0356c524a5e1"
HTTP/2 200

curl -i https://httpbin.eckerdal.work/status/200 --cookie "cf-noredir=true"
HTTP/2 403

# Verification the firewall DENY is happening before a possible worker's redirect
curl -i https://httpbin.eckerdal.work/status/200
HTTP/2 403

curl -i https://httpbin.eckerdal.work/status/200 -H "x-api-key:88c91ec0-5009-4d24-8b2f-0356c524a5e1"
HTTP/2 302
```


---

## Working notes
1. Created Free plan Cloudflare account johannes.eckerdal@gmail.com and setup api token
1. Created this repo
1. Created a setup script (```source setup.sh```)
1. Realized I couldn't use a subdomain, as it is a Free plan Cloudflare account. 
1. Bought a domain: ```eckerdal.work```
1. Created Terraform files and applied fundamentals to the eckerdal.work zone (apparently a lot less options available than on Enterprise)
1. Decided to start with the most interesting part of the excersize - Cloudflare Tunnel - Used https://github.com/cloudflare/argo-tunnel-examples to setup a GKE cluster with pods and a Tunnel. Quite some correction and updates were needed in the TF plans, as the repo is four years old. http://httpbin.eckerdal.work/ et al works
1. Got to know that only Universal SSL is supported on Free plan, so had to skip the cloudflare_certificate_pack resource.
1. Enabled Universal SSL and re-enabled HSTS, always HTTPS
1. Created an API call using HTTPie, to fetch all DNS-records from the zone and list them as tab-separated values using JQ.
1. Created a Worker to handle a redirect - used TF (rather than wrangler) to deploy and create worker-path (httpbin.eckerdal.work)
1. Added Custom Firewall rules to block TOR exit nodes, a list of UAs, and a list of GEO countries
1. Extended Custom Firewall rule with a block for /status/* paths, unless a valid x-api-key is provided
1. min_tls_version = "1.2" is already set, but in order to fulfil the first few _Technical requirements_ in the assignment, a new origin without Tunnel is to be created.
1. Deployed httpbin container as a Cloud Run instance
1. Planned to add DNS record and origin re-write (host) in Rules, but realized it is not on option when on a Free plan... 
1. Added origin hostname code into a Worker instead
1. Updated worker to use env.variable to avoid hard-coding
1. Upgraded security from _full_ to _strict_ in ```main.tf```
1. Wrote readme


