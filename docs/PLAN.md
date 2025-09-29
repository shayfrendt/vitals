# Vitals - Rails Code Health Assessment System

## Overview

**Vitals** is a CLI tool that checks the critical health indicators of your Rails codebase, similar to how a doctor checks vital signs (heart rate, blood pressure, temperature).

### Purpose

Provide automated, research-backed assessment of Rails codebase maintainability through three key metrics:

1. **Complexity** - How difficult is the code to understand and modify?
2. **Smells** - Does the code exhibit poor structural patterns?
3. **Coverage** - Is the code adequately tested?

---

## Research Foundation

Based on 2024-2025 software engineering research:

- **Cyclomatic Complexity**: Complex code requires 2.5-5x more maintenance effort (NIST threshold: ≤10)
- **Code Smells**: Automated detection outperforms manual reviews; high coupling = 2-3x harder to change
- **Test Coverage**: 35% fewer bugs with comprehensive testing; 20% fewer production incidents (State of DevOps 2025)

### Key Tools for Rails

1. **RuboCop** (25k+ ⭐) - Style + complexity metrics
2. **Reek** - Code smell detection (coupling, cohesion issues)
3. **Flog** - ABC complexity scores
4. **SimpleCov** - Test coverage reporting
5. **RubyCritic** - Aggregator that wraps Reek, Flay, Flog with quality scores

---

## Architecture

```
┌─────────────────────────────────────────┐
│   vitals check [vital-type]             │
│   Rails Code Health CLI                 │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       │  Orchestrator  │
       └───────┬────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
    ▼          ▼          ▼
┌─────────┐ ┌─────────┐ ┌──────────┐
│Complexity│ │ Smells │ │ Coverage │
│ Vital   │ │ Vital  │ │  Vital   │
└─────────┘ └─────────┘ └──────────┘
```

### Data Flow

```
User invokes CLI command
    ↓
CLI parses arguments
    ↓
Orchestrator initialized ← Config
    ↓
Run selected vitals (parallel where possible)
    ↓
┌─────────┬─────────┬─────────┐
│Complexity│ Smells │ Coverage│
│  Vital  │  Vital │  Vital  │
└────┬────┴────┬───┴────┬────┘
     └─────────┴────────┘
             ↓
    VitalResult collection
             ↓
    HealthReport generated
             ↓
    Reporter formats output
             ↓
    Output to user + Exit code
```

---

## Available Vitals (Check Types)

### 1. Complexity Vital 🧠

**What it measures**: Cyclomatic complexity, ABC complexity

**Tools**: RuboCop Metrics, Flog

**Healthy threshold**: ≤10 per method (NIST standard)

**Example output**:
```
Complexity Vital: 🟢 HEALTHY
├─ Average complexity: 4.2
├─ Methods over threshold: 3/487 (0.6%)
└─ Worst offenders:
   • OrdersController#create (complexity: 15) app/controllers/orders_controller.rb:42
   • User#calculate_score (complexity: 12) app/models/user.rb:89
```

### 2. Smells Vital 👃

**What it measures**: Code smells, coupling, cohesion

**Tools**: Reek, RubyCritic

**Healthy threshold**: RubyCritic score ≥80/100

**Example output**:
```
Smells Vital: 🟡 NEEDS ATTENTION
├─ Code quality score: 76/100
├─ Total smells detected: 12
└─ Critical smells:
   • TooManyMethods: UsersController (18 methods)
   • LongParameterList: PaymentService#process (6 params)
   • FeatureEnvy: Order#notify_customer
```

### 3. Coverage Vital 🛡️

**What it measures**: Test coverage (line & branch)

**Tools**: SimpleCov

**Healthy threshold**: ≥80% coverage

**Example output**:
```
Coverage Vital: 🟢 HEALTHY
├─ Line coverage: 87.3%
├─ Branch coverage: 82.1%
└─ Uncovered critical paths:
   • app/services/billing_service.rb (45% coverage)
   • app/models/payment.rb (62% coverage)
```

---

## Usage

