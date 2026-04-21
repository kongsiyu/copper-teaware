# Copper Teaware Shopify Store

Shopify store for copper teaware, coffee ware, and tableware.

- **Store URL**: https://copper-teaware.myshopify.com
- **GitHub**: https://github.com/kongsiyu/copper-teaware

## Project Structure

```
/
├── theme/          # Shopify theme customizations
├── scripts/        # Automation & deployment scripts
├── docs/           # Product docs, brand guidelines
└── assets/         # Product images, brand assets
```

## Getting Started

1. Install [Shopify CLI](https://shopify.dev/docs/themes/tools/cli)
2. Connect to store: `shopify theme dev --store copper-teaware.myshopify.com`
3. Push theme changes: `shopify theme push`

## Git Workflow

- Before making changes, always run `git fetch origin && git pull --ff-only` in this parent repo so local work starts from the latest remote state.
- After completing changes in this repo, you must commit and push them. Do not leave required delivery changes only in the local worktree.
- The `theme/` directory is a git submodule that points to the Shopify theme repository: `https://github.com/kongsiyu/copper-teaware-theme.git`.
- Shopify theme code must be committed and pushed directly to the `theme` repo `main` branch. GitHub then auto-syncs that branch to Shopify.
- After pushing `theme`, update the parent repo submodule pointer, commit the parent repo change, and push the parent repo as well.
- If `theme` local history diverges from `origin/main`, do not force-push. Rebase or replay the intended delta onto the latest `origin/main`, then push normally.
