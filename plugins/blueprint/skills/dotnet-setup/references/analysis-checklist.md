# Analysis Checklist

Systematically examine the target .NET project's ecosystem. Each section corresponds to information needed for the Plan phase.

---

## 1. .NET SDK & Runtime Detection

**Priority**: Must be determined first — affects all tool and framework choices.

**Check** (in priority order):
1. `global.json` → `sdk.version`
2. `.csproj` / `Directory.Build.props` → `<TargetFramework>` (e.g., `net9.0`, `net8.0`)
3. `dotnet --version` on the system

**Record**: Target framework moniker (TFM), C# language version, SDK version.

---

## 2. Solution & Project Structure

**Check**:
- `.sln` file — list all projects
- Source project locations (typically `src/`)
- Test project locations (typically `tests/`)
- Shared/common project structure
- `Directory.Build.props` and `Directory.Build.targets` (centralized MSBuild properties)
- `Directory.Packages.props` (central package management)
- Multi-target projects (`<TargetFrameworks>`)

**Patterns to detect**:
- Clean Architecture (Domain, Application, Infrastructure, Presentation/API layers)
- Vertical slice architecture
- Monorepo with multiple solutions
- Single-project application
- Library package

**Record**: Solution path, source projects, test projects, shared projects, architecture pattern.

---

## 3. Framework Detection

**Check each `.csproj` for SDK and package references**:

| Framework | Detection Signal |
|-----------|-----------------|
| ASP.NET Core Web API | `Sdk="Microsoft.NET.Sdk.Web"`, `Microsoft.AspNetCore.*` packages |
| ASP.NET Core MVC | `Microsoft.AspNetCore.Mvc` |
| Blazor | `Microsoft.AspNetCore.Components.*` |
| Worker Service | `Microsoft.Extensions.Hosting` without Web SDK |
| MAUI | `Sdk="Microsoft.NET.Sdk.Maui"` |
| WPF | `<UseWPF>true</UseWPF>` |
| WinForms | `<UseWindowsForms>true</UseWindowsForms>` |
| Console | `Sdk="Microsoft.NET.Sdk"` with `<OutputType>Exe</OutputType>` |
| Library | `Sdk="Microsoft.NET.Sdk"` without OutputType |
| gRPC | `Grpc.AspNetCore` package |
| Entity Framework | `Microsoft.EntityFrameworkCore.*` |
| MediatR | `MediatR` package |
| FluentValidation | `FluentValidation*` package |
| AutoMapper | `AutoMapper*` package |
| Dapper | `Dapper` package |

**Record**: Primary framework, ORM, validation library, mediator pattern, serialization.

---

## 4. Test Framework Detection

**Check test `.csproj` files for**:

| Framework | Detection Signal |
|-----------|-----------------|
| xUnit | `xunit`, `xunit.runner.*` packages |
| NUnit | `NUnit`, `NUnit3TestAdapter` packages |
| MSTest | `MSTest.TestAdapter`, `MSTest.TestFramework` |
| bUnit (Blazor) | `bunit` package |
| Moq | `Moq` package |
| NSubstitute | `NSubstitute` package |
| FakeItEasy | `FakeItEasy` package |
| FluentAssertions | `FluentAssertions` package |
| Shouldly | `Shouldly` package |
| Bogus | `Bogus` package |
| AutoFixture | `AutoFixture` package |
| Testcontainers | `Testcontainers*` package |
| Verify | `Verify.*` packages |

**Record**: Test framework, mocking library, assertion library, test data generators, integration test tools.

---

## 5. Existing Tool Configuration

**Check for existing quality tooling**:

| Tool | Detection Signal |
|------|-----------------|
| .editorconfig | `.editorconfig` file in repo root |
| StyleCop.Analyzers | Package reference in `.csproj` or `Directory.Build.props` |
| Roslynator.Analyzers | Package reference |
| SonarAnalyzer.CSharp | Package reference |
| Microsoft.CodeAnalysis.NetAnalyzers | Package reference (or implicit in .NET 5+) |
| Meziantou.Analyzer | Package reference |
| coverlet | `coverlet.collector` or `coverlet.msbuild` package in test projects |
| ReportGenerator | Package or dotnet tool |
| Central Package Management | `Directory.Packages.props` with `<ManagePackageVersionsCentrally>` |
| Nullable reference types | `<Nullable>enable</Nullable>` in `.csproj` or `Directory.Build.props` |
| TreatWarningsAsErrors | `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` |
| AnalysisLevel | `<AnalysisLevel>` setting |
| dotnet-outdated | Listed as dotnet tool |
| dotnet-format | Built-in since .NET 6 |

**Record**: Which tools are configured, their settings, any custom rule configurations.

---

## 6. Existing CI/CD

