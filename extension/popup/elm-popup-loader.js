(async function elmbootstrap() {
  async function getTitleAndUrl() {
    const tabs = await browser.tabs.query({
      currentWindow: true,
      active: true,
    });
    const title = tabs?.[0]?.title ?? null;
    const url = tabs?.[0]?.url ?? null;
    return { title, url };
  }

  const settings = (await browser.storage.local.get("settings"))?.settings;

/// APP INIT
  var app = Elm.Popup.init({
    node: document.getElementById("elm"),
    flags: {
      apiUrl: settings?.apiUrl ?? null,
      accessToken: settings?.personalAccessToken ?? null,
      ...(await getTitleAndUrl()),
    },
  });

  app.ports.sendMessage.subscribe(async (payload) => {
    // The popup has succesfully saved the link
    // Now close the popup
    if (payload.action === "success") {
      setTimeout(() => window.close(), 1000);
      return;
    } else {
      console.error(`Should not happen, got message: ${JSON.stringify(payload, null, 2)}`)
    }
  });

  browser.runtime.onMessage.addListener((msg) => {
    // This is needed because we expect a `Nothing` in Elm land.
    if (!msg.data) msg.data = null;

    app.ports.messageReceiver.send(msg);
  });
})();
