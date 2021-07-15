import { getAccessToken } from "/background/authorize.js";

function doAuth() {
    getAccessToken()
        .then(() => {
            browser.runtime.sendMessage({ action: "authSuccess" });
        })
        .catch(_ => {
            browser.runtime.sendMessage({ action: "error" });
        });
}

function handleMessage(request) {
    console.log(JSON.stringify(request));
    switch (request.action) {
        case "auth":
            doAuth();
    }
}

browser.runtime.onMessage.addListener(handleMessage);
