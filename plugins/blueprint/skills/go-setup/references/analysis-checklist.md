# Analysis Checklist

This checklist defines what the setup skill must analyze in a target codebase before applying the methodology. Each section feeds into tool selection, configuration, and threshold decisions.

---

## 1. Go Version

**Check for**:
- [ ] `go.mod` → `go` directive (e.g., `go 1.24`)
- [ ] `go.mod` → `toolchain` directive (e.g., `toolchain go1.24.1`)
- [ ] `go.mod` → `tool` directives (Go 1.24+ tool management)

**Impact**: Sets minimum Go version for modernization suggestions, determines available language features (generics 1.18+, range-over-int 1.22+, `go fix` 1.26+), affects which golangci-lint linters are applicable.

---

## 2. Project Structure

**Check for**:
- [ ] Single module (`go.mod` at root)
- [ ] Workspace (`go.work` file with multiple modules)
- [ ] Multi-module monorepo (multiple `go.mod` without `go.work`)
- [ ] `cmd/` directory (multiple binaries)
- [ ] `internal/` directory (private packages)
- [ ] `pkg/` directory (public packages)
- [ ] Main package (`package main` + `func main()`)
- [ ] Library module (no `main` package)
- [ ] `vendor/` directory (vendored dependencies)

**Impact**: Determines `./...` scope, per-module vs workspace execution, `deadcode` applicability (needs main entry points), coverage source directories, golangci-lint execution strategy for workspaces.

---

## 3. Build Constraints & Targets

**Check for**:
- [ ] `//go:build` tags in source files (e.g., `integration`, `e2e`, platform tags)
- [ ] CGo usage (`import "C"` in source files)
- [ ] `CGO_ENABLED` settings in Makefile/CI
- [ ] Cross-compilation targets in CI
- [ ] WASM target (`GOOS=js GOARCH=wasm` or `wasip1`)
- [ ] `embed` directive usage (`//go:embed`)

**Impact**:
- Build tags: add to `run.build-tags` in `.golangci.yml`
- CGo: may need `CGO_ENABLED=1` for lint/test, complicates CI
- WASM: separate test/build job
- Pure Go (`CGO_ENABLED=0`): simpler CI, avoid C toolchain

---

## 4. Framework / Ecosystem Detection

**Check for** (in `go.mod` dependencies):
- [ ] `github.com/gin-gonic/gin` or `github.com/labstack/echo` or `github.com/gofiber/fiber` or `github.com/go-chi/chi` → web framework
- [ ] `net/http` usage (stdlib web server)
- [ ] `github.com/spf13/cobra` or `github.com/urfave/cli` → CLI framework
- [ ] `google.golang.org/grpc` → gRPC
- [ ] `github.com/jmoiron/sqlx` or `gorm.io/gorm` or `github.com/jackc/pgx` → database
- [ ] `go.uber.org/zap` or `log/slog` → structured logging
- [ ] `github.com/stretchr/testify` → test assertions
- [ ] `go.opentelemetry.io` → observability
- [ ] No framework → pure library or utility

**Impact**:
- Web framework: enable `bodyclose`, `noctx`, `sqlclosecheck` linters; security-focused gosec rules
- CLI (cobra/cli): documentation on CLI commands, integration test patterns
- gRPC: exclude `.pb.go` generated files from linting
- Database: enable `sqlclosecheck`, `rowserrcheck` linters
- Library: raise coverage threshold, raise documentation requirements
- testify: enable `testifylint` linter

---

## 5. Existing Tool Configuration

**Check for existing config files**:
- [ ] `.golangci.yml` or `.golangci.yaml` or `.golangci.toml` — golangci-lint config
- [ ] `.testcoverage.yml` — go-test-coverage config
- [ ] `.goreleaser.yml` or `.goreleaser.yaml` — GoReleaser config
- [ ] `Makefile` or `Taskfile.yml` — build automation (check for lint/test/coverage targets)

**Check for Go tool directives** (Go 1.24+):
- [ ] `go.mod` → `tool` lines (e.g., `tool github.com/golangci/golangci-lint/v2/cmd/golangci-lint`)

**Check for legacy patterns**:
- [ ] `tools.go` file with `//go:build tools` — old-style tool dependency tracking

