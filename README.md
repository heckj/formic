# formic

Swift library to support IT Automation tasks.

## Experiment

Embracing the swift-format world in this project. 
I've' added a dependency on `swift-format`, so the following package plugin commands are available:

```bash
swift package lint-source-code
```

```bash
swift package format-source-code --allow-writing-to-package-directory
```

swift-format uses the built-in default style to lint and format code. 
A `.swift-format` configuration file can be used to customize the style used.
See [Configuration](https://github.com/swiftlang/swift-format/blob/main/Documentation/Configuration.md) for more details on customization options.
