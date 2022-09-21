import logger from "/background/logger.js";

async function getExtensionSettings() {
  const s = await browser.storage.local.get("settings");
  return s?.settings ?? {};
}

async function getBaseWebUrl() {
  const settings = await getExtensionSettings();
  return settings?.webUrl ?? "https://ln.ht";
}

async function getBaseApiUrl() {
  const settings = await getExtensionSettings();
  return settings?.apiUrl ?? "https://api.ln.ht";
}

async function getAuthorizeUrl() {
  const baseWebUrl = await getBaseWebUrl();
  return `${baseWebUrl}/_/oauth/authorize`;
}

async function getTokenUrl() {
  const baseApiUrl = await getBaseApiUrl();
  return `${baseApiUrl}/_/v1/oauth/token`;
}

const REDIRECT_URL = (() => {
  const u = browser.identity.getRedirectURL();
  return u.endsWith("/") ? u.slice(0, u.length - 1) : u;
})();

// I know this is a secret but with SPAs and extension there isn't really
// a way around it.
// See https://github.com/danschultzer/ex_oauth2_provider#authorization-code-flow-in-a-single-page-application
async function getClientSecret() {
  const settings = await getExtensionSettings();
  return (
    settings?.clientSecret ??
    "1fda7bfbaa775387caadb05dd7c6c93c1cf5d25100f767772a8fd3194f6b25ed"
  );
}

async function getClientId() {
  const settings = await getExtensionSettings();
  return (
    settings?.clientId ??
    "12ea1ba0aa4c3e0c59cbc235a17880e7a57a8cc4d3c7b7c1d76423e68b35fa8f"
  );
}

const SCOPES = ["posts:write", "posts:read"];

async function buildFullAuthorizationUrl() {
  const baseUrl = await getAuthorizeUrl();
  const clientId = await getClientId();
  const fullAuthUrl = `${baseUrl}?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(
    REDIRECT_URL
  )}&scope=${encodeURIComponent(SCOPES.join(" "))}`;
  logger.debug(`Using auth url: ${fullAuthUrl}`);
  return fullAuthUrl;
}

function getCodeFromCallbackUrl(redirectUri) {
  logger.debug(`Redirect URI: ${redirectUri}`);
  const parsedUrl = new URL(redirectUri);

  if (parsedUrl.searchParams.has("error")) {
    throw new Error(
      parsedUrl.searchParams.get("error_description") ?? "Generic error"
    );
  }

  if (!parsedUrl.searchParams.has("code")) {
    throw new Error(
      "Code was missing from the redirect URI as called by ln.ht"
    );
  }
  return parsedUrl.searchParams.get("code");
}

async function getCredentialsFromGrantCode(redirectURL) {
  const tokenUrl = await getTokenUrl();
  const url = new URL(tokenUrl);
  const clientSecret = await getClientSecret();
  const clientId = await getClientId();
  url.search = new URLSearchParams({
    grant_type: "authorization_code",
    client_id: clientId,
    redirect_uri: REDIRECT_URL,
    client_secret: clientSecret,
    code: getCodeFromCallbackUrl(redirectURL),
  }).toString();

  function getTokensFromServerResponse(response) {
    return new Promise((resolve, reject) => {
      if (response.status !== 200) {
        return reject(
          new Error(`Token creation error, status: ${response.status}`)
        );
      }

      response.json().then((json) => {
        if (!json.access_token || !json.refresh_token) {
          return reject(
            new Error(
              `access_token or refresh_token was missing from server reply`
            )
          );
        }

        logger.debug("Token looks good");
        return resolve(json);
      });
    });
  }

  return fetch(url, { method: "POST" }).then(getTokensFromServerResponse);
}

/**
Authenticate and authorize using browser.identity.launchWebAuthFlow().
If successful, this resolves with a redirectURL string that contains
an access token.
*/
async function authorize() {
  const authUrl = await buildFullAuthorizationUrl();
  logger.debug(`Starting authorize with url ${authUrl}`);
  return browser.identity.launchWebAuthFlow({
    interactive: true,
    url: authUrl,
  });
}

async function storeCredentials(credentials) {
  logger.debug(
    "Storing credentials in local storage" + JSON.stringify(credentials)
  );
  return browser.storage.local.set({ credentials });
}

export async function getAccessToken() {
  return authorize().then(getCredentialsFromGrantCode).then(storeCredentials);
}
