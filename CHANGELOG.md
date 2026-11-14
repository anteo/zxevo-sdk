# Changelog

## v0.1.0

### Documentation

- (sdk) document APIs, tools, and example ports

### Features

- (sdk) add shared audio, graphics, and RAM window APIs
- (appmake) package SPG images with optional page compression
- (tools) add asset conversion and emulator capture utilities
- (examples) port evosdk TSConf demonstrations
- (xnx) port game to TSConf SDK

### Fixes

- (formatter) indent nested sjasmplus blocks
- (test-runner) stop service ROM at boot checkpoints
- (formatter) preserve SDCC hash-asm blocks

### Other changes

- (tests) format assembly helpers and documentation
- (build) wire example targets and clean generated outputs

### Refactoring

- (test-runner) unify C and ASM suites with TOML profiles
- (examples) group TSConf SDK demos under sdk

## v0.0.1

### Build and CI

- (release) automate SDK publishing and changelog generation
- (release) format sources before creating the release commit

### Documentation

- (readme) set default README and add language badges
- (examples) add BaseConf and TSConf screenshots
- (readme) explain SDK startup, size and performance

### Features

- (sdk) add ZX Evolution development kit
- (appmake) support banked TSConf TAPs
- (crt) make stdio opt-in for both profiles
- (version) expose the SDK version in C
- (release) accept patch, minor, and major increments

### Fixes

- (appmake) use the SDK packager for TSConf
- (formatter) show directory progress and omit empty summaries
- (release) publish version notes from the changelog

### Refactoring

- (formatter) remove plan and check targets
- (profiling) rename memory and CPU tools
- (crt) share startup and ROM helpers across targets
- (test-runner) move Python tooling out of the Z80 runtime
- (zesarux) share TAP entry and breakpoint helpers

### Tests

- (appmake) exercise banked TAP loading on both machines

