# Vitals

**Vitals** is a CLI tool that checks the critical health indicators of your Rails codebase, similar to how a doctor checks vital signs (heart rate, blood pressure, temperature).

It provides automated, research-backed assessment of Rails codebase maintainability through three key metrics:

1. **Complexity** - How difficult is the code to understand and modify?
2. **Smells** - Does the code exhibit poor structural patterns?
3. **Coverage** - Is the code adequately tested?

## Installation

Install the gem locally by executing:

```bash
bundle install
```

## Usage

### Running Vitals

Run all vitals checks on your codebase:

```bash
./bin/vitals check [PATH]
```

Run specific vital checks:

```bash
./bin/vitals complexity [PATH]    # Check code complexity
./bin/vitals smells [PATH]        # Check code smells
./bin/vitals coverage [PATH]      # Check test coverage
```

Generate a full health report:

```bash
./bin/vitals report [PATH]
```

### Options

**Global Options:**
- `-c, --config=CONFIG` - Path to configuration file
- `--format=FORMAT` - Output format (cli, json, html) [default: cli]

**Threshold Overrides:**
- `--complexity-threshold=N` - Override complexity threshold (default: 10)
- `--smells-threshold=N` - Override smells threshold (default: 80)
- `--coverage-threshold=N` - Override coverage threshold (default: 80)

### Examples

```bash
# Run all checks with default settings
./bin/vitals check

# Run checks on specific directory
./bin/vitals check ./app

# Run with custom thresholds
./bin/vitals check --complexity-threshold=15 --coverage-threshold=90

# Output as JSON for CI/CD
./bin/vitals check --format=json

# Use custom config file
./bin/vitals check --config=.vitals.custom.yml
```

### Configuration

Create a `.vitals.yml` file in your project root to customize settings:

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

### Version

Check the installed version:

```bash
./bin/vitals version
```

### Help

View all available commands:

```bash
./bin/vitals help
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Running Tests

Run the test suite with RSpec:

```bash
bundle exec rspec
```

Or using the rake task:

```bash
rake spec
```

Run tests with coverage:

```bash
COVERAGE=true bundle exec rspec
```

### Development Console

You can run `bin/console` for an interactive prompt that will allow you to experiment:

```bash
./bin/console
```

### Local Installation

To install this gem onto your local machine:

```bash
bundle exec rake install
```

### Release Process

To release a new version:

1. Update the version number in `version.rb`
2. Run `bundle exec rake release`

This will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shayfrendt/vitals.
