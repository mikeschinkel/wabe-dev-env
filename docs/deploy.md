#WABE Deploy Process

_*ONLY for Pantheon NATIVE*_

##Process

- Commit releasable code to local repo
- Make Release
- Ask Client to Review (or not)
- Maybe Rollback


###Make Release 
When code is all committed and release candidate is ready:

- Document the features included in this release
- Fill out `release.json` 
- Run `make_release()`:

		cd www
		./init-deploy
		make_release

###Ask Client to Review
- Or not
	
###Promote Release to Live 
If client likes Release or Bug Fix is ready

		cd www
		./init-deploy
		promote_to_live

###Maybe Rollback
If rollback is needed:

		cd www
		./init-deploy
		rollback_release


##Branching Strategy

- `{feature}`
    - Merge to `develop`
- `develop` => Pantheon multidev branch `develop`
- `release` => Pantheon multidev branch `release`
- `hot fix`
    - Merge to `master`
    - Merge to `develop`
- `master`  = > Pantheon Dev
    - Copy to Pantheon Test
    - Copy to Pantheon Live

##Tagging

- Release: `R-YYYY-MM-DD[-x]`
- `[-x]` starts with `-a`

