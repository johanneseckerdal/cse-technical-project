# Customer Solutions Engineer Technical Project

Very welcome to my repo, holding the outcome of a _Customer Solutions Engineer Technical Project_!  
Below I'll describe what I've done, what I learned, and some reflections I've made along the way.

**Have a great summer!**

## Summary
### OnBoard a return-request-headers-app to Cloudflare
- HTTPBin container running in GCP accessible over [api.eckerdal.work](https://api.eckerdal.work)
- Use [api.eckerdal.work/headers](https://api.eckerdal.work/headers) to return all request headers (_note the headers Cloudflare is appending to the forward request to origin_)
   - Default Cloudflare caching and security settings used, with additional HSTS and security headers added.
   - HTTPS is enforced, with minimum TLS 1.2.
   - Origin TLS Full-strict mode used with origin certificate validation.

### Secure web apps using Cloudflare Tunnel
- Three web apps are running in a Google Kubernetes Engine cluster, accessible only via a Cloudflare Tunnel created with a ```cloudflared``` container, which proxies all requests to the _ngnix ingress_. 
    - [httpbin.eckerdal.work](https://httpbin.eckerdal.work)
    - [docker-helloworld.eckerdal.work](https://docker-helloworld.eckerdal.work)
    - [echoserver.eckerdal.work](https://echoserver.eckerdal.work)
- With Cloudflare Tunnel the GKE cluster does not have any inbound public routable access, but the ```cloudflared``` container establish a tunnel out to the nearest Cloudflare PoP.

### Demonstrate how-to list DNS records via API 
The API docs are available at https://developers.cloudflare.com/api/resources/dns/subresources/records/methods/list/. Here are also the nescessary permissions listed. 
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
docker-helloworld.eckerdal.work CNAME   tunnel.eckerdal.work
echoserver.eckerdal.work        CNAME   tunnel.eckerdal.work
tunnel.eckerdal.work CNAME   12db449e-cccd-4595-aa5e-aac6ae131e07.cfargotunnel.com
httpbin.eckerdal.work   CNAME   tunnel.eckerdal.work
...
```

### Redirect cURL requests
With a worker implementation, enabled for api.eckerdal.work and httpbin.eckerdal.work apps, the user-agent is evaluated. If user-agent is cURL the request is redirected to https://developer.cloudlfare.com/workers/about/, unless an exception cookie is provided.
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
### IaC Terraform
Everything in this project was achieved with Terraform and the plans are included in this repo. In [eckerdal.work/](eckerdal.work/) you'll find the account and zone plan, and in [terraform-gcp-gke-ingress-controller/](terraform-gcp-gke-ingress-controller/) is the GKE cluster and Cloudflare Tunnel setup.

## What did I learn?
There were mainly two things that was new to me in this project; the difference between a Free and an Enterprise plan (which is the only thing I've worked with before), and the Cloudflare Tunnel. I've previously only worked with the equivalent Akamai zero-trust tunnel clients and configurations.

Generally speaking I find the Cloudflare developer docs being a good starting point when learning something new. Then obviously Google, Copilot, Stack Overflow, etc are close at hand.
For Terraform related syntax it's https://registry.terraform.io/providers/cloudflare/cloudflare/4.52.0/docs (I chose to use this _old_ version as I'm still not started with v5 in my current professional role)

The lack of certain capabilities in the Free plan was causing me some issues and frustration. I had an idea of how to do the setup, but had to re-think at several occasions and chose a different path. 

## Cloudflare Tunnel and Workers
Cloudflare Tunnel adress the classical dilemma when using a CDN, that your origin is still accessible over the Internet, making it vulnerable to attacks, information leakage and even DDoS targeted your origin insfrastructure. The legacy solution is to use origin Firewalls and a DMZ network, restricting access to the CDN only.  
Using Cloudflare Tunnel your origin does not have any exposure to the Internet, it's gone dark. Instead there are thin agents installed, which opens _outbound_ connections to the nearest Cloudflare location, providing a tunnel through which requests are proxied from Cloudflare to the origin application.

Cloudflare Workers provide a truly serverless Edge computing capability, with an excellent developer experience where observability and fast feedback loops are built into the platform. With Workers you can use javascript or typescript coding to control the CDN behavior, both from a security, performance, and application functionality perspective.  
With Workers you can build web apps for global reach and scale - serverless without cold-start penalty or hazzle of regional deployments.

## HTTP Response headers with Cloudflare
When using a Content Delivery Network, you effectivly using a proxy between the users and the origin application. You are shielding the origin and you can also manipulate headers to/from the app. Some typical response headers we see when secured and boosted by Cloudflare are:
- ```server: cloudflare``` - this is always set, and replace whatever the origin has set.
- ```cf-ray``` - this is a unique request id, which can be used to troubleshoot and debug.
- ```cf-cache-status``` - information if a request is cacheable or not, cacheHit, cacheMiss, revalidated, etc.
- ```age``` - information how long a cachable object has been in edge cache, in seconds. The browser may use this in combination with cache-control directives to decide TTL in browser cache.


---

## Project working notes
1. Created Free plan Cloudflare account and setup api token
1. Created this repo
1. Created a setup script (```source setup.sh```)
1. Realized I couldn't use a subdomain, as it is a Free plan Cloudflare account. 
1. Bought a domain: ```eckerdal.work```
1. Created Terraform files and applied fundamentals to the eckerdal.work zone (apparently a lot less options available than on Enterprise)
1. Decided to start with the most interesting part of the excersize - Cloudflare Tunnel - Used https://github.com/cloudflare/argo-tunnel-examples to setup a GKE cluster with pods and a Tunnel. Quite some correction and updates were needed in the TF plans, as the repo is four years old. 
1. Got to know that only Universal SSL is supported on Free plan, so had to skip the cloudflare_certificate_pack resource.
1. Enabled Universal SSL and re-enabled HSTS, always HTTPS
1. Created an API call using HTTPie, to fetch all DNS-records from the zone and list them as tab-separated values using JQ.
1. Created a Worker to handle a redirect - used TF (rather than wrangler) to deploy and create worker-path (httpbin.eckerdal.work)
1. Added Custom Firewall rules to block TOR exit nodes, a list of UAs, and a list of GEO countries
1. Extended Custom Firewall rule with a block for /status/* paths, unless a valid x-api-key is provided
1. min_tls_version = "1.2" was already set, but in order to fulfil the first few _Technical requirements_ in the assignment, a new origin without Tunnel is to be created.
1. Deployed httpbin container as a Cloud Run instance
1. Planned to add DNS record and origin re-write (host) in Rules, but realized it is not on option when on a Free plan... 
1. Added origin hostname code into a Worker instead
1. Updated worker to use env.variable to avoid hard-coding
1. Upgraded security from _full_ to _strict_ in ```main.tf```
1. Wrote readme