```bash
# Run all vitals
vitals check [path]

# Run specific vital
vitals check complexity [path]
vitals check smells [path]
vitals check coverage [path]

# Output formats
vitals check --format=json          # JSON output for CI/CD
vitals check --format=html          # HTML dashboard
vitals check --format=cli           # Default: terminal output

# Threshold overrides
vitals check --complexity-threshold=15
vitals check --coverage-threshold=90

# Generate full health report
vitals report [path]
```

---

## Overall Health Score

The system provides an aggregate health score (0-100) weighted as:
- Complexity: 40%
- Smells: 30%
- Coverage: 30%

**Score interpretation**:
- 90-100: 🟢 Excellent maintainability
- 75-89: 🟢 Good maintainability
- 60-74: 🟡 Needs improvement
- <60: 🔴 High maintenance risk

**Example report**:
```
╔═══════════════════════════════════════════╗
║   CODEBASE HEALTH REPORT                  ║
╠═══════════════════════════════════════════╣
║   Overall Score: 82/100 🟢 GOOD          ║
╠═══════════════════════════════════════════╣
║   Complexity Vital:  🟢 92/100 (Excellent)║
║   Smells Vital:      🟡 76/100 (Fair)     ║
║   Coverage Vital:    🟢 87/100 (Good)     ║
╠═══════════════════════════════════════════╣
║   Recommendation: Address code smells in  ║
║   controllers and services directory      ║
╚═══════════════════════════════════════════╝
```

---

## Configuration

Create a `.vitals.yml` file in your project root:

```yaml
complexity:
  threshold: 10
  exclude:
    - db/migrate/**

smells:
  threshold: 80
  enabled_detectors:
    - TooManyMethods
    - LongParameterList
    - FeatureEnvy

coverage:
  threshold: 80
  require_branch_coverage: true

output:
  format: cli
  color: true
```

---

## Technical Architecture

### File Structure

```
vitals/
├── bin/
│   └── vitals                              # Executable entry point
├── lib/
│   ├── vitals/
│   │   ├── vitals/
│   │   │   ├── base_vital.rb
│   │   │   ├── complexity_vital.rb
│   │   │   ├── smells_vital.rb
│   │   │   └── coverage_vital.rb
│   │   ├── reporters/
│   │   │   ├── cli_reporter.rb
│   │   │   ├── json_reporter.rb
│   │   │   └── html_reporter.rb
│   │   ├── cli.rb
│   │   ├── config.rb
│   │   ├── orchestrator.rb
│   │   ├── vital_result.rb
│   │   ├── health_report.rb
│   │   └── version.rb
│   └── vitals.rb
├── spec/
│   ├── vitals/
│   │   ├── vitals/
│   │   ├── reporters/
│   │   └── integration/
│   └── spec_helper.rb
├── Gemfile
├── Rakefile
├── vitals.gemspec
└── README.md
```

### Dependencies

```ruby
# vitals.gemspec
spec.add_dependency "thor", "~> 1.3"           # CLI framework
spec.add_dependency "rubocop", "~> 1.60"       # Complexity analysis
spec.add_dependency "reek", "~> 6.3"           # Code smells
spec.add_dependency "rubycritic", "~> 4.9"     # Quality aggregation
spec.add_dependency "flog", "~> 4.8"           # ABC complexity
spec.add_dependency "simplecov", "~> 0.22"     # Coverage analysis
spec.add_dependency "tty-box", "~> 0.7"        # CLI formatting
spec.add_dependency "tty-table", "~> 0.12"     # CLI tables
spec.add_dependency "pastel", "~> 0.8"         # CLI colors

spec.add_development_dependency "rspec", "~> 3.13"
spec.add_development_dependency "rake", "~> 13.0"
```

### Core Classes

#### BaseVital

```ruby
class BaseVital
  attr_reader :name, :threshold, :config

  def initialize(config:)
  def check(path:)           # Returns VitalResult
  def healthy?(score:)        # Boolean
  def score(results:)         # 0-100
  def recommendations        # Array of strings
end
```

#### ComplexityVital

