source /usr/share/cachyos-fish-config/cachyos-config.fish

function vi
    if test (count $argv) -eq 0
        nvim .
    else
        nvim $argv
    end
end
export PATH="$PATH:/home/marc/bin/"
export PATH="$PATH:/usr/local/texlive/2025/bin/x86_64-linux"
function fish_greeting
end
set -x PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
pyenv init - | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

function _disable_git_prompt_on_sshfs --on-variable PWD
    if string match -q "$HOME/studium*" $PWD
        set -gx GIT_OPTIONAL_LOCKS 0
    end
end