**Impact**: Merge methodology config into existing config; don't overwrite user customizations. Respect existing linter choices and thresholds. Migrate `tools.go` to `go.mod` tool directives if Go 1.24+.

---

## 6. Existing CI/CD

**Check for**:
- [ ] `.github/workflows/*.yml` — GitHub Actions
- [ ] `.gitlab-ci.yml` — GitLab CI
- [ ] `.circleci/config.yml` — CircleCI
- [ ] `Jenkinsfile` — Jenkins
- [ ] `.travis.yml` — Travis CI
- [ ] `Dockerfile` — container builds

**Impact**: If CI exists, merge quality checks into existing pipeline rather than overwriting. If no CI, create `.github/workflows/ci.yml`.

---

## 7. Existing Claude Code Configuration

**Check for**:
- [ ] `.claude/settings.json` — existing hooks, permissions, statusline
- [ ] `.claude/hooks/` — existing hook scripts
- [ ] `CLAUDE.md` — existing project instructions

**Impact**: Merge hooks into existing settings.json. Don't overwrite existing CLAUDE.md — append methodology reference.

---

## 8. Project Maturity Signals

**Assess**:
- [ ] Git history length (commits, age)
- [ ] Lines of code (approximate via `find . -name '*.go' -not -path './vendor/*' | xargs wc -l`)
- [ ] Number of test functions (`grep -r 'func Test' --include='*_test.go' | wc -l`)
- [ ] Existing coverage percentage (if configured)
- [ ] Number of packages (`go list ./...`)
- [ ] README quality

**Impact**: Determines initial thresholds:
| Signal | Coverage | Documentation | Complexity (cyclomatic) |
|--------|----------|---------------|------------------------|
| New (< 500 LOC) | 60% | warn | 20 |
| Small (500–5k LOC) | 70% | warn | 18 |
| Medium (5k–50k LOC) | 80% | warn | 15 |
| Large (50k+ LOC) | 80% | warn | 15 |
| Library | 85% | strict | 15 |

---

## 9. Installed Tooling

**Check for installed Go tools**:
- [ ] `golangci-lint` — unified linter (check `golangci-lint version` for v1 vs v2)
- [ ] `gotestsum` — test runner with better output
- [ ] `go-test-coverage` — coverage threshold enforcement
- [ ] `govulncheck` — vulnerability scanner
- [ ] `gofumpt` — strict formatter
- [ ] `goimports` — import management
- [ ] `deadcode` — whole-program dead code analysis

**Impact**: Determine which tools need to be installed. Prefer golangci-lint v2 over v1 (migration needed). Check if tools are managed via `go.mod` tool directives.

---

## 10. Version & Packaging

**Check for**:
- [ ] Version constant in source (`var Version = "..."` or `const Version = "..."`)
- [ ] Version file (e.g., `version.go`, `internal/version/version.go`)
- [ ] `-ldflags "-X main.Version=..."` in Makefile or CI
- [ ] `debug.ReadBuildInfo()` usage
- [ ] Git tags (`v*` pattern)
- [ ] `.goreleaser.yml` — publishing automation
- [ ] Module path with major version suffix (`/v2`, `/v3`)

**Impact**: Determines Dimension 9 activation level:
| Signal | Activation |
|--------|-----------|
| No version constant | Dimension skipped |
| Version constant, no publishing | Format validation only (quality gate) |
| Version constant + goreleaser/tags | Format validation + bump enforcement |
| Module `/v2`+ path | Validate module path matches tag prefix |

**Record**: Version source, version value, publishing mechanism.

---

## Analysis Output Format

After analysis, the setup skill should produce a structured summary:

```
Go version: 1.24
Project structure: single module, cmd/ + internal/ + pkg/
Build constraints: CGO_ENABLED=0, no build tags
Framework: chi (web), cobra (CLI)
Project size: ~8,000 LOC, 120 test functions
Existing tools: golangci-lint v1 (needs v2 migration), no coverage enforcement
Missing dimensions: security, dead code analysis, documentation, coverage threshold
CI: GitHub Actions (test + lint jobs exist)
Version: var Version in cmd/root.go, goreleaser configured
```

This summary drives the plan phase, where the skill selects which dimensions to configure and how.
