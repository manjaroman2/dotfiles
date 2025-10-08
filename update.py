import shutil 
from pathlib import Path
import datetime
import subprocess
from common import base, save

for d in save:
    shutil.copytree(Path.home() / d, base / d, dirs_exist_ok=True)

subprocess.run(["git", "add", "."], check=True)
cm = datetime.datetime.now().isoformat()
result = subprocess.run(["git", "commit", "-am", cm], capture_output=True, text=True)
if result.stdout or result.stderr:
    print(result.stdout)
    print(result.stderr)
subprocess.run(["git", "push"], check=True)
