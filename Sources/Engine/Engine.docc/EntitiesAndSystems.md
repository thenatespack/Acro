# Entities, components, and systems

Store game state as components on entities, and update it with systems.

## Overview

A ``World`` holds entities and their components. An ``Entity`` is an identifier; a ``Component`` is a plain Swift value attached to it, such as a ``Transform`` or a ``MeshRenderer``. Systems are functions that run every frame and update the components they query.

## Define a component

A component is a `Codable` value type. Give it a stable ``Component/componentName`` so scene files keep loading after you rename the type:

```swift
import Engine

struct Spinner: Component, Equatable, Sendable {
    static let componentName = "Spinner"

    var speed: Float = 1  // radians per second
}
```

## Spawn entities

``World/spawn(_:)`` creates an entity with any number of components:

```swift
let world = World()
let entity = world.spawn(Transform(), Spinner(speed: 2))
```

Use ``World/add(_:to:)``, ``World/remove(_:from:)``, and ``World/get(_:for:)`` to change or read an entity's components later, and ``World/despawn(_:)`` to remove it.

## Query components

``World/query(_:_:)`` visits every entity that has the given components. ``World/queryMutating(_:_:)`` passes them `inout` and writes changes back:

```swift
world.queryMutating(Transform.self, Spinner.self) { _, transform, spinner in
    // Update transform using spinner.speed and world.time.delta.
}
```

Structural changes made during a query, such as spawning or despawning entities, are deferred until the query finishes.

## Add systems

Register a system with ``World/addSystem(_:stage:before:after:_:)``. Each system runs in a ``SystemStage``:

- ``SystemStage/fixedUpdate`` runs zero or more times per frame at a fixed timestep, for physics and frame-rate-independent gameplay.
- ``SystemStage/update`` runs once per frame. It's the default.
- ``SystemStage/lateUpdate`` runs after `update`, for work such as cameras following targets. Transform propagation runs right after it.
- ``SystemStage/renderPrep`` runs after transform propagation, to gather what the renderer needs.

`before` and `after` order a system relative to others in the same stage, by name. ``World/time`` gives the stage's ``WorldTime``, including the time step in ``WorldTime/delta``.

```swift
world.addSystem("game.spin") { world in
    let dt = world.time.delta
    world.queryMutating(Transform.self, Spinner.self) { _, transform, spinner in
        // Rotate by spinner.speed * dt.
    }
}
```

In a game module, register systems with ``GameModule``'s `system` method instead; the editor then runs them in play mode.
