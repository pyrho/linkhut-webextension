(async function elmbootstrap() {
    const webUrl = await browser.storage.local.get("webUrl");
    const apiUrl = await browser.storage.local.get("apiUrl");

    var app = Elm.Options.init({
        node: document.getElementById("elm"),
        flags: {
            webUrl: webUrl?.webUrl ?? null,
            apiUrl: apiUrl?.apiUrl ?? null,
        },
    });

    app.ports.sendMessage.subscribe(async payload => {
        console.log("IN HERE!" + JSON.stringify(payload));
        console.log(payload.action);
        // The popup has succesfully saved the link
        // Now close the popup
        if (payload.action === "save") {
            console.log("saving");
            await browser.storage.local.set({
                webUrl: payload.data.webUrl,
                apiUrl: payload.data.apiUrl,
            });
            console.log("saved");

            app.ports.messageReceiver.send("success");
        }
    });

    browser.runtime.onMessage.addListener(msg => {
        // This is needed because we expect a `Nothing` in Elm land.
        if (!msg.data) msg.data = null;

        app.ports.messageReceiver.send(msg);
    });
})();
