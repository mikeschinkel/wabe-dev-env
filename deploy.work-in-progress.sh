#!/usr/bin/env bash
#
# deploy
#

_pause() {
    echo
    pause.sh "Press a key to continue..."
    echo
}

_show_error() {

    if [ "$2" != "skip" ]; then
        >&2 echo
    fi

    >&2 echo "ERROR: $1"
    >&2 echo

    if [ "$3" != "continue" ]; then
        exit;
    fi

}

_ensure_in_www() {
    cur_dir=${PWD##*/}

    if [ "${cur_dir}" != "www" ]; then
        _show_error "The function must be called from the www directory."
    fi
    if [ ! -f deploy ]; then
        _show_error "The file 'deploy' does not exist. This must be the wrong directory. Is this not 'wabe.dev/www'?"
    fi
}

_ensure_release_json() {
    if [ ! -f release.json ]; then
        _show_error "The file 'release.json' does not yet exist."
    fi
}

_get_release_tag() {
    local index
    local cur_dir

    [[ "$1" == "" ]] && index="0" || index="$1"

    _ensure_in_www

    _ensure_release_json

    release_tag=$(jq -r ".[${index}].tag" release.json)
    echo "${release_tag}"

}

_ensure_new_release_tag() {

    _ensure_release_json

    local last_release=$(_get_last_release_from_file)
    local new_release_tag=$(_get_release_tag)

    if [ "${new_release_tag}" == "${last_release}" ]; then
        _show_error "release.json not updated. ${new_release_tag} already released. Please add new release tag at top of file."
    fi
}

_get_current_git_branch() {
    local current_branch=$(git branch --list | grep "*" | cut -f2 -d" ")
    echo "${current_branch}"
}

_update_last_release_file() {
    _ensure_new_release_tag

    git stash
    local current_branch=$(_get_current_git_branch)
    git checkout master
    local new_release_tag=$(_get_release_tag)
    echo "${new_release_tag}" > last-release
    git add last-release
    git commit -m "Updating 'last-release' to contain ${new_release_tag}."
    git checkout "${current_branch}"
    git stash pop

}

_get_last_release_from_file() {
    if [ ! -f last-release ]; then
        echo "" > last-release
    fi
    cat last-release
}

_get_current_git_status() {
    echo $(git status --porcelain)
}

_ensure_release_json_needs_commit() {
    git_status=$(_get_current_git_status |  cut -f2 -d" " )
    if [ "${git_status}" != "release.json" ]; then
        _show_error "'git status' should return one (1) changed file only; 'release.json'. Fix and try again." -- continue
        _show_error "${git_status}" skip
    fi
}

_ensure_clean_git_status() {
    git_status=$(_get_current_git_status)
    if [ "${git_status}" != "" ]; then
        _show_error "Repository needs attention. Please fix before and try again." -- continue
        _show_error "${git_status}" skip
    fi
}

#
# Prepare Release
#
prepare() {

    _ensure_in_www
    _ensure_release_json_needs_commit
    _ensure_new_release_tag

    local new_release_tag=$(_get_release_tag)

    echo "Staging release.json for release ${new_release_tag}..."
    git add release.json
    _pause

    echo "Commiting release.json..."
    git commit -m "Update release.json."
    _pause

    echo "Checking out 'release' branch..."
    git checkout release
    _pause

    echo "Merging in 'develop' branch to 'release'..."
    git merge develop
    _pause

    echo "Pushing committed 'release' branch to 'origin'..."
    git push origin release
    _pause

    echo "Updating 'last-release' file to release ${new_release_tag}..."
    _update_last_release_file
    _pause

    echo "Done."
}

#
# Promote Release to Production
#
promote() {

    _ensure_new_release_tag

    local saved_branch=$(_get_current_git_branch)
    local new_release_tag=$(_get_release_tag)
    if [ "${new_release_tag}" == "" ]; then
        _show_error "No release tag; check release.json."
    fi

    echo "Stashing work..."
    git stash
    _pause

    echo "Checking out 'master'..."
    git checkout master
    _pause

    echo "Merging from 'release' to 'master'..."
    git merge release
    _pause

    echo "Pushing 'master' to 'origin'..."
    git push origin master
    _pause

    echo "Tagging release as ${new_release_tag}..."
    git tag -a -m "${new_release_tag}"
    git push --tags
    _pause

    echo "Returning to branch ${saved_branch} and poping stash..."
    git checkout "${saved_branch}"
    git stash pop
    echo

    echo "Done."

}

#
# Rollback to previous release
#
rollback() {

    [[ "$1" == "" ]] && index="1" || index="$1"

    local index
    local prior_release_tag=$(_get_release_tag "${index}")
    local current_branch=$(_get_current_git_branch)

    git stash
    _pause
    git checkout master
    _pause
    git reset --hard "${prior_release_tag}"
    _pause
    git push -f origin master
    _pause
    git checkout "${current_branch}"
    git stash pop
    echo

}

self_commit() {
    git add deploy
    git commit -m "Update deployment script"
    git push
}

case "$1" in

    prepare) prepare && exit ;;
    promote) promote && exit ;;
    rollback) rollback && exit ;;
    self_commit) self_commit && exit ;;
    *) cat <<USAGE

USAGE:  deploy [prepare|promote|rollback|self_commit]

    NOTE: Your current subdirectory must be 'wabe.dev/www'.
USAGE
    ;;

esac



