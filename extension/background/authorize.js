import logger from "/background/logger.js";

const settings = (await browser.storage.local.get("settings"))?.settings ?? {};

const BASE_URL_WEB = settings?.webUrl ?? "https://ln.ht";

const BASE_URL_API = settings?.apiUrl ?? "https://api.ln.ht";

const CONSTANTS = {
    tokenUrl: `${BASE_URL_API}/v1/oauth/token`,
    authorizeUrl: `${BASE_URL_WEB}/_/oauth/authorize`,
};
const REDIRECT_URL = (() => {
    const u = browser.identity.getRedirectURL();
    return u.endsWith("/") ? u.slice(0, u.length - 1) : u;
})();

// I know this is a secret but with SPAs and extension there isn't really
// a way around it.
// See https://github.com/danschultzer/ex_oauth2_provider#authorization-code-flow-in-a-single-page-application
const CLIENT_SECRET =
    settings?.clientSecret ??
    "62cf230387f4c1706dbe7edbc29a6fc5386f0f401af8c0a648038bba8c972aa8";

const CLIENT_ID =
    settings?.clientId ??
    "90e66396114916ee104193f7b1c6171dfc3e4a9497db246db60646ba8135b780";

const SCOPES = ["posts:write", "posts:read"];
const AUTH_URL = `${CONSTANTS.authorizeUrl}\
?response_type=code\
&client_id=${CLIENT_ID}\
&redirect_uri=${encodeURIComponent(REDIRECT_URL)}\
&scope=${encodeURIComponent(SCOPES.join(" "))}`;

function getCodeFromCallbackUrl(redirectUri) {
    logger.debug(`Redirect URI: ${redirectUri}`);
    const parsedUrl = new URL(redirectUri);

    if (parsedUrl.searchParams.has("error")) {
        throw new Error(
            parsedUrl.searchParams.get("error_description") ?? "Generic error",
        );
    }

    if (!parsedUrl.searchParams.has("code")) {
        throw new Error(
            "Code was missing from the redirect URI as called by ln.ht",
        );
    }
    return parsedUrl.searchParams.get("code");
}

async function getCredentialsFromGrantCode(redirectURL) {
    const url = new URL(CONSTANTS.tokenUrl);
    url.search = new URLSearchParams({
        grant_type: "authorization_code",
        client_id: CLIENT_ID,
        redirect_uri: REDIRECT_URL,
        client_secret: CLIENT_SECRET,
        code: getCodeFromCallbackUrl(redirectURL),
    }).toString();

    function getTokensFromServerResponse(response) {
        return new Promise((resolve, reject) => {
            if (response.status !== 200) {
                return reject(new Error("Token creation error"));
            }

            response.json().then(json => {
                if (!json.access_token || !json.refresh_token) {
                    return reject(
                        new Error(
                            `access_token or refresh_token was missing from server reply`,
                        ),
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
function authorize() {
    return browser.identity.launchWebAuthFlow({
        interactive: true,
        url: AUTH_URL,
    });
}

async function storeCredentials(credentials) {
    logger.debug(
        "Storing credentials in local storage" + JSON.stringify(credentials),
    );
    return browser.storage.local.set({ credentials });
}

export function getAccessToken() {
    return authorize().then(getCredentialsFromGrantCode).then(storeCredentials);
}
