#!/usr/bin/env zsh
### -*- mode: sh; sh-shell: zsh -*-
### File: parallax/port-parser.scm
##
### License:
## Copyright © 2015 Remy Goldschmidt <taktoa@gmail.com>
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
## THE SOFTWARE.
##
### Author:   Remy Goldschmidt <taktoa@gmail.com>
##
### Homepage: https://github.com/taktoa/oh-my-zsh
##
### Commentary:
##+# My zsh theme.
##
### Code:

### ----------------------------------------------------------------------------
### ----------------------------- Custom variables -----------------------------
### ----------------------------------------------------------------------------

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''

### ----------------------------------------------------------------------------
### ---------------------------- Utility functions -----------------------------
### ----------------------------------------------------------------------------

message () {
    local COLOR="${fg[${1}]}"
    local NAME="${2}"
    shift 2
    echo "${COLOR}[${NAME}]${reset_color} $@"
}

debug-msg () {
    message or   DEBUG   "$@" 1>&2
}

info-msg () {
    message green  INFO    "$@" 1>&2
}

warning-msg () {
    message yellow WARNING "$@" 1>&2
}

error-msg () {
    message red    ERROR   "$@" 1>&2
}

usage-msg () {
    message white  Usage   "$@" 1>&2
}

# Useful alias
err () { error-msg "$@"; }