```ruby
class ComplexityVital < BaseVital
  def check(path:)
    rubocop_results = run_rubocop_complexity(path)
    flog_results = run_flog(path)

    VitalResult.new(
      vital: :complexity,
      score: calculate_score(rubocop_results, flog_results),
      violations: extract_violations(rubocop_results),
      metadata: {
        average_complexity: calculate_average(rubocop_results),
        methods_over_threshold: count_violations(rubocop_results),
        worst_offenders: top_offenders(rubocop_results, limit: 10)
      }
    )
  end
end
```

#### SmellsVital

```ruby
class SmellsVital < BaseVital
  def check(path:)
    reek_results = run_reek(path)
    rubycritic_results = run_rubycritic(path)

    VitalResult.new(
      vital: :smells,
      score: rubycritic_results.score,
      violations: extract_smells(reek_results),
      metadata: {
        total_smells: reek_results.count,
        smell_distribution: categorize_smells(reek_results),
        critical_files: identify_critical_files(rubycritic_results)
      }
    )
  end
end
```

#### CoverageVital

```ruby
class CoverageVital < BaseVital
  def check(path:)
    coverage_results = parse_simplecov_results(path)

    VitalResult.new(
      vital: :coverage,
      score: coverage_results.line_coverage,
      violations: identify_uncovered_files(coverage_results),
      metadata: {
        line_coverage: coverage_results.line_coverage,
        branch_coverage: coverage_results.branch_coverage,
        uncovered_critical_paths: find_critical_uncovered(coverage_results)
      }
    )
  end
end
```

#### VitalResult

```ruby
class VitalResult
  attr_reader :vital, :score, :violations, :metadata, :timestamp

  def initialize(vital:, score:, violations:, metadata:)
    @vital = vital
    @score = score
    @violations = violations
    @metadata = metadata
    @timestamp = Time.now
  end

  def healthy?(threshold:)
    score >= threshold
  end

  def to_h
    {
      vital: vital,
      score: score,
      healthy: healthy?,
      violations: violations.map(&:to_h),
      metadata: metadata,
      timestamp: timestamp.iso8601
    }
  end
end
```

#### HealthReport

```ruby
class HealthReport
  attr_reader :overall_score, :vital_results, :config

  def initialize(vital_results:, config:)
    @vital_results = vital_results
    @config = config
    @overall_score = calculate_overall_score
  end

  def calculate_overall_score
    # Weighted average:
    # Complexity: 40%
    # Smells: 30%
    # Coverage: 30%
  end

  def health_status
    case overall_score
    when 90..100 then :excellent
    when 75..89  then :good
    when 60..74  then :needs_improvement
    else              :high_risk
    end
  end

  def to_h
    {
      overall_score: overall_score,
      health_status: health_status,
      vitals: vital_results.map(&:to_h),
      recommendations: recommendations,
      generated_at: Time.now.iso8601
    }
  end
end
```

---

## Implementation Plan

### Phase 1: Project Setup & Foundation (2 hours)

1. Initialize Ruby gem structure: `bundle gem vitals`
2. Add dependencies to `vitals.gemspec`
3. Run `bundle install`
4. Create base classes:
   - `lib/vitals/config.rb`
   - `lib/vitals/vitals/base_vital.rb`
   - `lib/vitals/vital_result.rb`
   - `lib/vitals/health_report.rb`
5. Create corresponding unit tests

**Completion criteria**: All base classes have unit tests passing

### Phase 2: Implement Individual Vitals (6 hours)

#### 2.1 Complexity Vital
- Create `lib/vitals/vitals/complexity_vital.rb`
- Wrap RuboCop's `Metrics/CyclomaticComplexity` cop
- Integrate Flog for ABC complexity
- Create `spec/vitals/vitals/complexity_vital_spec.rb`

#### 2.2 Smells Vital
- Create `lib/vitals/vitals/smells_vital.rb`
- Wrap Reek for code smell detection
- Integrate RubyCritic for overall quality score
- Create `spec/vitals/vitals/smells_vital_spec.rb`

#### 2.3 Coverage Vital
- Create `lib/vitals/vitals/coverage_vital.rb`
- Parse SimpleCov's `.resultset.json`
- Create `spec/vitals/vitals/coverage_vital_spec.rb`

**Completion criteria**: All vitals can analyze code and unit tests pass

### Phase 3: Orchestration & Scoring (2 hours)

