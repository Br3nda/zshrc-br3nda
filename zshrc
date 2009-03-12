# atom's .zshrc# atom's .zshrc
# atom.smasher.org
# atom @
#       smasher.org
#       suspicious.org
# gpg key = 762A 3B98 A3C3 96C9 C6B7  582A B88D 52E4 D9F5 7808
# last updated 12 jun 2008 - under regular development, check back for updates
ZSHRC='public release v0.130 - http://smasher.org/zsh/'

source ~/.aliases

# !! this is not intended to be a universal zshrc file !!
# what's here works for me. i like it. the reason i'm
# releasing this is for others to learn from it. if you
# want to copy from it, good luck. for best results, roll
# up your sleeves and make it your own.
#
# original code released under GNU General Public License.
# http://www.gnu.org/licenses/gpl-3.0.txt
# other licenses may be available on request.
# to the best of my knowledge code from others has been
# properly attributed, but in most (all?) cases modified enough
# that i can claim copyright over it as it appears here.
#
# thanks to everyone who posted something that's attributed below!!
# and thanks to everyone who helped make this zshrc better.
# this file would never have gotten so far if not for all of you.

umask 022

export HOME TERM	\
    GZIP='-9'		\
    KDEDIR=/usr/local	\
    OGLE_USE_XV=0	\
    TZ=Pacific/Auckland

## this bit makes this zshrc more portable.
## the TZ setting above is a default if none is specified with a ~/.TZ file
## on a server on the US east coast my ~/.TZ contains "America/New_York"
## this way i don't have to set the TZ everytime i update my zshrc.
[[ -f ~/.TZ ]] && read TZ < ~/.TZ

# after this zshrc file is run you can type: TZ=<tab>
# and see a list of time zones ;)

WORDCHARS=':*?_-.[]~&;!#$%^(){}<>|'
HISTSIZE=250
HISTFILE=${HOME}/.zsh_history
SAVEHIST=1000

## freebsd - turn on colors for ls
[[ ${OSTYPE} == *freebsd* ]] && export CLICOLOR=yes

## enable:
setopt PROMPT_SUBST	\
    EXTENDED_GLOB	\
    AUTO_CD		\
    CORRECT		\
    CORRECT_ALL		\
    ZLE			\
    PROMPT_SP		\
    INTERACTIVE_COMMENTS

zmodload zsh/terminfo zsh/termcap

