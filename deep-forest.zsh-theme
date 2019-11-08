# kitty colors
kfg='#faf0d2'
kbg='#0f0f1f'

# greens
g1='#284d40'
g2='#2c635a'
g3='#2d6666'
g4='#3f5e26'

# reds
r1='#a33c3c'

# yellows
y1='#fff717'

# browns
b1='#423c32'

clock="%T"
cwd="%c"
command_line="%F{$kfg} ☰ %f"

LC=$'\Ue0b6'
RC=$'\Ue0b4'

export VIRTUAL_ENV_DISABLE_PROMPT=1

connector () {
    echo "%F{$pf}━%f"
}

arc1 () {
    echo "%F{$pf}┏%f"
}

arc2 () {
    echo "%F{$pf}┗%f"
}

start_time () {
    timer=${timer:-$SECONDS}
}

calc_time () {
    if [ $timer ]; then
        secs=$(($SECONDS - $timer))
        unset timer
    fi
}

forest_pass_fail () {
    if [[ $? == 0 ]]; then
        pf=$b1
    else
        pf=$r1
    fi
}

preexec_functions=(start_time)
precmd_functions=(calc_time forest_pass_fail)

forest_timer () {
    if [[ $secs > 1 ]]; then
        t="$(printf '%dd %dh %dm %ds\n' $(($secs/86400)) $(($secs%86400/3600)) $(($secs%3600/60)) $(($secs%60)))"
        if [[ $t[1] -eq 0 ]]; then
            t=$(echo $t | cut -c4-)
            if [[ $t[1] -eq 0 ]]; then
                t=$(echo $t | cut -c4-)
                if [[ $t[1] -eq 0 ]]; then
                    t=$(echo $t | cut -c4-)
                fi
            fi
        fi
        echo "$(connector)%F{$g4}$LC%f%F{$kfg}%K{$g4} $t %k%f%F{$g4}$RC%f"
    fi
}

forest_clock () {
    dt="$(date +'%H')"
    if [[ dt -gt 11 ]]; then
        suf='PM'
    else
        suf='AM'
    fi

    dt="$(date +%I:%M)"
    if [[ $dt[1] == 0 ]]; then
        tim="$(echo $dt | cut -c2-5)"
    else
        tim=$dt
    fi
    echo "$tim $suf"
}

forest_cwd () {
    echo "${PWD/#$HOME/~}" | rev | cut -d "/" -f1 -f2 | rev
}

forest_git () {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local g_status g_out=''
        branch="$(git branch --show-current)"
        g_status=$(command git status --porcelain 2> /dev/null)

        # check for untracked
        if $(echo "$g_status" | command grep -E '^\?\? ' &> /dev/null); then
            g_out="?$g_out"
        fi

        # Check for staged files
        if $(echo "$g_status" | command grep '^A[ MDAU] ' &> /dev/null); then
            g_out="+$g_out"
        elif $(echo "$g_status" | command grep '^M[ MD] ' &> /dev/null); then
            g_out="+$g_out"
        elif $(echo "$g_status" | command grep '^UA' &> /dev/null); then
            g_out="+$g_out"
        fi

        # Check for modified files
        if $(echo "$g_status" | command grep '^[ MARC]M ' &> /dev/null); then
            g_out="!$g_out"
        fi

        # Check for renamed files
        if $(echo "$g_status" | command grep '^R[ MD] ' &> /dev/null); then
            g_out="»$g_out"
        fi

        # Check for deleted files
        if $(echo "$g_status" | command grep '^[MARCDU ]D ' &> /dev/null); then
            g_out="✘$g_out"
        elif $(echo "$g_status" | command grep '^D[ UM] ' &> /dev/null); then
            g_out="✘$g_out"
        fi

        # Check for stashes
        if $(command git rev-parse --verify refs/stash >/dev/null 2>&1); then
            g_out="\$$g_out"
        fi

        # Check for unmerged files
        if $(echo "$g_status" | command grep '^U[UDA] ' &> /dev/null); then
            g_out="=$g_out"
        elif $(echo "$g_status" | command grep '^AA ' &> /dev/null); then
            g_out="=$g_out"
        elif $(echo "$g_status" | command grep '^DD ' &> /dev/null); then
            g_out="=$g_out"
        elif $(echo "$g_status" | command grep '^[DA]U ' &> /dev/null); then
            g_out="=$g_out"
        fi

        # Check whether branch is ahead
        local is_ahead=false
        if $(echo "$g_status" | command grep '^## [^ ]\+ .*ahead' &> /dev/null); then
            is_ahead=true
        fi

        # Check whether branch is behind
        local is_behind=false
        if $(echo "$g_status" | command grep '^## [^ ]\+ .*behind' &> /dev/null); then
            is_behind=true
        fi

        # Check wheather branch has diverged
        if [[ "$is_ahead" == true && "$is_behind" == true ]]; then
            g_out="⇕$g_out"
        else
            [[ "$is_ahead" == true ]] && g_out="⇡$g_out"
            [[ "$is_behind" == true ]] && g_out="⇣$g_out"
        fi

        if [[ -n $g_out ]]; then
            g_out=" %F{$y1}[$g_out]%f"
        fi

        echo "$(connector)%F{$g2}$LC%f%F{$kfg}%K{$g2}   $branch$g_out %k%f%F{$g2}$RC%f"
    fi
}

forest_venv () {
    if [[ -n $VIRTUAL_ENV ]]; then
        echo "$(connector)%F{$g3}$LC%f%F{$kfg}%K{$g3} ☉ $(basename $VIRTUAL_ENV) %k%f%F{$g3}$RC%f"
    fi
}

forest_info="%F{$g1}$LC%f%F{$kfg}%K{$g1} \$(forest_clock) ⁜ \$(forest_cwd) %k%f%F{$g1}$RC%f"

PROMPT="
\$(arc1)$forest_info\$(forest_git)\$(forest_venv)\$(forest_timer)
\$(arc2)$command_line"
