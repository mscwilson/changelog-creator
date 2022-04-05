# ~~changelog-creator~~ Release Helper
```
As a member of the DV Trackers team, I want to automate some of the release process, to minimise time spent on boring admin tasks. 
``` 

This Action does two separate but related things. There are easier ways to do parts of this. For example, check out this [release workflow](https://github.com/snowplow-incubator/snowplow-event-recovery/blob/develop/.github/workflows/release.yml) in Snowplow Event Recovery. 

**Prepare for release/CHANGELOG creation** When a "release/x.x.x" branch is opened to `main` (or `master`), it updates and commits the CHANGELOG file. This should happen in a new workflow.

**Release notes** When the `main` branch is tagged for release, it creates and outputs release notes, which can be provided to the Github Release action (softprops/action-gh-release). This should be part of the existing release/deploy workflow.


  - [Prepare for release/CHANGELOG creation](#prepare-for-releasechangelog-creation)
    - [Future work for this bit?](#future-work-for-this-bit)
  - [Release notes](#release-notes)
    - [Future work for this bit?](#future-work-for-this-bit-1)
  - [Example workflows](#example-workflows)

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
* Set a custom date.
* Set a custom word instead of "Version", like "Core" or "Java".
* Update the whole codebase to use the new version number?!

Users would provide a list of file paths which need changing, maybe also with the exact code snippets. For example, the Ruby tracker has just one file, "lib/snowplow-tracker/version.rb". The Java tracker sets the version in "build.gradle", but there's also a test that checks if the tracker version is correct, so that would need updating too.

The Action would get those files and use regex to update the version. The version number is known because it's in the `release` branch's name.

Then it would commit the new files along with the updated CHANGELOG, for one single "Prepare for x.x.x release" commit.


## Release notes creation
Github actually has a [built-in release note generating function](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes#configuring-automatically-generated-release-notes). I couldn't work out if it would do what I wanted.

Example release notes:  

> We are pleased to announce version 1.2.3. It does loads of cool stuff.
> 
> The main new feature is really good.
> 
>**New features**  
> Add an amazing new feature (#1) **BREAKING CHANGE**  
> Track a new kind of event (#4) - thanks @mscwilson! **BREAKING CHANGE**  
> Output winning lottery numbers (#6)  
> 
> **Bug fixes**  
> Fix events being randomly deleted (#8)  
> 
> **Under the hood**  
> Remove secret keys (#5)  

The text part is the description from the PR.

The commits are the ones in between the "Prepare for x release" commits on the `main` branch. They're sorted based on their issue labels: "type:enhancement", "type:defect", or "type:admin". Issues without one of those will be under the heading Miscellaneous.

Commits are labelled "breaking change" if the issue had the "category:breaking_change" label. As above, external contributions are determined based on author email address.

### Future work for this bit?
  * Loosen label name requirements, so that e.g. "enhancement" or "bug" would work for the categories.
  * Also output Slack release post.
  * Also output Discourse release post.
  
NB: I couldn't find an existing create-Discourse-post Action in the marketplace. There is a webhook and API so it's definitely possible.

## Example workflows
### CHANGELOG
