(async function elmbootstrap() {
    const credentials = (await browser.storage.local.get("credentials"))
        ?.credentials;

    const tabs = await browser.tabs.query({ active: true });
    const title = tabs?.[0]?.title ?? null;
    const url = tabs?.[0]?.url ?? null;

    var app = Elm.Popup.init({
        node: document.getElementById("elm"),
        flags: {
            accessToken: credentials?.access_token ?? null,
            title,
            url,
        },
    });

    app.ports.sendMessage.subscribe(payload => {
        if (payload.action === "success") {
            setTimeout(() => window.close(), 1000);
            return;
        }

        browser.runtime.sendMessage({
            type: payload.action,
        });
    });
})();
