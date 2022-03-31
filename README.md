# changelog-test
Testing auto changelog generation


commit1 = { message: "Publish Gradle module file with bintrayUpload",
                issue: "255",
                author: "me",
                snowplower: true,
                breaking_change: false,
                type: "feature" }
    commit2 = { message: "Update snyk integration to include project name in GitHub action",
                issue: "8",
                author: "SomeoneElse",
                snowplower: false,
                breaking_change: true,
                type: "bug" }
    commit3 = { message: "Rename bufferSize to batchSize",
                issue: "306",
                author: "XenaPrincess",
                snowplower: true,
                breaking_change: false,
                type: "bug" }
    commit4 = { message: "Update all copyright notices",
                issue: "279",
                author: "XenaPrincess",
                snowplower: true,
                breaking_change: false,
                type: "admin" }
    commit5 = { message: "Allow Emitter to use a custom ExecutorService",
                issue: "278",
                author: "XenaPrincess",
                snowplower: true,
                breaking_change: false,
                type: nil }


**New features**
Publish Gradle module file with bintrayUpload (#255)
Rename bufferSize to batchSize (#306) **BREAKING CHANGE**

**Bug fixes**
Update snyk integration to include project name in GitHub action (#8) - thanks @SomeoneElse! **BREAKING CHANGE**

**Under the hood**
Update all copyright notices (#279)

**Miscellaneous**
Allow Emitter to use a custom ExecutorService (#278)
