# Test Quality Vital - Future Enhancement Idea

## Overview

A vital that analyzes test code quality to detect "test smells" and ensure tests validate desired behavior rather than just mirroring implementation.

## Motivation

Current vitals check production code quality (complexity, smells, coverage), but test code quality is equally important. Poor tests can:
- Give false confidence (tests pass but don't validate behavior)
- Be brittle (break when implementation changes, even if behavior is correct)
- Be hard to maintain (unclear what's being tested)
- Miss edge cases and boundary conditions

## Test Smells to Detect

### 1. **Dirty Mirror Tests**
Tests that just mirror the implementation rather than testing behavior.

```ruby
# ❌ Bad - mirrors implementation
it "calls run_reek and run_rubycritic" do
  expect(vital).to receive(:run_reek)
  expect(vital).to receive(:run_rubycritic)
  vital.check(path: path)
end

# ✅ Good - tests behavior
it "detects code smells in files with poor design" do
  result = vital.check(path: file_with_smells)
  expect(result.violations).to include(a_smell_of_type(:TooManyMethods))
end
```

### 2. **Over-Mocking**
Excessive use of mocks/stubs that test implementation details rather than behavior.

**Detection**: Count mock/stub calls vs actual assertions. Flag when mocks > assertions.

### 3. **Weak Assertions**
Vague or missing assertions that don't validate specific behavior.

```ruby
# ❌ Weak
expect(result).to be_truthy

# ✅ Specific
expect(result.score).to eq(100)
```

### 4. **Mystery Guest**
Tests that depend on external data or state not visible in the test.

**Detection**: Look for references to instance variables, class variables, or external files without setup.

### 5. **Assertion Roulette**
Many assertions without clear context - hard to know what failed.

**Detection**: Flag tests with >5 assertions without descriptive contexts.

### 6. **Long Tests**
Tests that are too long (>25 lines), indicating they test too much.

**Detection**: Count lines between `it` block start and end.

### 7. **Testing Private Methods**
Direct testing of private implementation details.

```ruby
# ❌ Bad
expect(vital.send(:calculate_average, data)).to eq(5)

# ✅ Good - test through public API
expect(vital.check(path).metadata[:average]).to eq(5)
```

### 8. **Missing Edge Cases**
No boundary condition testing.

**Detection**: Look for patterns like "when value is 0", "when empty", "when nil", etc.

## Potential Tools/Gems

### Available Now:
- **Parser gem** - Parse Ruby AST to analyze test structure
- **Mutant** - Mutation testing (commercial, checks if tests catch code changes)
- **test-prof** - Test performance profiling
- **RSpec metadata** - Can track test patterns

### Custom Analysis Needed:
Most test smell detection would require custom AST analysis since no comprehensive gem exists.

## Scoring Approach

```ruby
score = 100 - (smell_density * penalty_weight)

# Smell density = total_weighted_smells / total_tests
# Severity weights: error=3, warning=2, info=1
```

## Metrics to Report

```yaml
metadata:
  total_test_files: 45
  total_tests: 234
  total_smells: 12
  smell_distribution:
    over_mocking: 5
    long_test: 4
    assertion_roulette: 3
  average_test_length: 8.5 lines
  mock_to_assertion_ratio: 0.3
```

## Example Output

```
Test Quality Vital: 🟡 NEEDS IMPROVEMENT
├─ Score: 78/100
├─ Total tests analyzed: 234
├─ Test smells detected: 12
└─ Top issues:
   • spec/vitals/complexity_vital_spec.rb:45 - Over-mocking (5 mocks vs 2 assertions)
   • spec/vitals/smells_vital_spec.rb:12 - Long test (32 lines)
   • spec/cli_spec.rb:89 - Assertion roulette (8 assertions, consider splitting)
```

## Implementation Complexity

**Medium-High:**
- Requires Ruby AST parsing (Parser gem)
- Need to understand RSpec DSL structure
- Heuristics may have false positives
- Different testing frameworks (Minitest vs RSpec)

## Benefits

1. **Better test quality** - Catch ineffective tests before they cause problems
2. **Educational** - Teach developers test best practices
3. **Maintainability** - Easier to maintain behavioral tests
4. **Confidence** - Tests actually validate what they claim to test

## Future Considerations

- Integration with Mutant for mutation testing scores
- Support for Minitest in addition to RSpec
- Machine learning to detect anti-patterns
- Track test quality trends over time
- Suggest specific refactoring for each smell type

## References

- Martin Fowler's Test Smells: https://martinfowler.com/bliki/TestSmell.html
- xUnit Test Patterns by Gerard Meszaros
- RSpec Best Practices: https://rspec.info/
- Thoughtbot's Testing Rails: https://thoughtbot.com/testing-rails