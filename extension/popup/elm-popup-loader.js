(async function elmbootstrap() {
    async function getTabInfo() {
        const tabs = await browser.tabs.query({ active: true });
        const title = tabs?.[0]?.title ?? null;
        const url = tabs?.[0]?.url ?? null;
        return { title, url };
    }

    async function getCredentials() {
        return (
            (await browser.storage.local.get("credentials"))?.credentials ?? {}
        );
    }
    function getAccessToken(credentials) {
        return credentials?.access_token ?? null;
    }

    var app = Elm.Popup.init({
        node: document.getElementById("elm"),
        flags: {
            accessToken: await getCredentials().then(getAccessToken),
            ...(await getTabInfo()),
        },
    });

    app.ports.sendMessage.subscribe(async payload => {
        // The popup has succesfully saved the link
        // Now close the popup
        if (payload.action === "success") {
            setTimeout(() => window.close(), 1000);
            return;
        } else if (payload.action === "getTabInfo") {
            app.ports.messageReceiver.send({
                action: "tabInfo",
                data: {
                    accessToken: await getCredentials().then(getAccessToken),
                    ...(await getTabInfo()),
                },
            });
            return;
        } else {
            // Send message to the background page
            browser.runtime.sendMessage(payload);
        }
    });

    browser.runtime.onMessage.addListener(msg => {
        // This is needed because we expect a `Nothing` in Elm land.
        if (!msg.data) msg.data = null;

        app.ports.messageReceiver.send(msg);
    });
})();
