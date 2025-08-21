# PurseCraft

[![gh-actions](https://github.com/pursecraft/pursecraft/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/pursecraft/pursecraft/actions?workflow=CI)
[![codecov](https://codecov.io/gh/pursecraft/pursecraft/branch/main/graph/badge.svg?token=V2XIAKYFOo)](https://codecov.io/gh/pursecraft/pursecraft)

## Quick Start

```
git clone git@github.com:pursecraft/pursecraft.git
cd pursecraft
cp .envrc.example .envrc
direnv allow
mix deps.get
mix ecto.setup.dev
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
