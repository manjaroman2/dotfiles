import shutil 
from pathlib import Path
import datetime
import subprocess

base = Path(__file__).parent
save = [
".config/nvim",
]
for d in save:
    shutil.copytree(Path.home() / d, base / d, dirs_exist_ok=True)

subprocess.run(["git", "add", "."], check=True)
cm = datetime.datetime.now().isoformat()
subprocess.run(["git", "commit", "-am", cm], check=True)

subprocess.run(["git", "push"], check=True)