1. Create `lib/vitals/orchestrator.rb`
   - Initialize with config and selected vitals
   - Run vitals in parallel where possible
   - Collect all VitalResult objects
2. Update `lib/vitals/health_report.rb`
   - Calculate weighted overall score
   - Determine health status
3. Create tests

**Completion criteria**: Orchestrator can run all vitals and aggregate results

### Phase 4: CLI Interface (2 hours)

1. Create `lib/vitals/cli.rb` using Thor
2. Implement commands:
   - `vitals check [PATH]`
   - `vitals check complexity [PATH]`
   - `vitals check smells [PATH]`
   - `vitals check coverage [PATH]`
   - `vitals report [PATH]`
3. Add options for format, thresholds, config path
4. Set proper exit codes (0=pass, 1=fail, 2=error)
5. Create `bin/vitals` executable

**Completion criteria**: All CLI commands work and parse correctly

### Phase 5: Reporters (4 hours)

#### 5.1 CLI Reporter
- Create `lib/vitals/reporters/cli_reporter.rb`
- Use tty-box, pastel for colored output
- Format overall health report with borders

#### 5.2 JSON Reporter
- Create `lib/vitals/reporters/json_reporter.rb`
- Convert HealthReport to pretty JSON

#### 5.3 HTML Reporter
- Create `lib/vitals/reporters/html_reporter.rb`
- Generate HTML dashboard
- Output to `tmp/vitals/report.html`

**Completion criteria**: All three output formats work correctly

### Phase 6: Configuration Support (1 hour)

1. Update `lib/vitals/config.rb`
   - Look for `.vitals.yml` in project root
   - Parse YAML configuration
   - Merge with defaults
   - Allow CLI options to override
2. Update tests

**Completion criteria**: Config file loads and overrides work

### Phase 7: Integration Testing (3 hours)

1. Create `spec/fixtures/sample_rails_app/` with known issues
2. Create `spec/integration/full_check_spec.rb`
3. Test scenarios:
   - Full check on sample app
   - Individual vitals
   - Different output formats
   - Custom thresholds
   - Exit codes

**Completion criteria**: All integration tests passing

### Phase 8: Documentation & Polish (2 hours)

1. Create `README.md` with:
   - Installation instructions
   - Quick start guide
   - Usage examples
   - Configuration options
2. Add Thor command descriptions for help output
3. Create CI/CD integration examples (GitHub Actions, etc.)

**Completion criteria**: Complete documentation

---

## Exit Codes for CI/CD

- `0` - All vitals healthy
- `1` - One or more vitals below threshold
- `2` - Critical failure (can't analyze code)

---

## Success Criteria

Before marking implementation complete:

1. ✅ All unit tests passing
2. ✅ All integration tests passing
3. ✅ Code coverage ≥90%
4. ✅ CLI runs on sample Rails app successfully
5. ✅ All three output formats work (CLI, JSON, HTML)
6. ✅ Exit codes work correctly
7. ✅ Configuration file support works
8. ✅ Documentation complete
9. ✅ Can install as gem locally (`gem build` and `gem install`)
10. ✅ Execution time <30 seconds on sample app

---

## Timeline Estimate

- **Phase 1**: 2 hours (setup & foundation)
- **Phase 2**: 6 hours (implement vitals)
- **Phase 3**: 2 hours (orchestration)
- **Phase 4**: 2 hours (CLI interface)
- **Phase 5**: 4 hours (reporters)
- **Phase 6**: 1 hour (configuration)
- **Phase 7**: 3 hours (integration tests)
- **Phase 8**: 2 hours (documentation)

**Total**: ~22 hours of development time

---

## Future Enhancements

After v1.0, consider:
1. **Security Vital**: Integrate Brakeman
2. **Performance Vital**: Integrate Bullet (N+1 detection)
3. **Dependencies Vital**: Bundle audit for vulnerable gems
4. **Documentation Vital**: YARD coverage
5. **Churn Vital**: Git history analysis for high-change files
6. **Web Dashboard**: Standalone web app for team visibility
7. **Trend Analysis**: Track scores over time
8. **GitHub App**: Automated PR comments with vitals report