import requests
import warnings
from urllib.parse import quote_plus
warnings.filterwarnings("ignore", category=RuntimeWarning)
import json
import sys
from pathlib import Path

packages_file = Path('xanados-iso/packages.x86_64')
if not packages_file.exists():
    print('packages file not found')
    sys.exit(1)

with packages_file.open() as f:
    packages = [line.strip() for line in f if line.strip() and not line.startswith('#')]

seen = set()
duplicates = []
missing_packages = []
results = {}

for pkg in packages:
    if pkg in seen:
        duplicates.append(pkg)
        continue
    seen.add(pkg)
    arch_url = f'https://archlinux.org/packages/search/json/?name={quote_plus(pkg)}'
    res = requests.get(arch_url, timeout=10, verify=False)
    if res.ok and res.json().get('results'):
        results[pkg] = 'arch'
        continue
    aur_url = f'https://aur.archlinux.org/rpc/?v=5&type=info&arg={quote_plus(pkg)}'
    res = requests.get(aur_url, timeout=10, verify=False)
    if res.ok and res.json().get('resultcount', 0) > 0:
        results[pkg] = 'aur'
    else:
        results[pkg] = 'missing'
        missing_packages.append(pkg)

print('Duplicate packages:', duplicates)
print('Missing packages:', missing_packages)
print('Summary:')
for pkg, src in results.items():
    print(f'{pkg}: {src}')
