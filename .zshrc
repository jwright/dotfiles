# ENVIRONMENT VARIABLES #
#########################

# No brainer, default to Vim
export EDITOR="vim"

# Color LS output to differentiate between directories and files
export LS_OPTIONS="--color=auto"
export CLICOLOR="Yes"
export LSCOLOR=""

# Speed up the rubies
export RUBY_GC_MALLOC_LIMIT=60000000
export RUBY_GC_HEAP_FREE_SLOTS=200000

# Add sbin, Homebrew, Postgres.app, and NPM related directories to path
export PATH=/sbin:$PATH
export PATH=/usr/local/bin:$HOME/bin:$PATH
export PATH=/Applications/Postgres93.app/Contents/MacOS/bin:$PATH
export PATH=/usr/local/share/npm/bin:$PATH

# Configure GOPATH and add go/bin to Path
export GOPATH=$HOME/projects/go
export PATH=$GOPATH/bin:$PATH

# Add GOROOT to PATH for access to godoc
export PATH=$PATH:/usr/local/Cellar/go/1.2/libexec/bin

# Configure chruby
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh

# Setup web
export PORT=5000

# Setup MONGO
export MONGO_PATH=/data/db

# Setup NODE_PATH
export NODE_PATH=$NODE_PATH:/usr/local/share/npm/lib/node_modules
export NVM_DIR="$HOME/.nvm"
  . "/usr/local/opt/nvm/nvm.sh"

# Setup REDIS
export REDIS_PORT=6379

# ALIASES #
###########

# Dotfiles
alias dot='cd ~/projects/dotfiles'

# Brew casks
alias casks='open /opt/homebrew-cask/Caskroom'

# Standard Shell
alias c='clear'
alias l='ls -l'
alias la='ls -al'
alias bloat='du -k | sort -nr | more'

# Bundle Exec
alias be="bundle exec"

# Git
alias g='git status -s'
alias gb='git branch'
alias gc='git commit -m'
alias gp='git push'
alias gpr='git pr'
alias gca='git commit -am'
alias gco='git checkout'
alias gcob='git checkout -b'
alias grpr='git remote prune origin'
alias grc='git rebase --continue'

# Gitignores
alias objc-ignore='cp ~/projects/gitignore/Objective-C.gitignore .gitignore'

# ngrok
alias ngrok='/Applications/ngrok'

# tmux
alias attach='tmux attach-session -t'
alias switch='tmux switch-session -t'
alias tmk='tmux kill-session -t'
alias tls='tmux ls'
alias start='tmuxinator start'

# Server fanciness with python
alias server='open http://localhost:1337/ && python -m SimpleHTTPServer 1337'

# Ruby REPLs & Pry for Rails
alias pryr='pry --simple-prompt -r ./config/environment'

# Xcode
alias pngcrush='/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/pngcrush -q -revert-iphone-optimizations -d'

# Quick way to rebuild the Launch Services database and get rid
# of duplicates in the Open With submenu.
alias fixopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user'

# Flush DNS Cache
alias dnsflush='dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# Tatsu
alias tatsu='heroku run rake console -a tatsu-production'

# ZSH CONFIGURATION #
#####################

# Turn off Vi mode
bindkey -e

# Source zsh syntax highlighting
[[ -s $HOME/bin/zsh-syntax-highlighting.zsh ]] && source $HOME/bin/zsh-syntax-highlighting.zsh

# Source Marked.app command line function
[[ -s $HOME/bin/marked.sh ]] && source $HOME/bin/marked.sh

# Source Tmuxinator if installed
[[ -s $HOME/.tmuxinator/scripts/tmuxinator ]] && source $HOME/.tmuxinator/scripts/tmuxinator

# Virtualenv & Virtualenvwrapper setup if installed
VIRTUAL_ENV_DISABLE_PROMPT=1
if which virtualenv > /dev/null;
then
  VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python
  export WORKON_HOME=$HOME/.virtualenvs
  source /usr/local/bin/virtualenvwrapper.sh
  export PIP_VIRTUALENV_BASE=$WORKON_HOME
fi

# Load completions for Ruby, Git, etc.
autoload compinit && compinit -C

# Make git completions not be ridiculously slow
__git_files () {
  _wanted files expl 'local files' _files
}

# Case insensitive auto-complete
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# PROMPT FUNCTIONS AND SETTINGS #
#################################

# Colors
BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

autoload -U colors && colors
setopt prompt_subst

# Set default ruby
chruby 2.4

# Display Virtualenv cleanly in right column
function virtualenv_info {
  [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

# Display wheather you are in a Git or Mercurial repo
function prompt_char {
  git branch >/dev/null 2>/dev/null && echo ' ±' && return
  hg root >/dev/null 2>/dev/null && echo ' ☿' && return
  echo ' ○'
}

# Display current ruby version
function ruby_info {
  echo "$(ruby -v | sed 's/.* \([0-9p\.]*\) .*/\1/')"
}

# Show previous command status
local command_status="%(?,%{$fg[green]%}✔%{$reset_color%},%{$fg[red]%}✘%{$reset_colors%})"

# Show relative path on one line, then command status
PROMPT='
%{$fg[cyan]%}%n@%m %{$fg[white]%}: %{$fg[cyan]%}%~ %{$fg[white]%}
${command_status} %{$reset_color%} '

# Show virtualenv, rbenv, branch, sha, and repo dirty status on right side
RPROMPT='%{$fg[cyan]%}$(virtualenv_info)%{$fg[white]%}$(ruby_info)$(prompt_char)$(~/bin/git-cwd-info.sh)%{$reset_colors%}'

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
