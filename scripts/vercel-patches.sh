#!/bin/bash
# Patches cal.diy for Vercel build compatibility.
# Run after yarn install, before next build.
set -e
cd "$(dirname "$0")/.."

echo "[patch] 1/3: rmdirSync → rmSync (Node 22+ compat)"
sed -i 's/rmdir/rm/g' node_modules/zod-prisma-types/dist/classes/directoryHelper.js

echo "[patch] 2/3: remove throws + turbopack from next.config.ts"
sed -i -e '/Please set/d' -e '/turbopack: {}/d' apps/web/next.config.ts

echo "[patch] 3/3: add NormalModuleReplacementPlugin to handle node: imports in webpack"
python3 << 'PYEOF'
with open('apps/web/next.config.ts') as f:
    content = f.read()

if 'NormalModuleReplacementPlugin' in content:
    print('  already patched with NormalModuleReplacementPlugin')
else:
    # Remove any previous webpack: config we added (resolve.alias approach)
    import re
    content = re.sub(
        r'\s*webpack: \(config\) => \{\s*config\.resolve\.alias = \{[^}]+\};\s*return config;\s*\},?\s*',
        '\n',
        content
    )

    # Insert NormalModuleReplacementPlugin before "async rewrites()"
    patch = '''    webpack: (config, { webpack: webpackInstance }) => {
      config.plugins.push(
        new webpackInstance.NormalModuleReplacementPlugin(/^node:/, (resource) => {
          resource.request = resource.request.replace(/^node:/, '');
        })
      );
      return config;
    },
'''
    if 'async rewrites()' in content:
        content = content.replace('    async rewrites()', patch + '    async rewrites()')
        with open('apps/web/next.config.ts', 'w') as f:
            f.write(content)
        print('  patched: NormalModuleReplacementPlugin added for node: imports')
    else:
        print('  WARNING: "async rewrites()" not found')
PYEOF

echo "[patch] done"
