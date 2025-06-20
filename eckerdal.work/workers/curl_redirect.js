import { env } from "cloudflare:workers";

export default {
    async fetch(request) {
        // Redirect Location and Path
        const newLocationHost = "developers.cloudflare.com";
        const newLocationPath = "/workers/about/";
        // Get an exception cookie from the request and check if it is set to "true"
        // If it is set to "true", do not redirect
        const cookieName = "cf-noredir";
        const cookieString = request.headers.get("Cookie") || "";
        const value = getCookie(cookieString, cookieName)
        //
        // Get User-Agent from request headers
        // If User-Agent contains 'curl', redirect to new location
        const reqUA = request.headers.get('user-agent');
        if (reqUA && reqUA.includes('curl') && value !== "true") {
            const newLocation = "https://" + newLocationHost + newLocationPath;
            return Response.redirect(newLocation, 302);
        }
        // If hostname is 'api', use different origin
        if (request.headers.get('host') === 'api.eckerdal.work') {
            const newUrl = new URL(request.url);
            newUrl.hostname = env.api_backend; 
            return fetch(newUrl.toString(), request);
        }
        // Otherwise, just return the original request
        return fetch(request);
    }
}

/**
 * Takes a cookie string
 * @param {String} cookieString - The cookie string value: "val=key; val2=key2; val3=key3;"
 * @param {String} key - The name of the cookie we are reading from the cookie string
 * @returns {(String|null)} Returns the value of the cookie OR "false" if nothing was found.
 */
function getCookie(cookieString, key) {
  if (cookieString) {
    const allCookies = cookieString.split("; ")
    const targetCookie = allCookies.find(cookie => cookie.includes(key))
    if (targetCookie) {
      const [_, value] = targetCookie.split("=")
      return value
    }
  }

  return "false"
}