valid-color () {
    if (( $# != 1 )) || [[ -z "${1}" ]] || [[ -z "${color[${1}]}" ]]; then
        return -1
    fi
    return 0
}

col-reset () {
    if (( $# != 0 )); then err "col-reset: invalid arguments: $@"; return -1; fi
    echo -n "%{$reset_color%}"
}

col-fg () {
    if (( $# != 1 )) || [[ -z "${1}" ]]; then
        err "col-fg: invalid arguments: $@"; return -1
    fi
    if ! valid-color "${1}"; then
        err "col-fg: invalid color: ${1}"; return -1
    fi
    echo -n "%{$fg[${1}]%}";
}

col-bfg () {
    if (( $# != 1 )) || [[ -z "${1}" ]]; then
        err "col-bfg: invalid arguments: $@"; return -1
    fi
    if ! valid-color "${1}"; then
        err "col-bfg: invalid color: ${1}"; return -1
    fi
    echo -n "%{$fg_bold[${1}]%}";

}

crs () {
    if (( $# != 1 )) || [[ -z "${1}" ]]; then
        error-msg "crs: invalid arguments"
        return -1
    fi
    echo -n "%{${1}%}"
}

prompt-segment() {
    local bg fg cbg sep
    cbg="${CURRENT_BG}"
    sep="${SEGMENT_SEPARATOR}"
    [[ -n "$1" ]] && bg="%K{$1}" || bg="%k"
    [[ -n "$2" ]] && fg="%F{$2}" || fg="%f"
    if [[ "${cbg}" != 'NONE' && "${1}" != "${cbg}" ]]; then
        echo -n " $(crs ${bg})$(crs %F{${cbg}})${sep}$(crs ${fg}) "
    else
        echo -n "$(crs ${bg})$(crs ${fg}) "
    fi
    CURRENT_BG="${1}"
    [[ -n "${3}" ]] && echo -n "${3}"
}

# End the prompt, closing any open segments
prompt-end() {
    local bg fg cbg sep
    cbg="${CURRENT_BG}"
    sep="${SEGMENT_SEPARATOR}"
    if [[ -n "${cbg}" ]]; then
        echo -n " $(crs %k%F{${cbg}})${sep}"
    else
        echo -n "%{%k%}"
    fi
    echo -n "%{%f%}"
    CURRENT_BG=''
}

### ----------------------------------------------------------------------------
### --------------------------- Generator functions ----------------------------
### ----------------------------------------------------------------------------

prompt-context () {
    local -A hostAbbrev
    hostAbbrev=('REMY-SYSTEM76' "$(col-fg red  )s76"
                'REMYDESKTOP'   "$(col-fg green)dsk"
                'REMYSERVER'    "$(col-fg blue )srv")
    local user host
    user="%(!.$(col-fg red).$(col-fg blue))%n"
    host="${hostAbbrev[${HOST}]:-${HOST}}"
    prompt-segment black default "${user}@${host}"
}

prompt-nix () {
    if [[ "${IN_NIX_SHELL}" = "1" ]]; then
        if [[ -z "${IN_NIX}" ]]; then IN_NIX="nix"; fi
        prompt-segment green black "${IN_NIX}"
    fi
}

prompt-virtualenv() {
    if [[ -n "${VIRTUAL_ENV}" && -n "${VIRTUAL_ENV_DISABLE_PROMPT}" ]]; then
        prompt-segment green black "$(basename \"${VIRTUAL_ENV}\")"
    fi
}

prompt-pwd () {
    prompt-segment blue black "%c"
}

prompt-multiplexer () {
    function get-tmux-window () {
        tmux lsw                        \
            | grep active               \
            | sed 's/\*.*$//g;s/: / /1' \
            | awk '{ print $2 "-" $1 }' -
    }
    
    function get-screen-window () {
        echo "$(screen -Q windows; screen -Q echo '')" \
            | sed 's/  /\n/g'                          \
            | grep '\*'                                \
            | sed 's/\*\$ / /g'                        \
            | awk '{ print $2 "-" $1 }' -
    }
    
    [[ -n $TMUX ]]   && prompt-segment cyan black "$(get-tmux-window)"
    [[ -n $WINDOW ]] && prompt-segment cyan black "$(get-screen-window)"
    unset get-tmux-window get-screen-window
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt-status () {
    local symbols
    symbols=()
    [[ $RETVAL -ne 0 ]]            && symbols+="$(col-fg red)✘"
    [[ $UID -eq 0 ]]               && symbols+="$(col-fg yellow)⚡"
    [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="$(col-fg cyan)⚙"
    [[ -n "$symbols" ]]            && prompt-segment black default "$symbols"
}

# prompt-git () {
#     local prefix suffix dirty clean
#     prefix="$(col-fg yellow)"
#     suffix="$(col-reset) "
#     dirty="$(col-fg green) $(col-fg yellow)?$(col-fg green)$(col-reset)"
#     clean="$(col-fg green)"
#     ZSH_THEME_GIT_PROMPT_PREFIX="$prefix"
#     ZSH_THEME_GIT_PROMPT_SUFFIX="$suffix"
#     ZSH_THEME_GIT_PROMPT_DIRTY="$dirty"
#     ZSH_THEME_GIT_PROMPT_CLEAN="$clean"
#     git_prompt_info
# }

prompt-git () {
    local ref dirty mode repo_path
    repo_path=$(git rev-parse --git-dir 2>/dev/null)

    if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
        dirty=$(parse_git_dirty)
        ref=$(git symbolic-ref HEAD 2> /dev/null) \
            || ref="➦ $(git show-ref --head -s --abbrev | head -n1 2>/dev/null)"
        if [[ -n $dirty ]]; then
            prompt-segment yellow black
        else
            prompt-segment green black
        fi

        if [[ -e "${repo_path}/BISECT_LOG" ]]; then
            mode=" <B>"
        elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
            mode=" >M<"
        elif [[ -e "${repo_path}/rebase"       \
                      || -e "${repo_path}/rebase-apply" \
                      || -e "${repo_path}/rebase-merge" \
                      || -e "${repo_path}/../.dotest" ]]; then
            mode=" >R>"
        fi

        setopt promptsubst
        autoload -Uz vcs_info
        zstyle ':vcs_info:*'     enable            git
        zstyle ':vcs_info:*'     get-revision      true
        zstyle ':vcs_info:*'     check-for-changes true
        zstyle ':vcs_info:*'     stagedstr         '✚'
        zstyle ':vcs_info:git:*' unstagedstr       '●'
        zstyle ':vcs_info:*'     formats           ' %u%c'
        zstyle ':vcs_info:*'     actionformats     ' %u%c'
        vcs_info
        echo -n "${ref/refs\/heads\// }${vcs_info_msg_0_%% }${mode}"
    fi
}

prompt-hg () {
    local rev status
    if $(hg id >/dev/null 2>&1); then
        if $(hg prompt >/dev/null 2>&1); then
            if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
                # if files are not added
                prompt-segment red white
                st='±'
            elif [[ -n $(hg prompt "{status|modified}") ]]; then
                # if any modification
                prompt-segment yellow black
                st='±'
            else
                # if working copy is clean
                prompt-segment green black
            fi
            echo -n $(hg prompt "☿ {rev}@{branch}") $st
        else
            st=""
            rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
            branch=$(hg id -b 2>/dev/null)
            if `hg st | grep -q "^\?"`; then
                prompt-segment red black
                st='±'
            elif `hg st | grep -q "^(M|A)"`; then
                prompt-segment yellow black
                st='±'
            else
                prompt-segment green black
            fi
            echo -n "☿ $rev@$branch" $st
        fi
    fi
}

## Main prompt
build-prompt() {
  RETVAL=$?
  prompt-status
  prompt-virtualenv
  prompt-nix
  prompt-context
  prompt-pwd
  prompt-git
  prompt-hg
  prompt-end
}

PROMPT='$(col-reset)$(crs %b%k)$(build-prompt) '

RPS1="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

accept-line-or-clear-warning () {
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

controversial () {
    autoload -U run-help
    autoload run-help-git
    autoload run-help-svn
    autoload run-help-svk
    unalias run-help
    alias help=run-help

    zstyle ':completion:*'            rehash      true
    zstyle ':completion:*:parameters' list-colors "=*=32"
    zstyle ':completion:*:commands'   list-colors '=*=1;31'
    zstyle ':completion:*:builtins'   list-colors '=*=1;38;5;142'
    zstyle ':completion:*:aliases'    list-colors '=*=2;38;5;128'
    zstyle ':completion:*:*:kill:*'   list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'
    zstyle ':completion:*:options'    list-colors '=^(-- *)=34'
}

#controversial
