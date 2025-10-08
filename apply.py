import shutil 
from pathlib import Path
import subprocess

from common import base, save

result = subprocess.run(["git", "pull"], capture_output=True, text=True)
if result.stdout or result.stderr:
    print(result.stdout)
    print(result.stderr)

for d in save:
    src = base / d
    dst = Path.home() / d
    if src.is_file():
        shutil.copyfile(src=src, dst=dst)
    elif src.is_dir():
        shutil.copytree(src=src, dst=dst, dirs_exist_ok=True)
