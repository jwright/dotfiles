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
export PATH=/opt/homebrew/bin:$PATH
export PATH=/Applications/Postgres93.app/Contents/MacOS/bin:$PATH
export PATH=/usr/local/share/npm/bin:$PATH

# Configure GOPATH and add go/bin to Path
export GOPATH=$HOME/projects/go
export PATH=$GOPATH/bin:$PATH

# Add GOROOT to PATH for access to godoc
export PATH=$PATH:/usr/local/Cellar/go/1.2/libexec/bin

# Add fucking PHP Composer
export PATH=$HOME/.composer/vendor/bin:$PATH

# Ruby install configuration
export RUBY_CONFIGURE_OPTS="\
  --disable-install-doc \
  --with-libyaml-dir=/opt/homebrew/opt/libyaml \
  --with-openssl-dir=/opt/homebrew/opt/openssl@1.1 \
  --with-zlib-dir=/opt/homebrew/opt/zlib \
  --without-tcl \
  --without-tk \
"

# gdbm
export LDFLAGS="-L/opt/homebrew/opt/gdbm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/gdbm/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/gdbm/lib/pkgconfig"

# Libffi
export LDFLAGS="-L/opt/homebrew/opt/libffi/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"

# libyaml
export LDFLAGS="-L/opt/homebrew/opt/libyaml/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/libyaml/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libyaml/lib/pkgconfig:$PKG_CONFIG_PATH"

# Readline
export LDFLAGS="-L/opt/homebrew/opt/readline/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/readline/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

# OpenSSL
export PATH="/opt/homebrew/opt/openssl@1.1/bin:$PATH"
# export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib $LDFLAGS"
# export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include $CPPFLAGS"
# export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig:$PKG_CONFIG_PATH"
# export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:$PKG_CONFIG_PATH"

# MySQL
export PATH="/opt/homebrew/opt/mysql-client@8.0/bin:$PATH"

# Configure chruby
# source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
# source /opt/homebrew/opt/chruby/share/chruby/auto.sh

# The following lines were added by compinstall
zstyle :compinstall filename '/Users/jwright/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Setup web
export PORT=5000

# Setup MONGO
export MONGO_PATH=/data/db

# Setup NODE_PATH
export NODE_PATH=$NODE_PATH:/usr/local/share/npm/lib/node_modules
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Setup REDIS
export REDIS_PORT=6379

# ALIASES #
###########

# Dotfiles
alias dot='cd ~/Projects/kt-dotfiles'

# Brew casks
alias casks='open /opt/homebrew-cask/Caskroom'

# Standard Shell
alias c='clear'
alias l='ls -l'
alias la='ls -al'
alias bloat='du -k | sort -nr | more'

# Bundle Exec
alias be="bundle exec"

# bin/rails
alias br="bin/rails"

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
# chruby 2.7.2

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

# Show virtualenv, what Ruby, branch, sha, and repo dirty status on right side
RPROMPT='%{$fg[cyan]%}$(virtualenv_info)%{$fg[white]%}$(ruby_info)$(prompt_char)$(~/bin/git-cwd-info.sh)%{$reset_colors%}'

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

### Gigalixir
export PATH=~/.local/bin:$PATH

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install

eval "$(mise activate zsh)"
export PATH="$HOME/.local/share/mise/shims:$PATH"

eval "$(direnv hook zsh)"
eval "$(pyenv init -)"
source /Users/jwright/.config/op/plugins.sh

# Configure asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# CFLAGS compiler flags
export CFLAGS="-Wno-default-const-init-field-unsafe"

# Added by Windsurf
export PATH="/Users/jwright/.codeium/windsurf/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/jwright/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# OpenClaw Completion
source "/Users/jwright/.openclaw/completions/openclaw.zsh"
