# Changelog
All notable changes to this project will be documented in this file.

## Release 2.1.2

### Bugfixes
- Bugfix of a case when deviceName is not specified in IODD file

## Release 2.1.1

### Bugfixes
- Bugfix of selecting process data format with new version of IODD interpreter

## Release 2.1.0

### New features
- User can select a subindex to read (even if subindex access is not supported)

## Release 2.0.0
Major internal code edits!

### New features
- Provide version of module via 'OnNewStatusModuleVersion'
- Function 'getParameters' to provide PersistentData parameters
- Check if features of module can be used on device and provide this via 'OnNewStatusModuleIsActive' event / 'getStatusModuleActive' function

### Improvements
- Only keep IODD tables which are used by instances
- Share single IODD table among instances that use same IODD (no copies anymore)
- Set 'LuaLoadAllEngineAPI' to false
- New UI design available (e.g. selectable via CSK_Module_PersistentData v4.1.0 or higher), see 'OnNewStatusCSKStyle'
- 'loadParameters' returns its success
- 'sendParameters' can control if sent data should be saved directly by CSK_Module_PersistentData
- Added UI icon and browser tab information

## Release 1.0.1

### Bugfix
- Saving and loading data to/from persistent data module did not work

## Release 1.0.0
- Initial commit