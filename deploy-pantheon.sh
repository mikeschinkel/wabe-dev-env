#!/usr/bin/env bash
#
# example: deploy example.dev ssh://pantheon-git-repo-url-here:2222/~/repository.git
#
# Assumes dev computer is a Mac and sites to deploy are in the ~/Sites directory.
#
# WARNING: Add Mike Schinkel how to use this before using
#

function deploy() {

    project="$1"
    git_url="$2"
    sites_root="${HOME}/Sites"
    deploy_root="/tmp"

    save_dir=$(pwd)

    cd /tmp

    #
    # Verify we can start clean
    #
    rm -rf "/tmp/git-dir" 2>/dev/null
    rm -rf "/tmp/${project}" 2>/dev/null

    #
    # We need the .git dir
    #
    git clone "${git_url}" git-dir

    #
    # Clone the pristine Pantheon Upstream
    #
    git clone https://github.com/pantheon-systems/WordPress "${project}"
    cd "${project}"

    #
    # We are not going to use this .git repo
    #
    rm -rf .git

    #
    # Rip out it's content directory
    #
    rm -rf wp-content

    #
    # Replace with our content directory
    #
    cp -RP "${sites_root}/${project}/www/content/" wp-content/

    #
    # Don't forget the /vendor directory
    #
    cp -RP "${sites_root}/${project}/www/vendor/" vendor/

    #
    # Strip .git "submodules"
    #
    find . -name .git | xargs rm -fr

    #
    # Remove these. We do not need these on a hosted site.
    #
    rm README.md
    rm README.html
    rm license.txt
    rm wp-content/plugins/hello.php 2>/dev/null

    #
    # Delete dev only plugins
    # Later we can optimize by reading "required-dev" from composer.json
    #
    rm -rf wp-content/plugins/helpful-information/
    rm -rf wp-content/plugins/query-monitor/
    rm -rf vendor/composer/installers
    rm -rf vendor/johnpbloch

    #
    # Now get the Pantheon repo's .git dir and make it our own
    #
    mv /tmp/git-dir/.git .

    #
    # So we can view after the fact
    #
    git status

    #
    # Add any changes to staging
    #
    git add .

    #
    # Add any changes to staging
    #
    git add -u

    #
    # So we can view after the fact
    #
    git status

    #
    # Merge in any changes
    #
    git commit -m "Merging in changes"

    #
    # Now do a pull, just in case.
    # It should be up to date though.
    #
    git pull --commit --no-edit --no-ff --verbose

    #
    # So we can view after the fact
    #
    git status

    #
    # Push our changes back to Panethon
    #
    git push

    cd "${save_dir}"
}

deploy primeglobal.dev ssh://codeserver.dev.01d38677-b1d5-4ee0-a4bc-7c55e49a8f14@codeserver.dev.01d38677-b1d5-4ee0-a4bc-7c55e49a8f14.drush.in:2222/~/repository.git
