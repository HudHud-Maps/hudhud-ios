# Experimental Features Guide

## Overview
Feature flags allow us to safely develop and test new features by controlling their visibility in different environments. This system helps:
- Test features in development without affecting production
- Gradually roll out features
- A/B test different implementations
- Quick feature disabling if issues arise

## Adding New Features

### 1. Define the Feature
Add your feature to `Common/Experimental/ExperimentalFeature.swift`:

```swift
enum ExperimentalFeature: String, CaseIterable, Identifiable {
    case newUserInterface = "New UI"
    case yourNewFeature = "Feature Name"
    
    var id: String { rawValue }
}
```

### 2. Use the Feature Flag

You can use feature flags in two ways:

#### Option 1: Property Wrapper
Best for view models and business logic:

```swift
@Observable 
final class MapStore {
    // Simple boolean flag
    @Feature(.newUserInterface)
    var isNewUIEnabled: Bool
    
    // Custom value with default
    @Feature(.mapStyle, defaultValue: "satellite")
    var mapStyle: String
}
```

#### Option 2: View Modifier
Best for conditional UI rendering:

```swift
struct MapView: View {
    var body: some View {
        VStack {
            // Only shows in development & staging
            NewMapFeature()
                .experimental(.newUserInterface)
            
            // Only shows in development
            ExperimentalControl()
                .experimental(.newUserInterface, allowedIn: .development)
        }
    }
}
```

### 3. Control Features

Features can be toggled in the Debug Menu:
1. Open Debug Menu
2. Navigate to "Experimental Features" section
3. Toggle features on/off

## Environment Control

By default, features are only enabled in development and staging. You can restrict to specific environments:

```swift
// Development only
@Feature(.awesomeFeature, defaultValue: false, allowedIn: [.development])

// Development and Staging (default) - you can omit default value
@Feature(.anotherAwesomeFeature) // default value is false by default you can omit it

// All environments - use carefully
@Feature(.reallyAwesomeFeature, defaultValue: true, allowedIn: [.development, .staging, .production])
```

### Environment Guidelines
- **Development**: Use for features in active development
- **Staging**: For features ready for QA testing
- **Production**: Only for fully tested features

## Best Practices

1. **Default to Off**: Always set `defaultValue: false` for new features
2. **Clear Names**: Use descriptive feature names that indicate functionality
3. **Clean Up**: Remove feature flags once features are stable in production
4. **Document**: Add comments explaining what the feature does
5. **Test Both States**: Ensure code works with feature both enabled and disabled

## Wrapup

```swift
@Observable
final class MapStore {
    // Simple feature flag
    @Feature(.newMapStyle, defaultValue: false)
    var isNewStyleEnabled
    
    // Feature with custom value
    @Feature(.mapZoomLevel, defaultValue: 15)
    var defaultZoom: Int
}

// or in View
struct MapView: View {
    // optionn 1
    @Experimental(.newMapStyle, defaultValue: false)
    var isNewStyleEnabled
    
    var body: some View {
        Map()
            .experimental(.newMapStyle, allowedIn: .development)
    }
}
```

## Removing Feature Flags

When a feature is stable and ready for production, follow these steps to remove the feature flag:

1. Remove the feature from `ExperimentalFeature.swift`:

```swift
enum ExperimentalFeature: String, CaseIterable, Identifiable {
    case newUserInterface = "New UI"
    case yourNewFeature = "Feature Name"
}
```


2. The Swift compiler will show errors for all usages of the removed feature flag. Follow the compiler errors to:
   - Remove `@Feature` property wrappers and the feature flag declaration
   - Remove `.experimental()` view modifiers
   - Make the feature's code permanent



That's it! Remember to remove feature flags once features are stable and ready for production.
