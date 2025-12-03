from pathlib import Path
from shutil import ignore_patterns

base = Path(__file__).parent
save = [
    ".config/nvim",
    ".XCompose",
]
ignore = ignore_patterns(".git")
