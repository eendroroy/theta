#!/usr/bin/env zsh

THEME_ROOT=${0:A:h}

source "${THEME_ROOT}/libs/promptlib/activate"
source "${THEME_ROOT}/libs/zsh-async/async.zsh"
source "${THEME_ROOT}/libs/zsh-256color/zsh-256color.plugin.zsh"

_ssh_st(){ [[ -n "$SSH_CLIENT" ]] && echo -n "[S] "; }

_is_git(){ if [[ $(git branch 2>/dev/null) != "" ]]; then; echo 1 ; else; echo 0 ; fi; }
_git_branch(){ ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="detached" || return false; echo -n "${ref#refs/heads/}"; return true; }
_git_rev(){ rev=$(git rev-parse HEAD | cut -c 1-7); echo -n "${rev}"; return true; }

_git_dirty(){
  _mod=$(git status --porcelain 2>/dev/null | grep 'M ' | wc -l | tr -d ' ');
  _add=$(git status --porcelain 2>/dev/null | grep 'A ' | wc -l | tr -d ' ');
  _del=$(git status --porcelain 2>/dev/null | grep 'D ' | wc -l | tr -d ' ');
  _new=$(git status --porcelain 2>/dev/null | grep '?? ' | wc -l | tr -d ' ');
  [[ "$_mod" != "0" ]] && echo -n " ⭑";
  [[ "$_add" != "0" ]] && echo -n " +";
  [[ "$_del" != "0" ]] && echo -n " -";
  [[ "$_new" != "0" ]] && echo -n " ?";
}

_git_left_right(){
  if [[ $(_git_branch) != "detached" ]]; then
    _pull=$(git rev-list --left-right --count `_git_branch`...origin/`_git_branch` 2>/dev/null | awk '{print $2}' | tr -d ' \n');
    _push=$(git rev-list --left-right --count `_git_branch`...origin/`_git_branch` 2>/dev/null | awk '{print $1}' | tr -d ' \n');
    [[ "$_pull" != "0" ]] && [[ "$_pull" != "" ]] && echo -n " ▼";
    [[ "$_push" != "0" ]] && [[ "$_push" != "" ]] && echo -n " ▲";
  else
    echo -n "";
  fi
}

_is_hg(){ if [[ $(hg branch 2>/dev/null) != "" ]]; then; echo 1 ; else; echo 0 ; fi; }
_hg_branch(){ ref=$(hg branch 2> /dev/null) || return false; echo -n "${ref}"; return true; }
_hg_rev(){ rev=$(hg identify --num | tr -d " +") || return false; echo -n "${rev}"; return true; }

_is_svn(){ if [[ $(svn info 2>/dev/null) != "" ]]; then; echo 1 ; else; echo 0 ; fi; }
_svn_rev(){ rev=$(svn info 2>/dev/null | grep Revision | awk '{print $2}') || return false; echo -n "${rev}"; return true; }

_branch(){
  if [[ $(_is_git) == 1 ]]; then
    echo -ne "%F{$_vcs}G%f %F{$_br}`_git_branch`%f"
  elif [[ $(_is_hg) == 1 ]]; then
    echo -ne "%F{$_vcs}M%f %F{$_br}`_hg_branch`%f"
  elif [[ $(_is_svn) == 1 ]]; then
    echo -ne "%F{$_vcs}S%f"
  else
    echo -ne ""
  fi
}

_rev(){
  if [[ $(_is_git) == 1 ]]; then
    echo -ne "%F{$_rev}`_git_rev`%f"
  elif [[ $(_is_hg) == 1 ]]; then
    echo -ne "%F{$_rev}`_hg_rev`%f"
  elif [[ $(_is_svn) == 1 ]]; then
    echo -ne "%F{$_rev}`_svn_rev`%f"
  else
    echo -ne ""
  fi
}

_left_right(){
  if [[ $(_is_git) == 1 ]]; then
    echo -ne "%F{$_lr}`_git_left_right`%f"
  else
    echo -ne ""
  fi
}

_dirty(){
  if [[ $(_is_git) == 1 ]]; then
    echo -ne "%F{$_dirty}`_git_dirty`%f"
  else
    echo -ne ""
  fi
}

_vcs_prompt(){
  if [[ $(_is_git) == 1 ]] || [[ $(_is_hg) == 1 ]] || [[ $(_is_svn) == 1 ]]; then
    echo -ne " [`_branch``_left_right` `_rev``_dirty`]"
  fi
}

_java_version(){
  which java > /dev/null && echo " %F{$_jc}[J `java -version 2>&1 | awk -F '.' '/version/ {print $2}'`]%f"
}

_python_version(){
  which python > /dev/null && echo " %F{$_pyc}[P `python --version 2>&1 | awk '{print $2}'`]%f"
}

_ruby_version(){
  which ruby > /dev/null && echo " %F{$_rbc}[R `ruby -v | tr 'p' ' ' | awk '{print $2}' | tr -d ' \n'`]%f"
}

_node_version(){
  which node > /dev/null && echo " %F{$_nc}[N `node -v | awk '{print $1}' | tr -d ' v\n'`]%f"
}

_go_version(){
  which go > /dev/null && echo " %F{$_goc}[G `go version | awk '{print $3}' | tr -d 'go \n'`]%f"
}

_elixir_version(){
  which elixir > /dev/null && echo " %F{$_exc}[E `elixir --version | grep "Elixir" | awk '{print $2}' | tr -d ' \n'`]%f"
}

_bg_count() {
  _jobc="`jobs | wc -l | tr -d ' '`";
  if [[ "$_jobc" != 0 ]]; then
    echo " %F{$_bjob}[$_jobc]%f"
  fi
}

_sdk_prompt(){
  echo "`_java_version``_python_version``_ruby_version``_node_version``_go_version``_elixir_version``_bg_count`"
}

function __dummy(){}

function __lprompt_complete() {
  PROMPT='
 %F{$_dir}[%1~]%f`_vcs_prompt``_sdk_prompt`
 %F{$_ssh}`_ssh_st`%f%(?.%F{$_theta}Θ %f.%F{$_error}Θ %f)'
  zle && zle reset-prompt
  async_stop_worker lprompt -n
}

_vcs=33
_ssh=226
_dir=67
_error=208
_rev=80
_br=157
_dirty=208
_lr=220
_jc=248
_pyc=144
_rbc=124
_nc=67
_goc=110
_exc=55
_bjob=178
_theta=42

function precmd() {

  _colorize()
  autoload -U add-zsh-hook
  setopt prompt_subst
  PROMPT='
 %F{$_dir}[%~]%f
 %F{$_ssh}`_ssh_st`%f%(?.%F{$_theta}Θ %f.%F{$_error}Θ %f)'
  RPROMPT=''
  async_init
  async_start_worker lprompt -n
  async_register_callback lprompt __lprompt_complete
  async_job lprompt __dummy
}
