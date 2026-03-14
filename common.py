from pathlib import Path
from shutil import ignore_patterns

base = Path(__file__).parent
save = [
    ".config/nvim",
    ".config/alacritty",
    ".config/tmux",
    ".config/fish",
    ".config/btop",
    ".config/waybar",
    ".config/hypr",
    ".XCompose",
]
ignore = ignore_patterns(".git")
