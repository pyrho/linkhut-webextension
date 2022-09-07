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

  // Intercept messages from the options page TO the background page
  app.ports.sendMessage.subscribe(async (payload) => {
    if (payload.action === "save") {
      await browser.storage.local.set({
        settings: {
          webUrl: payload.data.webUrl,
          apiUrl: payload.data.apiUrl,
          clientId: payload.data.clientId,
          clientSecret: payload.data.clientSecret,
        },
      });

      // The the options page the save was succesfull
      app.ports.messageReceiver.send("success");
    } else if (payload.action === "reset") {
      await browser.storage.local.remove("settings");
      // The the options page the reset was succesfull
      app.ports.messageReceiver.send("resetDone");
    }
  });

  // 2022-09-06: actually is this needed ?
  // There are only interaction flows outbound of the options page,
  // nothing inbound iirc.
  /*
  const OPTIONS_BACKGROUND_MESSAGES = ["resetDone"];
  browser.runtime.onMessage.addListener((msg) => {
    // This is needed because we expect a `Nothing` in Elm land.
    if (!msg.data) msg.data = null;

    // The same port is used for options/bg/popup communications.
    // Filter the messages that are meant for the options page.
    if (OPTIONS_BACKGROUND_MESSAGES.some((p) => p === msg.action)) {
      app.ports.messageReceiver.send(msg);
    }
  });
  */
})();
