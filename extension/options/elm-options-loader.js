(async function elmbootstrap() {
    const settings =
        (await browser.storage.local.get("settings"))?.settings ?? {};

    var app = Elm.Options.init({
        node: document.getElementById("elm"),
        flags: {
            clientId: settings?.clientId ?? null,
            clientSecret: settings?.clientSecret ?? null,
            webUrl: settings?.webUrl ?? null,
            apiUrl: settings?.apiUrl ?? null,
        },
    });

    app.ports.sendMessage.subscribe(async payload => {
        // The popup has succesfully saved the link
        // Now close the popup
        if (payload.action === "save") {
            await browser.storage.local.set({
                settings: {
                    webUrl: payload.data.webUrl,
                    apiUrl: payload.data.apiUrl,
                    clientId: payload.data.clientId,
                    clientSecret: payload.data.clientSecret,
                },
            });

            app.ports.messageReceiver.send("success");
        } else if (payload.action === "reset") {
            await browser.storage.local.remove("settings");
            app.ports.messageReceiver.send("resetDone");
        }
    });

    browser.runtime.onMessage.addListener(msg => {
        // This is needed because we expect a `Nothing` in Elm land.
        if (!msg.data) msg.data = null;

        app.ports.messageReceiver.send(msg);
    });
})();
