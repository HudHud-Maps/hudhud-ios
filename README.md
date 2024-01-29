# HUDHUD Proof of Conecpt App

Goal of this repo is to make a simple app that can:
* Searching for a POI
* Displaying POI information on MapLibre
* Starting a navigation using MapLibre Navigation

## Setup

### Git Flow

We follow the Git Flow branching model for development. The main branches are:

master: Represents the production-ready code.
develop: Serves as the integration branch for new features.
For feature development, create a new branch off develop:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-awesome-feature
```
After completing the feature, submit a pull request to merge it into develop.

### Code Style

SwiftLint is used to enforce a consistent code style. Before submitting a pull request, ensure your code adheres to the SwiftLint rules. SwiftLint is run automatically as part of the build.