## figure out what the PATH should be
typeset -U common_paths
common_paths=(
    ${path} ${=$(command -p getconf PATH)//:/ } # what the system thinks PATH should be
    /bin /sbin /usr/bin /usr/sbin		# good places to look
    /usr/local/bin /usr/local/sbin		# freeBSD
    /usr/X11R6/bin				# X11
    /usr/pkg/bin /usr/pkg/sbin			# ???
    /usr/ucb					# solaris - BSD
    /usr/sfw/bin /usr/sfw/sbin			# solaris - sun free-ware
    /usr/xpg4/bin /usr/xpg6/bin			# solaris - X/Open Portability Guide
    /opt/local/bin /opt/local/sbin /opt/SUNWspro/bin	# solaris
    /usr/ccs/bin				# solaris - C Compilation System
    /usr/platform/$(uname -i)/sbin		# solaris - hardware dependent
    #/var/qmail/bin				# qmail - uncomment if desired
    /usr/games					# fun stuff
    ${HOME}/bin					# personal stuff
)
unset PATH_tmp
unsetopt NOMATCH
for temp_path in ${common_paths}
do
  if [[ ${OSTYPE} == solaris* ]] {
	  ## solaris may has some of these directories owned by "bin:bin" (uid 2)
	  ## observed on: SunOS 5.10 Generic_120011-14 sparc, core install
	  test -d "${temp_path}"(u0r^IWt,u2r^IWt,Ur^IWt) && PATH_tmp="${PATH_tmp}${temp_path}:"
  } else {
	  test -d "${temp_path}"(u0r^IWt,Ur^IWt) && PATH_tmp="${PATH_tmp}${temp_path}:"
	  ## the next line shows how to include symlinks in the PATH
	  #test -e "${temp_path}"(-/u0r^IWt,-/Ur^IWt) && PATH_tmp="${PATH_tmp}${temp_path}:"
  }
done
setopt NOMATCH
export PATH=${PATH_tmp/%:/}
unset common_paths temp_path PATH_tmp

## solaris grep is lacking
if [[ ${OSTYPE} == solaris* ]] {
	## solaris-10 will likely have these, except core install
	[[ -x $(whence -p  ggrep) ]] && alias  grep=$(whence -p ggrep)
	[[ -x $(whence -p gegrep) ]] && alias egrep=$(whence -p gegrep)
	[[ -x $(whence -p gfgrep) ]] && alias fgrep=$(whence -p gfgrep)
}

## not all systems have `less`, but it sure beats `more`
[[ -x $(whence -p less) ]] && export PAGER=$(whence -p less)
##
## not all systems have `most`, but i like it better than `less`
[[ -x $(whence -p most) ]] && export PAGER=$(whence -p most)

## not all systems (solaris) have a userland stat
[[ -x $(whence -p stat) ]] || { zmodload zsh/stat && alias stat="stat -ronL" }

## after setting the PAGER, above...
READNULLCMD=${PAGER}

## not all systems have `emacs`, but i like it when they do
#[[ -x $(whence -p emacs) ]] && export EDITOR=$(whence -p emacs)

## if there's a `manpath` command, use it
[[ -x $(whence -p manpath) ]] && export MANPATH=$(manpath 2> /dev/null)

## old (and/or crappy) versions of `grep` choke on this - make it safe
grep -q --color '.' . 2> /dev/null && export GREP_OPTIONS='--color'

#######################################################
## set up an array to help facilitate the PROMPT tricks
## the array "PR_STUFF" contains things to be used in the prompt
typeset -A PR_STUFF

######################
## aliases & functions
alias mv='nocorrect mv'		# no spelling correction on mv (zsh FAQ 3.4)
alias cp='nocorrect cp'		# no spelling correction on cp (zsh FAQ 3.4)
alias mkdir='nocorrect mkdir'	# no spelling correction on mkdir (zsh FAQ 3.4)

## look for rsync - if it's found create a "cpv" function
[[ -x $(whence -p rsync) ]] && cpv () {
    ## verbose copy
    ## rsync, but neutered
    rsync -PIhb --backup-dir=/tmp/rsync -e /dev/null -- ${@}
}

cd () {
    ## cd to a file (cd to the directory that a file is in)
    ## this _might_ break some zsh specific features of 'cd', but none that i use
    ## as of 23 oct 2007 i can't see that it breaks anything
    if [[ 1 == "${#}" && '-' != "${1}" && ! -d "${1}" && -d "${1:h}" && "${1}" != (+|-)<-> ]]
    then
	#print "correcting \"${1}\" to \"${1:h}\"" >&2
	PR_STUFF[cd_color]=file
	builtin cd "${1:h}"
    else
	[[ "${*}" == '-' ]] && PR_STUFF[cd_color]=dash
	builtin cd "${@}"
    fi
}

cdmkdir () {
    ## create a new directory and cd into it
    mkdir -p "${1}"
    cd "${1}"
}

fortune () {
	## include all fortunes in the database
	command fortune -a ${@} /usr/share/games/fortune
}

shellname () {
    ## a *very* simple command to set the SHELL_NAME variable.
    ## used to explicitly set a name for the shell, as displayed in
    ##    title bars, icons, `screen` lists, etc
    ## with no arguments the name returns to normal (dynamic) operation
    SHELL_NAME="${*}"
}
shellprefix () {
    ## like shellname, but just a prefix
    SHELL_PREFIX="${*}"
}

command_title () {
    ### this function sets the current command name in title bars, tabs, and screen lists
    ## inspired by: http://www.semicomplete.com/blog/2006/Jun/29
    if [[ -n ${SHELL_NAME} ]]
    then
	# allow the $cmnd_name to be set manually and override automatic values
	# to set the shell's title to "foo";	export SHELL_NAME=foo
	# to return to normal operation;	unset SHELL_NAME
	cmnd_name="${SHELL_NAME}"
    elif [[ 'fg' == "${${(z)@}[1]}" ]]
    then
	# this is a poor hack to replace 'fg' with a more sensical command
	# it really only works properly if only one job is suspended
	cmnd_name="${(vV)jobtexts}"
    else
	# get the $cmnd_name from the current command being executed
	# make nonprintables visible
	local cmnd_name="${(V)1}"
    fi
    # escape '%'; get rid of pesky newlines; get rid of tabs; instruct the prompt to truncate
    cmnd_name="%80>...>${${${cmnd_name//\%/\%\%}//'\n'/; }//'\t'/ }%<<"
    # ^^^ in other words:
    # ${cmnd_name//\%/\%\%} ; ${cmnd_name}//'\n'/; } ; ${cmnd_name//'\t'/ } ; %60>...>${cmnd_name}%<<
    # if the shell is not run by the $LOGIN user, prefix the command with "$USERNAME: "
    [[ "${USERNAME}" != "${LOGNAME}" ]] && cmnd_name="${USERNAME}: ${cmnd_name}"
    # if the shell is running on an ssh connection, prefix the command with "$HOST: "
    [[ -n "${SSH_CONNECTION}" ]] && cmnd_name="${HOST}: ${cmnd_name}"
    ## add prefix, if defined
    [[ -n "${SHELL_PREFIX}" ]] && cmnd_name="${SHELL_PREFIX}: ${cmnd_name}"
    # don't confuse the display any more than required
    #	we'll put this back, if required, below
    unsetopt PROMPT_SUBST
    case ${TERM} {
    xterm*)
	print -Pn "\e]0;[xterm] ${cmnd_name}\a" # plain xterm title & icon name
	;;
    screen)
	print -Pn "\ek${cmnd_name}\e\\" # screen title
	;;
    rxvt*)
	print -Pn "\e]62;[mrxvt] ${cmnd_name}\a" # rxvt title name
	[[ -n ${MRXVT_TABTITLE} || -n ${SSH_CONNECTION} ]] && \
	    print -Pn "\e]61;${cmnd_name}\a" # mrxvt tab name
	    ## using ssh from *rxvt, we'll assume that it's mrxvt
	    ## there's no good way to know for sure
	    ## this doesn't seem to cause any harm
	;;
    }
    # return PROMPT_SUBST to previous state, if it was set
    setopt LOCAL_OPTIONS
}

