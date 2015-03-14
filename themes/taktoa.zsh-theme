# the idea of this theme is to contain a lot of info in a small string, by
# compressing some parts and colorcoding, which bring useful visual cues,
# while limiting the amount of colors and such to keep it easy on the eyes.
# When a command exited >0, the timestamp will be in red and the exit code
# will be on the right edge.
# The exit code visual cues will only display once.
# (i.e. they will be reset, even if you hit enter a few times on empty command prompts)

typeset -A host_repr

# translate hostnames into shortened, colorcoded strings
host_repr=('REMY-SYSTEM76' "%{$fg_bold[red]%}s76"
           'REMYDESKTOP'   "%{$fg_bold[green]%}dsk"
           'REMYSERVER'    "%{$fg_bold[blue]%}srv"
           'sebastian'     "%{$fg_bold[cyan]%}ssv")

# user part, color coded by privileges
local user="%(!.%{$fg[blue]%}.%{$fg[blue]%})%n%{$reset_color%}"

# Hostname part.  compressed and colorcoded per host_repr array
# if not found, regular hostname in default color
local host="@${host_repr[$HOST]:-$HOST}%{$reset_color%}"

local nixshell="%{$fg[green]%}$IN_NIX%{$reset_color%}"

# Compacted $PWD
local pwd="%{$fg[blue]%}%c%{$reset_color%}"

function get-tmux-window () {
  tmux lsw | grep active | sed 's/\*.*$//g;s/: / /1' | awk '{ print $2 "-" $1 }' -
}

function get-screen-window () {
  initial="$(screen -Q windows; screen -Q echo '')"
  middle="$(echo $initial | sed 's/  /\n/g' | grep '\*' | sed 's/\*\$ / /g')"
  echo $middle | awk '{ print $2 "-" $1 }' -
}

function multiplexer-prompt () {
  if [[ -z $TMUX ]]; then
  else
    get-tmux-window
  fi
  if [[ -z $WINDOW ]]; then
  else
    get-screen-window
  fi
}

PROMPT='${user}${host} ${pwd} ${nixshell}$(git_prompt_info)λ '

# i would prefer 1 icon that shows the "most drastic" deviation from HEAD,
# but lets see how this works out
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[green]%} %{$fg[yellow]%}?%{$fg[green]%}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[green]%}"

# elaborate exitcode on the right when >0
return_code_enabled="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"
return_code_disabled=
return_code=$return_code_enabled

RPS1='${return_code}'

function accept-line-or-clear-warning () {
	if [[ -z $BUFFER ]]; then
		time=$time_disabled
		return_code=$return_code_disabled
	else
		time=$time_enabled
		return_code=$return_code_enabled
	fi
	zle accept-line
}
zle -N accept-line-or-clear-warning
bindkey '^M' accept-line-or-clear-warning
