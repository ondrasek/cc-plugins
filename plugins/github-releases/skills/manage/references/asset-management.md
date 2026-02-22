---
type: reference
used_by: manage
description: Release asset naming conventions, platform matrix, checksums, and upload verification.
---

# Asset Management

## Naming Conventions

### Standard Patterns

```
{project}-{version}-{os}-{arch}.{ext}
```

| Component | Examples |
|-----------|---------|
| project | `myapp`, `my-tool` |
| version | `1.2.3`, `v1.2.3` (match tag convention) |
| os | `linux`, `darwin`, `windows` |
| arch | `amd64`, `arm64`, `x86_64`, `aarch64` |
| ext | `.tar.gz`, `.zip`, `.deb`, `.rpm`, `.msi`, `.dmg` |

**Examples**:
- `myapp-1.2.3-linux-amd64.tar.gz`
- `myapp-1.2.3-darwin-arm64.tar.gz`
- `myapp-1.2.3-windows-amd64.zip`

### Platform Matrix

Common cross-platform release matrix:

| OS | Architecture | Extension |
|----|-------------|-----------|
| Linux | amd64, arm64 | `.tar.gz`, `.deb`, `.rpm` |
| macOS | amd64 (Intel), arm64 (Apple Silicon) | `.tar.gz`, `.dmg` |
| Windows | amd64, arm64 | `.zip`, `.msi` |

### Checksum Files

Include a checksum file for verification:

```
checksums.txt          — SHA-256 checksums for all assets
SHA256SUMS             — alternative name
{project}-{version}-checksums.sha256
```

**Checksum file format** (one line per file):
```
e3b0c44298fc1c149afbf4c8996fb924  myapp-1.2.3-linux-amd64.tar.gz
d7a8fbb307d7809469ca9abcb0082e4f  myapp-1.2.3-darwin-arm64.tar.gz
```

Generate checksums:
```bash
shasum -a 256 myapp-*.tar.gz myapp-*.zip > checksums.txt
```

## Upload Verification

After uploading assets, verify they're accessible:

```bash
# List assets with sizes
gh release view TAG --json assets --jq '.assets[] | "\(.name) — \(.size) bytes — \(.downloadCount) downloads"'
```

**Check**:
- All expected platform binaries are present
- File sizes are reasonable (not 0 bytes, not unexpectedly small)
- Checksum file is included

## Download Patterns

```bash
# Download all assets from latest release
gh release download --pattern "*"

# Download specific platform
gh release download TAG --pattern "*linux-amd64*"

# Download to specific directory
gh release download TAG --dir ./release-assets

# Download checksums only
gh release download TAG --pattern "*checksum*"
```

## Size Limits

- **Per-file limit**: 2 GB
- **No per-release total limit** (but be reasonable)
- If files exceed 2 GB: split into parts or use Git LFS
