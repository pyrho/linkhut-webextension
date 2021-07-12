# Linkhut webextension

## TODO
- [ ] register oauth app
- [ ] oauth flow
- [ ] get suggested tags

## Bugs
- [ ] OAUth flow when user is logged out fails to redirect to correct original URL
    - the url is just `https://ln.ht/_/oauth/authorize`
    - make sure this is real
    - it is
- [x] fix sr.ht docs typo @ https://docs.linkhut.org/overview.html#oauth-applications
- [ ] fails when redirect_uri endsWith a trailing `/`
- [ ] "They would like permission to access the following resources on your account: "  is empty

## Dump

Application ID
    b933dc378d12877e9d2ede0cd23c896fb314315316210ff64368462ab6456416
Application Secret
    d2b9b18a2366033da955ce2ce7e9d5a18b5bd760c673a00c48792cf233261b8f 

https://7cbf31398b3b68cc258a89745b9f12854af81164.extensions.allizom.org/

https://ln.ht/_/oauth/authorize?response_type=code&client_id=b933dc378d12877e9d2ede0cd23c896fb314315316210ff64368462ab6456416&scopes=posts:write&redirect_uri=https://7cbf31398b3b68cc258a89745b9f12854af81164.extensions.allizom.org/
https://github.com/mdn/webextensions-examples/blob/master/google-userinfo/options/options.js
https://ln.ht/_/oauth/authorize?response_type=code&client_id=b933dc378d12877e9d2ede0cd23c896fb314315316210ff64368462ab6456416&redirect_uri=https%3A%2F%2F7cbf31398b3b68cc258a89745b9f12854af81164.extensions.allizom.org%2F&scope=posts%3Awrite
https://ln.ht/_/oauth/authorize?response_type=code&client_id=b933dc378d12877e9d2ede0cd23c896fb314315316210ff64368462ab6456416&redirect_uri=https%3A%2F%2F7cbf31398b3b68cc258a89745b9f12854af81164.extensions.allizom.org%2F&scopes=posts%3Awrite
