# API

#### `shared.rBundle.install(repo: string)`

Installs a bundle from a GitHub repository string formatted as `owner/repository`

#### `shared.rBundle.install(repoList: { string })`

Installs bundles from GitHub repositories formatted as `owner/repository`

#### `shared.rBundle.list()`

List locally installed bundles

#### `shared.rBundle.info(bundle_id: string)`

Fetch info from a locally installed bundle passing in its id

#### `shared.rBundle.getToken()`

Returns the set GitHub API token

#### `shared.rBundle.getDirectory()`

Returns the set bundle installation directory

#### `shared.rBundle.setToken(token: string)`

Set the GitHub API token

#### `shared.rBundle.setDirectory(directory: Instance)`

Set the bundle installation directory (default is `ReplicatedStorage/Bundles`)
