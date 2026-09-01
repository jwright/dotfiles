eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(pyenv init --path)"

source ~/.cf2_secrets

# allow for persistent history between iex sessions
export ERL_AFLAGS="-kernel shell_history enabled"
eval "$(mise activate zsh --shims)"

# >>> Codex installer >>>
export PATH="/Users/jwright/.local/bin:$PATH"
# <<< Codex installer <<<
export PATH="/opt/cloud66/bin:${PATH}"