##############################
## enable completion functions
autoload -U compinit
compinit

##########################
# See if we can use colors
# inspired by: http://www.aperiodic.net/phil/prompt/
autoload colors
if [[ "${terminfo[colors]}" -ge 8 ]]
then
	colors
fi
for color in CYAN WHITE YELLOW MAGENTA BLACK BLUE RED DEFAULT GREY GREEN
do
	PR_STUFF[${color}]="%{${fg_bold[${(L)color}]}%}"
	PR_STUFF[LIGHT_${color}]="%{${fg[${(L)color}]}%}"
	PR_STUFF[BG_${color}]="%{${bg_bold[${(L)color}]}%}"
	PR_STUFF[BG_LIGHT_${color}]="%{${bg[${(L)color}]}%}"
done

##################################
## print  fortune in reverse video
[[ -x $(whence -p fortune) ]] && \
    print "${terminfo[bold]}${fg[cyan]}${terminfo[rev]}`fortune`${terminfo[sgr0]}"

######################
#### prompt tricks ###
## not all tricks are available on all terminals
######################
## property  start end
## bold      %B    %b
## underline %U    %u
## standout  %S    %s
PR_STUFF[ITALIC]="%{${terminfo[sitm]}%}"	# enter_italics_mode
PR_STUFF[END_ITALIC]="%{${terminfo[ritm]}%}"	# exit_italics_mode
PR_STUFF[DIM]="%{${terminfo[dim]}%}"		# enter_dim_mode
PR_STUFF[BLINK]="%{${terminfo[blink]}%}"	# enter_blink_mode
PR_STUFF[NO_COLOR]="%{${terminfo[sgr0]}%}"	# exit_attribute_mode (turn off all attributes)

