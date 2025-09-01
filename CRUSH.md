# CRUSH.md - Coding Guidelines and Commands for Baukasten Kirby CMS

## Build/Run Commands
- Start development server: Use DDEV with `ddev start` or similar local development environment
- Build assets: Check package.json in relevant plugin directories (some plugins use kirbyup)

## Test Commands
- Run all tests: `vendor/bin/phpunit` (runs all tests in site/plugins/*/tests directories)
- Run single test file: `vendor/bin/phpunit path/to/test/file.php`
- Run specific test: `vendor/bin/phpunit --filter TestClassName`

## Lint/Format Commands
- PHP linting: Use PHPStan or Psalm for static analysis (not yet configured)
- YAML linting: `vendor/bin/yaml-lint`
- General code style: Follow PSR-12 coding standards

## Code Style Guidelines

### PHP
- Follow PSR-12 coding standards
- Use camelCase for variables and functions
- Use PascalCase for classes and namespaces
- Use snake_case for file names
- Keep functions and methods small and focused
- Add PHPDoc comments for all public methods

### Imports and Namespaces
- Use explicit imports (don't use global namespace when possible)
- Group related functionality in namespaces
- Keep imports at the top of the file

### Types and Type Checking
- Use strict typing: declare(strict_types=1);
- Use type hints for function parameters and return types
- Prefer built-in PHP types over custom validation when possible

### Naming Conventions
- Variables: $camelCase
- Functions: camelCase()
- Classes: PascalCase
- Constants: UPPER_SNAKE_CASE
- Files: snake_case.php for templates, kebab-case for blueprints

### Error Handling
- Use Kirby's exception classes when appropriate
- Handle errors gracefully with try/catch blocks
- Log errors appropriately using Kirby's logging system
- Validate input parameters at the beginning of functions

### Kirby Specifics
- Use Kirby's data structures (pages, files, users) appropriately
- Follow established patterns in existing plugins
- Use Kirby's built-in helpers and utilities
- Implement blueprints for structured content
- Use Kirby's field methods for custom field functionality

### Plugin Architecture
- Follow the existing plugin structure in /site/plugins/
- Use composer.json for dependencies
- Implement proper autoloading
- Separate concerns (API, Helpers, Services)

## File Structure
- Content in /content/
- Plugins in /site/plugins/
- Templates in /site/templates/
- Blueprints in /site/blueprints/
- Assets in /assets/
- Public files in /public/

## Documentation Standards
- All documentation must be placed in the `docs/` folder
- Use clear, descriptive filenames
- Keep documentation up-to-date with code changes
- Include both technical and user-facing documentation

## Cursor Rules
The project includes specific Cursor rules in .cursor/rules/baukasten-kirby.mdc that define:
- Project structure and integration points
- Block creation standards for the Baukasten system
- Plugin functionality descriptions
- Development workflow guidelines
- Best practices for headless Kirby implementations

These rules should be referenced when working on any Kirby-related functionality.