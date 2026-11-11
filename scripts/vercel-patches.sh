#!/bin/bash
# Patches cal.diy for Vercel build compatibility.
# Run after yarn install, before next build.
set -e
cd "$(dirname "$0")/.."

echo "[patch] 1/3: rmdirSync → rmSync (Node 22+ compat)"
sed -i 's/rmdir/rm/g' node_modules/zod-prisma-types/dist/classes/directoryHelper.js

echo "[patch] 2/3: remove throws + turbopack from next.config.ts"
sed -i -e '/Please set/d' -e '/turbopack: {}/d' apps/web/next.config.ts

echo "[patch] 3/3: add webpack config to handle node: imports"
python3 << 'PYEOF'
import re
with open('apps/web/next.config.ts') as f:
    content = f.read()

if 'node:process' in content:
    print('  already patched')
else:
    # Build alias map for common node: builtins
    node_modules = ['process', 'path', 'fs', 'crypto', 'stream', 'util', 'buffer',
                    'os', 'url', 'child_process', 'http', 'https', 'net', 'tls',
                    'zlib', 'events', 'querystring', 'string_decoder', 'timers',
                    'worker_threads', 'perf_hooks', 'assert', 'dns', 'dgram',
                    'cluster', 'readline', 'repl', 'vm', 'tty', 'v8', 'sys',
                    'punycode', 'module', 'inspector', 'async_hooks', 'trace_events']
    alias_str = ', '.join(f'"node:{m}": "{m}"' for m in node_modules)

    patch = f'''    webpack: (config) => {{
      config.resolve.alias = {{ ...config.resolve.alias, {alias_str} }};
      return config;
    }},
'''
    # Insert before "async rewrites()"
    if 'async rewrites()' in content:
        content = content.replace('    async rewrites()', patch + '    async rewrites()')
        with open('apps/web/next.config.ts', 'w') as f:
            f.write(content)
        print('  patched: webpack node: aliases added')
    else:
        print('  WARNING: "async rewrites()" not found in next.config.ts')
PYEOF

echo "[patch] done"
