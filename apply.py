import shutil 
from pathlib import Path
import subprocess

from common import base, save


result = subprocess.run(["git", "pull"], capture_output=True, text=True)
if result.stdout or result.stderr:
    print(result.stdout)
    print(result.stderr)

for d in save:
    shutil.copytree(base / d, Path.home() / d, dirs_exist_ok=True)