#####################################################
# See if we can use extended characters to look nicer
# more info on all of this funky stuff: man 5 terminfo
typeset -A altchar
set -A altchar ${(s..)terminfo[acsc]}
PR_STUFF[SET_CHARSET]="%{${terminfo[enacs]}%}"	# enable_alternate_char_set
PR_STUFF[SHIFT_IN]="%{${terminfo[smacs]}%}"	# enter_alt_charset_mode
PR_STUFF[SHIFT_OUT]="%{${terminfo[rmacs]}%}"	# end_alternate_charcter_set
typeset -A ACS
ACS[STERLING]=${altchar[\}]:- }	# UK pound sign
ACS[DARROW]=${altchar[.]:- }	# arrow pointing down
ACS[LARROW]=${altchar[,]:-<}	# arrow pointing left
ACS[RARROW]=${altchar[+]:->}	# arrow pointing right
ACS[UARROW]=${altchar[-]:-^}	# arrow pointing up
ACS[BOARD]=${altchar[h]:-#}	# board of squares
ACS[BULLET]=${altchar[~]:-#}	# bullet
ACS[CKBOARD]=${altchar[a]:-#}	# checker board (stipple)
ACS[DEGREE]=${altchar[f]:-#}	# degree symbol
ACS[DIAMOND]=${altchar[\`]:-+}	# diamond
ACS[GEQUAL]=${altchar[z]:->}	# greater-than-or-equal-to
ACS[PI]=${altchar['{']:-#}	# greek pi
ACS[HLINE]=${altchar[q]:--}	# horizontal line
ACS[LANTERN]=${altchar[i]:-#}	# lantern symbol
ACS[PLUS]=${altchar[n]:-+}	# large plus or crossover
ACS[LEQUAL]=${altchar[y]:-<}	# less-than-or-equal-to
ACS[LLCORNER]=${altchar[m]:-+}	# lower left corner
ACS[LRCORNER]=${altchar[j]:-+}	# lower right corner
ACS[NEQUAL]=${altchar[|]:-!}	# not-equal
ACS[PLMINUS]=${altchar[g]:-#}	# plus/minus
ACS[S1]=${altchar[o]:-_}	# scan line 1
ACS[S3]=${altchar[p]:-_}	# scan line 3
ACS[S7]=${altchar[r]:-_}	# scan line 7
ACS[S9]=${altchar[s]:-_}	# scan line 9
ACS[BLOCK]=${altchar[0]:-#}	# solid square block
ACS[TTEE]=${altchar[w]:-+}	# tee pointing down
ACS[RTEE]=${altchar[u]:-+}	# tee pointing left
ACS[LTEE]=${altchar[t]:-+}	# tee pointing right
ACS[BTEE]=${altchar[v]:-+}	# tee pointing up
ACS[ULCORNER]=${altchar[l]:-+}	# upper left corner
ACS[URCORNER]=${altchar[k]:-+}	# upper right corner
ACS[VLINE]=${altchar[x]:-#}	# vertical line

export LESS_TERMCAP_md="${terminfo[bold]}${fg_bold[white]}"	# bold/ bright
export LESS_TERMCAP_mh="${fg[white]}"		# dim/ half
export LESS_TERMCAP_me="${terminfo[sgr0]}"	# normal (turn off all attributes)
export LESS_TERMCAP_mr="${terminfo[rev]}"	# reverse
export LESS_TERMCAP_mp="${fg[white]}"		# protected
export LESS_TERMCAP_mk="${fg[white]}"		# blank/ invisible
export LESS_TERMCAP_se="${terminfo[sgr0]}"	# standout end
export LESS_TERMCAP_so="${terminfo[rev]}"	# standout
export LESS_TERMCAP_ue="${terminfo[sgr0]}"	# end underline
export LESS_TERMCAP_us="${fg_bold[cyan]}"	# underline
export LESS='MiRJw -z-5 -j15'

how_many_cpu () {
    ## try to figure out how many CPUs are in the system
    local cpu_count=0
    ## sysctl; freeBSD...
    if sysctl -n hw.ncpu 2> /dev/null | read cpu_count
    then
	print "Found ${cpu_count} CPUs with sysctl" 1>&2
	print "${cpu_count}"
	return 0
    fi
    ## or, on (linux) systems that have /proc/cpuinfo ...
    if [[ -r /proc/cpuinfo ]]
    then
	local line_from_cpuinfo
	while read line_from_cpuinfo
	do
	  [[ -z "${line_from_cpuinfo:#*:}" ]] && cpu_count=$[${cpu_count}+1]
	done < /proc/cpuinfo
	print "Found ${cpu_count} CPUs with /proc/cpuinfo" 1>&2
	print "${cpu_count}"
	return 0
    fi
    ## solaris...
    if [[ -x $(whence -p psrinfo) ]]
    then
	local psrinfo_count
	psrinfo | while read psrinfo_count
	do
	  [[ -z "${psrinfo_count##*on-line*}" ]] && cpu_count=$[${cpu_count}+1]
        done
	print "Found ${cpu_count} \"on-line\" CPUs with psrinfo" 1>&2
	print "${cpu_count}"
	return 0
    fi
    ## if all else fails, assume 1 CPU
    print 'Assuming 1 CPU' 1>&2
    print 1
}

###################################################################################
## before we colorize the system load figure out how many CPUs are sharing the load
#########################################
## if the load is less then #CPUs - green
## if the load is more than twice #CPUs - red
## if the load is in between - yellow
PR_STUFF[cpu_count]=$(how_many_cpu)

load_color () {
    load_color=${1}
    ## if the same color is used two (or more) times it only has
    ##   to be specified once
    if [[ ${load_color} == ${this_load_color} ]]
    then
	color_loads="${color_loads}${each_load}"
    else
	color_loads="${color_loads}${PR_STUFF[UPTIME_LOAD_${load_color}]}${each_load}"
	this_load_color=${load_color}
    fi
}

set_up_prompt () {
  ## set up for PROMPT
  local TERMWIDTH=$[${COLUMNS}-2]
  ## figure out the load averages
  local uptime_load uptime_load_size color_loads each_load this_load_color load_color
  ## stderr from `uptime` is redirected to /dev/null to cope with a bug observed in OS-X
  ##    10.5.1 and likely exists in other OS-X releases; if an xterm is opened in X11
  ##    the output of `uptime` gets hosed in *all* terminals
  uptime_load="${(@)${=$(uptime 2> /dev/null)}[-3,-1]}"	# the load averages
  uptime_load_size=$[ ${#uptime_load} + 2]	# how many characters in the load averages
  ## colorize the load averages
  for each_load in ${${=uptime_load}[1]}\  ${${=uptime_load}[2]}\  ${${=uptime_load}[3]}
  do
    ## this looks weird: ${each_load/%${~:-,*}/}
    ## it's doing a pattern substitution on ',*' to get rid of everything after a comma, if there is one
    ## the leading '~' allows substitution for a pattern, instead of a string
    ## the ':' tells it to substitute what follows, instead of using the preceeding null string
    ## different LOCALEs, and different OSes do weird things with commas in the load
    ##    averages, and this seems to deal with them all
    if [[ "${PR_STUFF[cpu_count]:-1}" -gt "${each_load/%${~:-,*}/}" ]]
    then
	load_color LOW
    elif [[ $[${PR_STUFF[cpu_count]:-1}*2] -le "${each_load/%${~:-,*}/}" ]]
    then
	load_color HI
    else
	load_color MED
    fi
  done
  uptime_load="${PR_STUFF[SHIFT_OUT]}${color_loads}${PR_STUFF[SHIFT_IN]}"
  ## time zone stuff - a linux system with a half-broken strftime(3) showed me that i like seeing
  ## the city name of the time zone i'm in. if that's not available then show the short version
  ## if you just want the short version use this: PR_STUFF[TZ]=$(print -P '%D{%Z}')
  if [[ ${TZ} != ${PR_STUFF[TZ_LAST]} ]]
  then
      ## sanity check if the TZ file exists
      ## only do this when the TZ env variable changed
      ## the reason for this is to not display nonsense if TZ=foo/bar
      ##   and set TZ to something useful instead of leaving it undefined
      local tz_file
      ## thanks: Peter Stephenson - zsh-users mailing list 09 Jan 2008
      tz_file=(/usr/{share,lib,share/lib}/{zoneinfo,locale/TZ}/${TZ}(.N))
      (( ${#tz_file} )) || export TZ=Etc/UTC
      PR_STUFF[TZ_LAST]=${TZ}
      PR_STUFF[TZ]=${${TZ:t}:-$(print -P '%D{%Z}')}
  fi
  ## how much space will the time take up
  local time_space="${#${(%):-$(print -P '%D{%H:%M} '${PR_STUFF[TZ]})}}"
  ## if there's battery info, get it. otherwise don't (gracefully)
  ## the battery info comes from "/root/bin/bat-mon"
  ## check that /tmp/battery-status is a plain file
  ##   and owned either by root or current UID
  unsetopt NOMATCH
  if test -f /tmp/battery-status(u0R^IW,UR^IW)
  then
      setopt NOMATCH ## return that to normal
      BATT_STAT=`< /tmp/battery-status`
      local batt_stat_size=${#${(%S)BATT_STAT//\$\{*\}}}
      [[ -n "${BATT_STAT}" ]] && BATT_STAT="${ACS[RTEE]}${BATT_STAT}${PR_STUFF[PS1_LINE]}${PR_STUFF[NO_COLOR]}${PR_STUFF[PS1_LINE]}${ACS[LTEE]}"
      local promptsize=$[${#${(%):-xx%n@%M:}} + ${batt_stat_size} + 2 + ${uptime_load_size} + time_space + 2]
  else
      setopt NOMATCH ## return that to normal
      local promptsize=$[${#${(%):-xx%n@%M:}} + ${uptime_load_size} + time_space + 2]
  fi
  ## count up the width of the things that are on the prompt
  local pwdsize=${#${(%):-%(1/.%~/.%~)}}
  local termwidth_minus_promptsize_minus_pwdsize=$[${TERMWIDTH} - ${promptsize} - ${pwdsize}]
  [[ 0 -gt ${termwidth_minus_promptsize_minus_pwdsize} ]] && termwidth_minus_promptsize_minus_pwdsize='0'
  PR_STUFF[PWDLEN]=$[${TERMWIDTH} - ${promptsize}]
  [[ 0 -gt $PR_STUFF[PWDLEN] ]] && PR_STUFF[PWDLEN]=1
  PR_STUFF[FILLBAR]="\${(r:${termwidth_minus_promptsize_minus_pwdsize}::${ACS[HLINE]}:)}\
${ACS[RTEE]}${PR_STUFF[TIME]}${PR_STUFF[SHIFT_OUT]}%D{%H:%M} ${PR_STUFF[TIME_TZ]}${PR_STUFF[TZ]}${PR_STUFF[SHIFT_IN]}${PR_STUFF[PS1_LINE]}${ACS[LTEE]}${ACS[RTEE]}\
${uptime_load}${PR_STUFF[PS1_LINE]}${ACS[LTEE]}${BATT_STAT}"

  PR_STUFF[COLUMNS]=${COLUMNS}
}

chpwd () {
    [[ -z "${PR_STUFF[cd_color]}" ]] && PR_STUFF[cd_color]=new
}

## use colors from the 256 color palate if they're available
##
## to set a background color behind the prompt,
##    uncomment the lines starting with: PR_STUFF[BG_PS]
if [[ 256 -eq "${terminfo[colors]}" ]]
then
    ## if the TERM supports 256 colors
#    PR_STUFF[BG_PS]="$PR_STUFF[BG_BLACK]" ## prompt bg color
    PR_STUFF[PWD_NEW]="%b${PR_STUFF[BG_PS]}%{$(echoti setaf 226)%}"
    PR_STUFF[PWD_NEW_FILE]="%b%U${PR_STUFF[BG_PS]}%{$(echoti setaf 226)%}"
    PR_STUFF[PWD_NEW_DASH]="%b${PR_STUFF[BG_PS]}%{$(echoti setaf 178)%}"
    PR_STUFF[PWD_OLD]="%b${PR_STUFF[BG_PS]}%{$(echoti setaf 33)%}"
    PR_STUFF[TIME]="%b%{$(echoti setaf 147)%}${PR_STUFF[SHIFT_OUT]}${PR_STUFF[BG_PS]}"
    PR_STUFF[TIME_TZ]="%{$(echoti setaf 62)%}"
    PR_STUFF[UPTIME_LOAD_LOW]="%{$(echoti setaf 40)%}${PR_STUFF[BG_PS]}"
    PR_STUFF[UPTIME_LOAD_MED]="%{$(echoti setaf 226)%}${PR_STUFF[BG_PS]}"
    PR_STUFF[UPTIME_LOAD_HI]="%{$(echoti setaf 196)%}${PR_STUFF[BG_PS]}"
    	PR_STUFF[PS1_LINE]="${PR_STUFF[BG_PS]}%{$(echoti setaf 231)%}"
    	[[ 0 -eq ${UID} ]] && PR_STUFF[PS1_LINE]="${PR_STUFF[BG_PS]}%{$(echoti setaf 196)%}"
    PR_STUFF[ROOT_BG]="%{$(echoti setab 196)%}"
else
    ## if the term doesn't support 256 colors
#    PR_STUFF[BG_PS]="$PR_STUFF[BG_BLACK]" ## prompt bg color
    PR_STUFF[PWD_NEW]="%b${PR_STUFF[BG_PS]}${PR_STUFF[YELLOW]}"
    PR_STUFF[PWD_NEW_FILE]="%b%U${PR_STUFF[BG_PS]}${PR_STUFF[YELLOW]}"
    PR_STUFF[PWD_NEW_DASH]="%b${PR_STUFF[BG_PS]}${PR_STUFF[GREEN]}"
    PR_STUFF[PWD_OLD]="%b${PR_STUFF[BG_PS]}${PR_STUFF[BLUE]}"
    PR_STUFF[TIME]="%b${PR_STUFF[LIGHT_CYAN]}${PR_STUFF[BG_PS]}"
    PR_STUFF[UPTIME_LOAD_LOW]="${PR_STUFF[BG_PS]}${PR_STUFF[LIGHT_GREEN]}"
    PR_STUFF[UPTIME_LOAD_MED]="${PR_STUFF[BG_PS]}${PR_STUFF[LIGHT_YELLOW]}"
    PR_STUFF[UPTIME_LOAD_HI]="${PR_STUFF[BG_PS]}${PR_STUFF[LIGHT_RED]}"
    	PR_STUFF[PS1_LINE]="${PR_STUFF[BG_PS]}${PR_STUFF[WHITE]}"
    	[[ 0 -eq ${UID} ]] && PR_STUFF[PS1_LINE]="${PR_STUFF[BG_PS]}${PR_STUFF[RED]}"
    PR_STUFF[ROOT_BG]="$PR_STUFF[BG_LIGHT_RED]"
fi

chpwd_color () {
  ## change the color of the PWD in the prompt
  ## if we just changed directories
  if [[ -z "${PR_STUFF[cd_color]}" ]]
  then
      PR_STUFF[PWD_COLOR]="${PR_STUFF[PWD_OLD]}${PR_STUFF[BG_PS]}"
  else
      ## we just changed to to a new directory
      ## the color of the new dir depends on how we got here
      case ${PR_STUFF[cd_color]} {
	dash)
	  PR_STUFF[PWD_COLOR]="${PR_STUFF[PWD_NEW_DASH]}${PR_STUFF[BG_PS]}"
	  ;;
	file)
	  PR_STUFF[PWD_COLOR]="${PR_STUFF[PWD_NEW_FILE]}${PR_STUFF[BG_PS]}"
	  ;;
	*)
	  PR_STUFF[PWD_COLOR]="${PR_STUFF[PWD_NEW]}${PR_STUFF[BG_PS]}"
	  ;;
	}
  unset 'PR_STUFF[cd_color]'
  fi
}

precmd () {
  # this displays nifty stuff about commands that exit non-zero
  # 1) Look at exit status of last command - attach appropriate signal
  # if it was a signal that caused it.  It's safest to do this first
  # before $?'s value gets screwed up.
  # http://zsh.dotsrc.org/Contrib/startup/users/debbiep/dot.zshrc
  # 2) make it more feasible to control how/when it's displayed
  # idea from zsh-users mailing list;
  # Matthew Wozniski <godlygeek@gmail.com>, Sep 29 2007
  local exitstatus="${?}"
  if [[ 0 -ne "${exitstatus}" && -z "${shownexterr}" ]]
  then
    PR_STUFF[exitstuff]="${exitstatus}"
    shownexterr=1	# see also preexec: unset shownexterr
    if [[ ${exitstatus} -ge 128 && $exitstatus -le (127+${#signals}) ]]
    then
      # Last process was killed by a signal.  Find out what it was from
      # the $signals environment variable.
      PR_STUFF[exitstuff]="${PR_STUFF[exitstuff]}:${signals[${exitstatus}-127]}"
    fi
  else
    unset 'PR_STUFF[exitstuff]'
  fi
  ## if the most recent command returned non-zero, display the exit status in the prompt
  ## if the most recent command was killed with a signal, show that too
  if [[ -n "${PR_STUFF[exitstuff]}" ]]
  then
    PR_STUFF[exitstuff]="${PR_STUFF[SHIFT_IN]}${ACS[RTEE]}${PR_STUFF[BG_RED]}${PR_STUFF[WHITE]}${PR_STUFF[SHIFT_OUT]}${PR_STUFF[exitstuff]}${PR_STUFF[NO_COLOR]}${PR_STUFF[WHITE]}${PR_STUFF[BG_PS]}${PR_STUFF[PS1_LINE]}${PR_STUFF[SHIFT_IN]}${ACS[LTEE]}"
  fi

  ## underline the USERNAME in the prompt if it's different than the LOGNAME
  PR_STUFF[ps1_name]=$([[ ${LOGNAME} != ${USERNAME} ]] && print '%U%n%u' || print '%n')

  command_title "${ZSH_NAME} (${TTY:t})"

  set_up_prompt

  chpwd_color

  print -n "${terminfo[rmacs]}"	## reset a sane tty
}

preexec () {
  unset shownexterr
  print -n ${terminfo[sgr0]}	## reset colors, etc
  command_title "${1}"
}

## // unfortunately, this chokes on interactve prompts to STDERR, eg, rm -i file
## Colorize STDERR
## based on - http://gentoo-wiki.com/TIP_Advanced_zsh_Completion#Colorize_STDERR
## // the only way really make this work properly is to implement it in the terminal
#exec 2>>(
#while read stderr
#do
#	print "${fg[red]}"${(q)stderr}"${terminfo[sgr0]}" 1>&2
#done)

## colored completion listings
[[ "${terminfo[colors]}" -ge 8 ]] && zstyle ':completion:*:default' list-colors \
	'no=0;35:fi=1;36:di=0;34:ln=0;35:pi=0;31:so=0;32:bd=44;37:cd=44;37:ex=0;31:tc=0;0:sp=0;0:ec='

###############################
## custom widgets & keybindings

bindkey -e	## emacs keybindings

## SHIFT-TAB can do a reverse-menu-complete!
## may not work on all TERMs
bindkey '^[[Z' reverse-menu-complete

move-to-bottom () {
    ## because sometimes i feel like moving to the bottom of the screen
    echoti cup $[${LINES}-1] 0
    zle && zle reset-prompt
}
zle -N move-to-bottom
bindkey "^X^L" move-to-bottom

copy-prev-word () {
    ## for most command line editing i like to use "/" as a word seperator
    ## but when using "copy-prev-word" i want the whole path
    local WORDCHARS="'${WORDCHARS}/'"
    zle .copy-prev-word
}
zle -N copy-prev-word

backward-word-with-slash () {
    ## SHIFT-ALT-B can do backward-word, with slashes
    local WORDCHARS="'${WORDCHARS}/'"
    zle .backward-word
}
zle -N backward-word-with-slash
bindkey "^[B" backward-word-with-slash

forward-word-with-slash () {
    ## SHIFT-ALT-F can do forward-word, with slashes
    local WORDCHARS="'${WORDCHARS}/'"
    zle .forward-word
}
zle -N forward-word-with-slash
bindkey "^[F" forward-word-with-slash

transpose-words () {
    ## definately
    local WORDCHARS="'${WORDCHARS}/'"
    zle .transpose-words
}
zle -N transpose-words

accept-line () {
    ## this may not be the most efficient way to do this...
    ## redraw the edit buffer before executing the command
    ## the real reason this is here is to re-color the edit buffer
    ##    if completion messed it up
    zle .redisplay
    zle .accept-line
}
zle -N accept-line

expand-or-complete-with-color () {
    print -n ${fg_bold[cyan]}
    _main_complete
}
zle -C expand-or-complete .expand-or-complete expand-or-complete-with-color

expand-or-complete-prefix-with-color () {
    print -n ${fg_bold[cyan]}
    _main_complete
}
zle -C expand-or-complete-prefix .expand-or-complete-prefix expand-or-complete-prefix-with-color
## if i do "^A" and go to the beginning of the line, and i want to insert a command
##    at the beginning of the line, i can start typing the command and CTRL-SPACE to complete
bindkey "^ " expand-or-complete-prefix

#################################################
## redraw the prompt when the window size changes
TRAPWINCH () {
    zle || return 0
    [[ ${PR_STUFF[COLUMNS]} -gt ${COLUMNS} ]] && echoti cud1
    set_up_prompt
    zle reset-prompt
}

##################################
## update the prompt automagically
## update ~about~ every 30 seconds
## this can be invoked manually with a "kill -ALRM" to the shell (from another process)
TMOUT=$[(${RANDOM}%15)+25]
TRAPALRM () {
    ## reset-prompt - this will update the prompt
    zle && set_up_prompt && zle reset-prompt
}

##########
## prompts

PS1='${PR_STUFF[SET_CHARSET]}${PR_STUFF[PS1_LINE]}\
${PR_STUFF[SHIFT_IN]}${ACS[ULCORNER]}${ACS[RTEE]}${PR_STUFF[SHIFT_OUT]}\
%(0#.${PR_STUFF[WHITE]}${PR_STUFF[ps1_name]}@%M.${PR_STUFF[MAGENTA]}${PR_STUFF[ps1_name]}${PR_STUFF[PWD_OLD]}@${PR_STUFF[MAGENTA]}%M)\
${PR_STUFF[WHITE]}:${PR_STUFF[PWD_COLOR]}%${PR_STUFF[PWDLEN]}<...<%(1/.%~/.%~)%<<%u\
${PR_STUFF[NO_COLOR]}\
${PR_STUFF[BG_PS]}${PR_STUFF[PS1_LINE]}\
${PR_STUFF[SHIFT_IN]}${ACS[LTEE]}\
${(e)PR_STUFF[FILLBAR]}\

${PR_STUFF[SHIFT_IN]}${ACS[LLCORNER]}${PR_STUFF[exitstuff]}\
%#${PR_STUFF[NO_COLOR]}${PR_STUFF[SHIFT_OUT]} ${PR_STUFF[CYAN]}'

PS2='${PR_STUFF[BLUE]}>${PR_STUFF[NO_COLOR]} ${PR_STUFF[CYAN]}'

# RPS1 not used - it got in the way of copy-n-paste,
# especially with multi-line commands

RPS2='${PR_STUFF[BLUE]}${PR_STUFF[BG_PS]}${PR_STUFF[SHIFT_IN]}\
${ACS[HLINE]}${PR_STUFF[WHITE]}${ACS[RTEE]}${PR_STUFF[SHIFT_OUT]}\
%_\
${PR_STUFF[SHIFT_IN]}${ACS[VLINE]}${PR_STUFF[SHIFT_OUT]}${PR_STUFF[NO_COLOR]}${PR_STUFF[CYAN]}'

## spelling prompt
SPROMPT="${PR_STUFF[YELLOW]}zsh: correct '%U%R%u' to '%U%r%u' ${PR_STUFF[NO_COLOR]}\
${PR_STUFF[LIGHT_YELLOW]}[Nyae]?${PR_STUFF[NO_COLOR]} "

###########################################
## display some stuff when the shell starts
print "${terminfo[smul]}OS:\t$OSTYPE${terminfo[rmul]}
${terminfo[smul]}MACH:\t$MACHTYPE${terminfo[rmul]}
${terminfo[smul]}CPU:\t$CPUTYPE${terminfo[rmul]}"

:
