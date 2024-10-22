# Changelog
All notable changes to this project will be documented in this file.

## Release 2.0.0
Major internal code edits!

### New features
- Provide version of module via 'OnNewStatusModuleVersion'
- Function 'getParameters' to provide PersistentData parameters
- Check if features of module can be used on device and provide this via 'OnNewStatusModuleIsActive' event / 'getStatusModuleActive' function

### Improvements
- Only keep IODD tables which are used by instances
- Share single IODD table among instances that use same IODD (no copies anymore)
- New UI design available (e.g. selectable via CSK_Module_PersistentData v4.1.0 or higher), see 'OnNewStatusCSKStyle'
- 'loadParameters' returns its success
- 'sendParameters' can control if sent data should be saved directly by CSK_Module_PersistentData
- Added UI icon and browser tab information

## Release 1.0.1

### Bugfix
- Saving and loading data to/from persistent data module did not work

## Release 1.0.0
- Initial commit