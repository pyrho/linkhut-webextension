const BASE_URL_API = "http://10-25-47-4.sslip.io:4000/_";
const appendTagToField = newTag => {
    const tags = document
        .querySelector("#tags")
        .value?.split(",")
        .filter(e => !!e);
    tags.push(newTag);
    document.querySelector("#tags").value = tags.join(",");
};
const fetchRecommended = async credentials => {
    const u = `${BASE_URL_API}/v1/posts/suggest?url=${encodeURIComponent(
        document.querySelector("#url").getAttribute("value"),
    )}`;
    const rawReq = await fetch(u, {
        method: "GET",
        headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": `Bearer ${credentials.access_token}`,
        },
    });
    const tags = await rawReq.json();
    const recommendedTags = [...tags?.[0]?.popular, ...tags?.[1]?.recommended];
    recommendedTags.forEach(t => {
        var a = document.createElement("a");
        var linkText = document.createTextNode(t);
        a.appendChild(linkText);
        a.href = "#";
        a.className = "is-link";
        a.dataset.tagValue = t;
        a.onclick = function (e) {
            e.preventDefault();
            appendTagToField(e.target.dataset.tagValue);
        };
        window.document.querySelector("#reco").appendChild(a);
        const spacer = window.document.createElement("span");
        spacer.appendChild(document.createTextNode("  "));
        window.document.querySelector("#reco").appendChild(spacer);
    });
};

const getUrl = () => document.querySelector("#url").value;
const getTitle = () => document.querySelector("#title").value;
const getNote = () => document.querySelector("#note").value;
const getTags = () => document.querySelector("#tags").value;
const getIsPriv = () => document.querySelector("#is_private:checked")?.value;

const setupButtonHandlers = credentials => {
    document
        .querySelector("#cancel")
        .addEventListener("click", () => window.close());
    document.querySelector("#ok").addEventListener("click", async () => {
        document.querySelector("#ok").className += " is-loading";
        const u = `${BASE_URL_API}/v1/posts/add\
?url=${encodeURIComponent(getUrl())}\
&description=${encodeURIComponent(getTitle())}\
&extended=${encodeURIComponent(getNote())}\
&tags=${encodeURIComponent(getTags())}
&shared=${getIsPriv() ? "no" : "yes"}`;

        const rawReq = await fetch(u, {
            method: "GET",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": `Bearer ${credentials.access_token}`,
            },
        });

        const resp = await rawReq.json();
        if (resp.result_code === "done") {
            window.close();
        } else {
            document.querySelector("#ok").className = "button is-danger";
            document.querySelector("#ok").innerText = "Ooops";
        }
    });

    window.document
        .querySelector("#authorize")
        .addEventListener("click", () =>
            browser.runtime.sendMessage({ type: "auth" }),
        );
};

const fillInCurrentUrl = async () => {
    const tabs = await browser.tabs.query({ active: true });
    if (tabs.length !== 1) {
        throw new Error("Something went wrong, cannot get current tab.");
    }
    document.querySelector("#url").setAttribute("value", tabs[0].url);
    document.querySelector("#title").setAttribute("value", tabs[0].title);
};

const shouldLogIn = async () => {
    const credentials = await browser.storage.local.get("credentials");
    if (credentials?.credentials?.access_token?.length ?? 0 > 0) {
        return false;
    } else {
        return true;
    }
};

const switchUiForLogin = credentials => {
    console.log(credentials?.access_token?.length ?? 0 === 0);

    const baseSectionClasses = "section is-small";
    const hiddenSection = `${baseSectionClasses} is-hidden`;
    if (!credentials?.access_token?.length) {
        document.querySelector("#loggedin").className = hiddenSection;
        document.querySelector("#loggedout").className = baseSectionClasses;
    } else {
        document.querySelector("#loggedin").className = baseSectionClasses;
        document.querySelector("#loggedout").className = hiddenSection;
    }
};

const getCredentials = async () => {
    const credentials = await browser.storage.local.get("credentials");
    return credentials?.credentials ?? null;
};

window.onload = async () => {
    const credentials = await getCredentials();
    switchUiForLogin(credentials);
    setupButtonHandlers(credentials);
    await fillInCurrentUrl();
    await fetchRecommended(credentials);
};

browser.runtime.onMessage.addListener(() => {
    getCredentials().then(switchUiForLogin);
});
