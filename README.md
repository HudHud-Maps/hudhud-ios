# HUDHUD App - Proof of Concept Phase

Goal of this repo is to make a simple app that can:
* Searching for a POI
* Displaying POI information on MapLibre
* Starting a navigation using MapLibre Navigation

## Setup

- Clone this Repo
- Run: git checkout main
- Run: git flow init and use the default answers like so:

```
Which branch should be used for bringing forth production releases?
   - develop
   - main
Branch name for production releases: [main]

Which branch should be used for integration of the "next release"?
   - develop
Branch name for "next release" development: [develop]

How to name your supporting branch prefixes?
Feature branches? [feature/]
Release branches? [release/]
Hotfix branches? [hotfix/]
Support branches? [support/]
Version tag prefix? []
``` 
### Git Flow

We follow the Git Flow branching model for development. The main branches are:

main: Represents what is currently on the app store.
develop: Serves as the integration branch for new features.
For feature development, create a new branch off develop:

```bash
git checkout develop
git pull origin develop
git flow feature start HHIOS-NNNN-my-awesome-feature
```
It is important to always checkout and pull develop before starting a new feature to ensure that you don't start your branch with merge conflicts.

Ensure the name of your branch contains the ticket number (HHIOS-NNNN) so that the Jira integration can link it.

After completing the feature, submit a pull request to merge it into develop.

### Resolving Merge Conflicts

To be able to merge your pull request, it needs to be uptodate with develop, so you will be asked to merge in develop and resolve merge conflicts if github complains. There are many tools like Fork, Tower, VSCode that can help you resolve conflicts. If you do not want to use tools the raw command line commands you need to run are:

```bash
git checkout develop
git fetch
git pull
git checkout nameOfYourBranch
git merge develop
```

Now resolve any merge conflicts by hand or using a merge conflict resolve tool to help you.
Once resolved, stage any files that need to be changed. Then:


```bash
git commit -am "resolve merge conflicts"
git push
```

#### Resolving Project File Merge Conflicts: Kintsugi

There is a nice tool to fix Xcode project merge conflicts: https://github.com/Lightricks/Kintsugi. Installing this on an M1 machine is tricky as the preinstalled Ruby installtion has its quirks.

Add this to your `~/.zprofile`

```bash
export GEM_HOME="$HOME/.gem"
path+=("$GEM_HOME/bin")
export PATH
```

Then install kintsugi by running

```bash
gem install kintsugi
```

To run and resolve conflicts in the project file, run the following command from your hudhud directory
```bash
kintsugi HudHud.xcodeproj/project.pbxproj
```

##### Optional GUI Git Client

If you use only the command line then your setup is finished here.
If you use a GUI git client (I recommend https://fork.dev) then this will not work as Fork doesn't know where kintsugi is installed. I fixed this by adjusting my global gitconfig in `~/.gitconfig` as follows:

```bash
[merge "kintsugi"]
	name = Kintsugi driver
	driver = export GEM_HOME="$HOME/.gem" && $GEM_HOME/bin/kintsugi driver %O %A %B %P
```

If everything is seutp correctly this is how it will look when you encounter a merge conflict. Notice how it says `Kintsugi auto-merged HudHud.xcodeproj/project.pbxproj`.

![](.tools/kintsugi-working.png)

```bash
POST git-upload-pack (339 bytes)
From https://github.com/HudHud-Maps/hudhud-ios
 * branch            develop    → FETCH_HEAD
 = [up to date]      develop    → origin/develop
[32mKintsugi auto-merged HudHud.xcodeproj/project.pbxproj[0m

Warning: Trying to add a build file without any file reference to build phase 'FrameworksBuildPhase'
Auto-merging HudHud.xcodeproj/project.pbxproj
CONFLICT (modify/delete): HudHud.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved deleted in d396af3c1a8f95265ed412e0fa99bfd3cc1603d0 and modified in HEAD.  Version HEAD of HudHud.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved left in tree.
Auto-merging HudHud/Views/ContentView.swift
CONFLICT (content): Merge conflict in HudHud/Views/ContentView.swift
Automatic merge failed; fix conflicts and then commit the result.
```


### Code Style

We use the Ray Wenderlich Code Style: https://github.com/raywenderlich/swift-style-guide. SwiftLint is used to enforce a consistent code style. Before submitting a pull request, ensure your code adheres to the SwiftLint rules. SwiftLint is run automatically as part of the build.

### SwiftFormat

We use https://github.com/nicklockwood/SwiftFormat to automatically format our swift code when on commit. It runs seamlessly in the background and normally you shouldn't notice it. Only commited files are reformated so your unstaged files are untouched.

If you want to manually start the formating I recommend installing the Xcode Source Editor Extension, however you don't need to as the minimum setup is already done.

#### Install or update the Xcode Source Editor Extension as follows

```bash
brew install --cask swiftformat-for-xcode

brew upgrade --cask swiftformat-for-xcode
```

When you installed it for the first time you need to grant it some permissions. Go to /Applications and open `SwiftFormat for Xcode`. 
Xcode Extensions are sevierly limited in functionality, they don't have access to the current project so you need to import the formatting rules. For this open `SwiftFormat for Xcode`, go to File > Open and select the `.swiftformat` file in the hudhud repo. 

##### NOTE:
This configuration will apply system wide for all of your projects.

Now you need to Enable the Xcode Extension so it shows up in Xcode. For this go to 

```
Settings > Privacy & Security > Extensions > Xcode Source Editor
```

and make sure SwiftFormat is enabled. 

![](.tools/enable-xcode-extension.png)

Now lets verify the installation was successful by opening a swift file in Xcode by going to 

```
Editor > SwiftFormat > Format File
```

If you see the menu entry then you correctly installed the Source Extension.

![](.tools/source-extension-visible.png)

##### Define a custom Shortcut

Next I would recommend to define a custom shortcut so you can reformat the currently opened file in Xcode with a button press. For this go to 

```
Xcode > Preferences > Key Bindings
```

and search for `Format File`, then you can define your prefered Keyboard Shortcut. I personally use the Apple Magic Keyboard with Numeric Keypad which gives me additional Function Keys, thefore I mapped it to F13 Key as this won't interfere with any other predefined shortcut. You can use any other shortcut just make sure its not already used by the system or Xcode, if that happens you will see a yellow alert symbol next to it.

![](.tools/custom-shortcut.png)

### Logger Structure

 You should use logger structure to handle logging and debugging messages. because it enables better control over application logging by providing a consistent interface for handling messages, facilitating easier maintenance, debugging, and ensuring the scalability of logging practices as the application grows.
 
## Usage

To use the Logger structure, first import OSLog wherever you need to log.
```bash
import OSLog
```
Second categorize your loggers in the folder named extensions check the LoggerSettings file [a link](https://github.com/HudHud-Maps/hudhud-ios/blob/develop/HudHud/Extensions/LoggerSettings.swift). Then call it and use one of the logging methods provided (e.g., debug, info, warn, error)
Ex:
```bash
Logger.searchView.debug("Authorization status authorizedAllowed")
```

### Pull Requests

You should not self merge your branches. Instead after creating your branch via the 'git flow feature ...'
command and completing your issue, you should push your branch to github and create
a pull request if it passes tests. If your branch does not pass tests please fix the issue first and re-push (see Fixing Conflicts above).
Once tests pass, assign one of the senior devs as the reviewer. The reviewer will review
your code and merge it if its ok, or request changes.

## Design

### General approach

We encourage to use SwiftUI for new UI components whenever it's possible.
When old xibs or storyboards are subjects of significant changes they should be converted to SwiftUI on the way.

All your SwiftUI views must provide Previews.
