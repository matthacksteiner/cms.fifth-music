# CRUSH.md - Coding Guidelines and Commands for Baukasten Kirby CMS

## Build/Run Commands
- Start development server: `composer run dev` or use DDEV: `ddev start`
- Build assets: Check package.json in relevant plugin directories

## Test Commands
- Run all tests: `./vendor/bin/kirby test` (if available) or check individual plugin test directories
- Run single test file: `php [path/to/test/file.php]`
- Run specific test: Use phpunit with filter option if installed separately

## Lint/Format Commands
- PHP linting: `composer run lint` or `./vendor/bin/kirby lint`
- YAML linting: `./vendor/bin/yaml-lint`

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

Include the Cursor rules from .cursor/rules/baukasten-kirby.mdc as project-specific context for AI agents.