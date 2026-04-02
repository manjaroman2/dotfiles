import shutil 
from pathlib import Path
import datetime
import subprocess
from common import base, save, ignore

for d in save:
    src = Path.home() / d
    dst = base / d
    if src.is_file():
        shutil.copyfile(src=src, dst=dst)
    elif src.is_dir():
        shutil.copytree(src=src, dst=dst, dirs_exist_ok=True, ignore=ignore)

subprocess.run(["git", "add", "."], check=True)
cm = datetime.datetime.now().isoformat()
result = subprocess.run(["git", "commit", "-am", cm], capture_output=True, text=True)
if result.stdout or result.stderr:
    print(result.stdout)
    print(result.stderr)
subprocess.run(["git", "push"], check=True)
