import { getAccessToken } from "/background/authorize.js";
import logger from "/background/logger.js";

function doAuth() {
  getAccessToken()
    .then(() => {
      browser.runtime.sendMessage({ action: "authSuccess" });
    })
    .catch((e) => {
      logger.error("An error occured");
      logger.error(e);
      browser.runtime.sendMessage({ action: "error" });
    });
}

function handleMessage(request) {
  logger.log(`Got message from popup: ${JSON.stringify(request)}`);
  switch (request.action) {
    case "auth":
      doAuth();
  }
}

browser.runtime.onMessage.addListener(handleMessage);
