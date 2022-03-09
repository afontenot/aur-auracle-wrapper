#!/usr/bin/env bash

# please set your AUR build directory in your .bashrc
# the directory needs to exist
# mine looks like this:
#export aurcache="/home/adam/.cache/aur"

aur () {
    aurcache="${aurcache-}"
    if [[ ! -d "$aurcache" ]]; then
        printf "You need to point \$aurcache to your local AUR build directory.\n"
    fi
    (
    set -euo pipefail
    cd "$aurcache"
    if [[ $# -eq 0 || $1 == "-h" ]]; then
        printf "aur: a wrapper for auracle\n\n"
        printf "The following auracle commands will run unmodified:\n"
        printf "buildorder, info, rawinfo, rawsearch, search, show\n\n"
        printf " * aur upgrade <names> : fetch changes and build <names> or all\n"
        printf " * aur build <names>   : build <names> or all\n"
        printf " * aur clean <names>   : remove build files for <names> or all\n"
        printf " * aur outdated        : print upgradable pkgs and show locally merged\n"
        printf " * aur clone           : clone, but recursive and uses your cache dir\n"
        printf " * aur update          : update, but recursive and uses your cache dir\n"
        printf " * aur help            : show help for auracle instead of this wrapper\n"
    elif [[ "$1" == "help" ]]; then
        auracle -h
    elif [[ "$1" == "upgrade" ]]; then
        if [[ $# -ge 2 ]]; then
            aurupdate=("${@:2}")
        else
            aurupdate=("$(auracle --quiet outdated)")
            if [[ ${#aurupdate[@]} -gt 0 ]]; then
                printf "Updating the following: %s\n" "${aurupdate[*]}"
                printf "Would you like to proceed [Y/n]? "
                read -r response
                if [[ $response == [nN] ]]; then
                    return
                fi
            fi
        fi
        pretobuild=()
        for pkg in "${aurupdate[@]}"; do
            cd "$pkg"
            git fetch
            pkgchanges=$(git diff --color HEAD origin)
            infostr="$pkg: these are changes on the remote that have not yet been merged.\n"
            if [[ -n "$pkgchanges" ]]; then
                printf "%s%s" "$infostr" "$pkgchanges" | less -r
                printf "[Y] accept changes and build; [n] reject changes; [m] merge only\n"
                printf "What do you want to do [Y/n/m]? "
                read -r response
                if [[ $response == [nN] ]]; then
                    continue
                elif [[ $response == [mM] ]]; then
                    auracle -C "$aurcache" -r clone "$pkg"
                else
                    auracle -C "$aurcache" -r clone "$pkg"
                    pretobuild+=("$pkg")
                fi
            else
                printf "%s: no changes on remote; build anyway [Y/n]? " "$pkg"
                read -r response
                if [[ $response == [nN ]]; then
                    continue
                else
                    pretobuild+=("$pkg")
                fi
            fi
            cd ..
        done
        tobuild=()
        while IFS='' read -r line; do tobuild+=("$line"); done < <(auracle buildorder "${pretobuild[@]}" | grep TARGETAUR | awk -F' ' '{print $3}')
        for pkg in "${tobuild[@]}"; do
            cd "$pkg"
            makepkg -si || break
            cd ..
        done
    elif [[ "$1" == "build" ]]; then
        if [[ $# -lt 2 ]]; then
            pretobuild=()
            for pkg in ./*/; do
                pkg=$(basename "$pkg")
                cd "$pkg"
                pkgdate=$(pacman -Qi "$pkg" | grep 'Build Date' | awk -F': ' '{print $NF}')
                pkghaschanges=$(git log --since "$pkgdate" | wc -l)
                if [[ "$pkghaschanges" -gt 0 ]]; then
                    pretobuild+=("$pkg")
                fi
                cd ..
            done
        else
            pretobuild=("${@:2}")
        fi
        tobuild=()
        while IFS='' read -r line; do tobuild+=("$line"); done < <(auracle buildorder "${pretobuild[@]}" | grep TARGETAUR | awk -F' ' '{print $3}')
        for pkg in "${tobuild[@]}"; do
            cd "$pkg"
            pkgdate=$(pacman -Qi "$pkg" | grep 'Build Date' | awk -F': ' '{print $NF}')
            pkghaschanges=$(git log --since "$pkgdate" | wc -l)
            if [[ "$pkghaschanges" -gt 0 ]]; then
                git log -p --since "$pkgdate"
                printf "%s: these are locally merged changes that have not yet been built.\n" "$pkg"
            else
                printf "%s: there appear to be no locally merged changes.\n" "$pkg"
            fi
            printf "Would you like to proceed [Y/n]? "
            read -r response
            if [[ $response == [nN] ]]; then
                continue
            fi
            makepkg -si || break
            cd ..
        done
    elif [[ "$1" == "clean" ]]; then
        if [[ $# -ge 2 ]]; then
            pkgstoclean=("${@:2}")
        else
            pkgstoclean=()
            for pkg in ./*/; do
                pkgstoclean+=("$(basename "$pkg")")
            done
        fi
        for pkg in "${pkgstoclean[@]}"; do
            cd "$pkg"
            printf "Cleaning %s\n" "$pkg"
            git clean -fidx
            cd ..
        done
    elif [[ "$1" == "outdated" ]]; then
        auracle outdated
        changedpkgs=""
        for pkg in ./*/; do
            pkg=$(basename "$pkg")
            cd "$pkg"
            pkgdate=$(pacman -Qi "$pkg" | grep 'Build Date' | awk -F': ' '{print $NF}')
            pkghaschanges=$(git log --since "$pkgdate" | wc -l)
            if [[ "$pkghaschanges" -gt 0 ]]; then
                changedpkgs+="$pkg "
            fi
            cd ..
        done
        if [[ $changedpkgs != "" ]]; then
            printf "\nThe following have locally merged changes that are not yet built:\n"
            printf "%s\n" "$changedpkgs"
        fi
    elif [[ "$1" == "clone" ]]; then
        auracle -C "$aurcache" -r clone "${@:2}"
    elif [[ "$1" == "update" ]]; then
        auracle -C "$aurcache" -r update "${@:2}"
    else
        auracle "$@"
    fi
    )
}
