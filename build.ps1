docker build `
  --build-arg GITHUB_USER=$env:GH_USER `
  --build-arg GITHUB_TOKEN=$env:GH_TOKEN `
  --build-arg BUILD_CONFIGURATION=Release `
  --build-arg INF_VER='local.build' `
  --build-arg SEMVER='1' `
  --build-arg RELEASE_TAG='T' `
  -t ghcr.io/orion6dev/pg-german:local .