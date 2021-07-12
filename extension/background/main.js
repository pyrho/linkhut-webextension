import { getAccessToken } from "/background/authorize.js";

function handleMessage(request /*sender, sendResponse*/) {
    const action = (() => {
        switch (request.type) {
            case "auth":
                return () => getAccessToken();
        }
    })();

    action().then(() => browser.runtime.sendMessage({ action: "refreshUI" }));
}
//;

browser.runtime.onMessage.addListener(handleMessage);
