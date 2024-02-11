# HUDHUD Proof of Conecpt App

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

master: Represents the production-ready code.
develop: Serves as the integration branch for new features.
For feature development, create a new branch off develop:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/HHIOS-NNNN-my-awesome-feature
```
Ensure the name of your branch contains the ticket number (HHIOS-NNNN) so that the Jira integration can link it.

After completing the feature, submit a pull request to merge it into develop.

### Code Style

SwiftLint is used to enforce a consistent code style. Before submitting a pull request, ensure your code adheres to the SwiftLint rules. SwiftLint is run automatically as part of the build.
