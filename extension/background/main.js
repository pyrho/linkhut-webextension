import { getAccessToken } from "/background/authorize.js";

function handleMessage(request) {
    const action = (() => {
        switch (request.type) {
            case "auth":
                return () => getAccessToken();
        }
    })();

    action().catch(e => {
        console.error(e);
    });
}
//;

browser.runtime.onMessage.addListener(handleMessage);