**Check** (in priority order):
1. `.github/workflows/*.yml` → GitHub Actions
2. `.gitlab-ci.yml` → GitLab CI
3. `azure-pipelines.yml` → Azure DevOps
4. `Jenkinsfile` → Jenkins
5. `.circleci/config.yml` → CircleCI
6. `appveyor.yml` → AppVeyor

**For each CI found, note**:
- Which quality checks run
- Which .NET SDK version is used
- Whether tests run with coverage
- Whether NuGet audit runs

**Record**: CI platform, existing jobs, gaps vs methodology.

---

## 7. Existing Claude Code Configuration

**Check**:
- `.claude/settings.json` — existing hook registrations
- `.claude/hooks/` — existing hook scripts
- `CLAUDE.md` — existing project instructions
- `.claude/rules/` — existing rule files

**Record**: What hooks exist, any conflicts with methodology hooks.

---

## 8. Project Maturity Signals

**Check**:
- Lines of code (rough estimate from source projects)
- Test coverage (if measurable)
- Number of contributors (`git shortlog -sn --no-merges | wc -l`)
- Age of project (`git log --reverse --format='%ai' | head -1`)
- NuGet packages published? (`.nupkg` generation, `<IsPackable>true</IsPackable>`)
- README quality

**Maturity thresholds** (for dimension adaptation):

| Signal | New | Small | Medium | Large |
|--------|-----|-------|--------|-------|
| LOC | < 500 | 500–5k | 5k–50k | 50k+ |
| Coverage target | 70% | 80% | 85% | 90% |
| Documentation | minimal | public API | full API | full + examples |
| Architecture tests | skip | skip | recommended | required |

**Record**: Maturity level, recommended threshold adjustments.

---

## 9. NuGet Configuration

**Check**:
- `nuget.config` — custom feeds, authentication
- `Directory.Packages.props` — centralized version management
- `.config/dotnet-tools.json` — local dotnet tools

**Record**: Custom feeds, tool manifest, central package management.

---

## 10. Version & Packaging

**Check for**:
- [ ] `.csproj` → `<Version>` element
- [ ] `.csproj` → `<PackageVersion>` element (overrides Version for NuGet)
- [ ] `Directory.Build.props` → `<Version>` (centralized versioning)
- [ ] `.csproj` → `<IsPackable>true</IsPackable>` (NuGet package intent)
- [ ] `.csproj` → `<GeneratePackageOnBuild>true</GeneratePackageOnBuild>`
- [ ] `.nuspec` file (legacy NuGet packaging)
- [ ] `.csproj` → `<VersionPrefix>` and `<VersionSuffix>` (split version fields)

**Impact**: Determines Dimension 9 activation level:
| Signal | Activation |
|--------|-----------|
| No Version property | Dimension skipped |
| Version property, not packable | Format validation only (quality gate) |
| Version property + IsPackable/GeneratePackageOnBuild | Format validation + bump enforcement |
| Centralized in Directory.Build.props | Single check against central file |

**Record**: Version source file, version value, packaging intent, centralized vs per-project.

---

## Analysis Output Format

Present the analysis as a structured summary:

```
## Target Project Analysis

### Environment
- .NET SDK: 9.0.100
- Target Framework: net9.0
- C# Language Version: 13
- Solution: MyApp.sln

### Structure
- Source projects: src/MyApp.Api, src/MyApp.Core, src/MyApp.Infrastructure
- Test projects: tests/MyApp.Api.Tests, tests/MyApp.Core.Tests
- Architecture: Clean Architecture (Domain, Application, Infrastructure, API)
- Central Package Management: Yes (Directory.Packages.props)

### Framework
- Primary: ASP.NET Core Web API
- ORM: Entity Framework Core 9.0
- Validation: FluentValidation
- Mediator: MediatR

### Testing
- Framework: xUnit
- Mocking: NSubstitute
- Assertions: FluentAssertions
- Coverage: coverlet (current: 62%)

### Existing Quality Tools
- .editorconfig: Yes (basic)
- Nullable: Enabled
- Analyzers: Microsoft.CodeAnalysis.NetAnalyzers (default)
- StyleCop: Not configured
- TreatWarningsAsErrors: No

### CI/CD
- Platform: GitHub Actions
- Existing jobs: build, test
- Missing: lint, security, coverage enforcement

### Dimension Gaps
- [x] Testing & Coverage — partial (tests exist, no coverage threshold)
- [ ] Linting & Formatting — basic .editorconfig only
- [x] Type Safety — nullable enabled
- [ ] Security Analysis — no security tooling
- [ ] Code Complexity — no complexity limits
- [ ] Dead Code — no dead code detection
- [ ] Documentation — no XML doc enforcement
- [ ] Architecture — no architecture tests
```
