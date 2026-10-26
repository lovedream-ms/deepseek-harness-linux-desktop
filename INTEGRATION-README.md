# Automated Build Workflow for DeepSeek Harness Linux

This directory contains the files needed to add automated building of DeepSeek Harness Linux deb packages to the [lql341/deepseek-harness-linux-desktop](https://github.com/lql341/deepseek-harness-linux-desktop) repository.

## Overview

The automated build workflow monitors the upstream [DeepSeek Harness repository](https://github.com/deepseek-ai/deepseek-harness) for new releases and automatically builds Linux-compatible deb packages using the existing patch set.

## Files Included

- `.github/workflows/automated-build.yml` - The GitHub Actions workflow definition

## How It Works

1. **Scheduled Check**: The workflow runs daily at 2 AM UTC to check for new DeepSeek Harness versions
2. **Version Detection**: Automatically detects the latest version from the upstream repository
3. **Duplicate Prevention**: Skips building if a release for the detected version already exists
4. **Build Process**: 
   - Clones the latest DeepSeek Harness source
   - Applies Linux compatibility patches using the existing `apply.sh` script
   - Builds the deb package using the established process
5. **Release**: Creates a GitHub Release with the built deb package

## Manual Trigger

The workflow can also be triggered manually with these options:
- **target_tag**: Specify a particular version to build (e.g., `dsh-v0.2.1-rc.3`)
- **build_prerelease**: Whether to build pre-release versions

## Integration Instructions

To integrate this into the target repository:

1. Create the directory `.github/workflows/` in the repository
2. Copy the `automated-build.yml` file to that directory
3. Ensure the workflow has appropriate permissions (Contents: Read and write)
4. The workflow will automatically begin monitoring for new releases

## Benefits

- **Automatic Updates**: New Linux packages are built automatically when upstream releases new versions
- **Consistency**: All packages are built using the same process and environment
- **Quality Assurance**: Built-in verification ensures packages are valid
- **Reduced Manual Effort**: No need to manually build packages for each new release

## Security Considerations

- The workflow only builds from official upstream releases
- All build steps follow the same process as the manual method
- The workflow has minimal required permissions