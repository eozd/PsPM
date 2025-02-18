# PsPM Release Checklist
This file contains the steps required for finalising a PsPM release. Many items at the beginning don't have to be followed sequentially. However, it is important that there aren't any revisions (commits) that implement/fix something new in the release branch, because we don't merge these branches back to trunk. Therefore, it is sensible to create the release branch after making absolutely sure that no new stuff will be implemented.

- [ ] Update version number & date in
	 - [ ] `pspm_msg.txt`
	 - [ ] `pspm_quit`
	 - [ ] `pspm_ui`
	 - [ ] `pspm_ui_app`
- [ ] Manual and Developers Guide: front pages
- [ ] Make sure both manuals are updated
- [ ] Add release notes section of the new version to manual (at the end) and release\_notes.tex
- [ ] Get the manual reviewed
- [ ] Create manual and dev guide PDFs using `lyx`
- [ ] Check if underscores and dashes are visible in newly added manual sections
- [ ] Create new git branch for this release
- [ ] Merge branch 'develop' into branch 'master' 
- [ ] Delete temporary files if there are any, like `.asv`.
- [ ] Create zip of the new branch
- [ ] Make sure zip doesn't contain any svn related files. As a sanity check, the zip file should be roughly the same size as the previous version zip files (maybe slightly larger but not much)
- [ ] Create a release on GitHub
- [ ] Upload zip to GitHub
  - [ ] Make sure the newly added zip file is the default download
- [ ] Add release message to GitHub
- [ ] Change release number on lab webpage (gh-pages branch)
- [ ] Add release message to lab webpage (gh-pages branch)
- [ ] Update `PsPM_installer` in `/src/helper` with the new version number and download link, and merge this pull request on the official release date.

