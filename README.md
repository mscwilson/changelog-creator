# changelog-creator

As a member of the DV Trackers team, I want to automate some of the release process to minimise time spent on boring admin tasks.  

This Action is designed to run when a PR is created from a "release/{{ version }}" branch into main/master. It gets the commits in the release branch, and the existing CHANGELOG, then commits an updated version.  

Because the commits have the issue number in the commit message, the Action can also get the issue labels to categorise the commits for the release notes ("fancyLOG").  Currently the fancyLOG is added as a comment to the PR.

This Action is based on the Github API library Octokit.

### Example basic CHANGELOG section:

```
Version 0.2.0 (2022-02-01)
-----------------------
Publish Gradle module file with bintrayUpload (#255)
Update snyk integration to include project name in GitHub action (#8) - thanks @ExternalPerson!
```

### Example fancyLOG:  

**New features**  
Add an amazing new feature (#1) **BREAKING CHANGE**  
Track a new kind of event (#4) - thanks @mscwilson! **BREAKING CHANGE**  
Output winning lottery numbers (#6)  

**Bug fixes**  
Fix events being randomly deleted (#8)  

**Under the hood**  
Remove secret keys (#5)  

### Goals
* Run a script to update the version whereever it's found in the codebase? Then, the version update and the new CHANGELOG could be correctly committed together as a "Prepare for x.x release" commit in the release branch.
* Allow the Action to be used as part of the normal release workflow, to copy the PR description and fancyLOG to the GH release notes.


### Known bugs:
Had an `Octokit::Conflict` when there was an existing CHANGELOG. 
