# ~~changelog-creator~~ Release Helper
```
As a member of the DV Trackers team, I want to automate some of the release process, to minimise time spent on boring admin tasks. 
``` 

This Action does two separate but related things.  

**Prepare for release/CHANGELOG creation** When a "release/x.x.x" branch is opened to `main` (or `master`), it updates the CHANGELOG file. This should be a new workflow.

**Release notes** When the `main` branch is tagged for release, it creates and outputs release notes, which can be provided to the Github Release action. This should be part of the existing release/deploy workflow.

## Prepare for release/CHANGELOG creation
A basic CHANGELOG section looks like this:
```
Version 0.2.0 (2022-02-01)
-----------------------
Publish Gradle module file with bintrayUpload (#255)
Update snyk integration to include project name in GitHub action (#8) - thanks @ExternalPerson!
```
This Action gets the version number from the name of the release branch: "release/{{ version }}". The date is today's date.

The commits are all the commits on the release branch, up until the last "Prepare for release" commit, excluding any without issue numbers. 

If the commit was authored by someone without a "@snowplowanalytics.com" email address, then it's from an external contributor. Their username is added to thank them.

The new CHANGELOG is committed with the message "Prepare for x.x.x release".

### Future work for this bit?
* Set a custom date
* Set a custom word instead of "Version", like "Core" or "Java"
* Update the whole codebase to use the new version number?!

Users would provide a list of file paths which need changing, maybe also with the exact code snippets. For example, the Ruby tracker has just one file, "lib/snowplow-tracker/version.rb". The Java tracker sets the version in "build.gradle", but there's also a test that checks if the tracker version is correct, so that would need updating too.

The Action would get those files and use regex to update the version. The version number is known because it's in the `release` branch's name.

Then it would commit the new files along with the updated CHANGELOG, for one single "Prepare for x.x.x release" commit.

## Release notes

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
