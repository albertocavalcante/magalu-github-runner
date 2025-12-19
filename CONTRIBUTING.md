# Contributing to Magalu GitHub Runner

First off, thanks for taking the time to contribute!

## Development Setup

To ensure quality and consistency, we use strict linting and formatting rules enforced by [Lefthook](https://github.com/evilmartians/lefthook).

### 1. Install Dependencies

You will need the following tools installed on your machine:

- **Terraform** / **OpenTofu**: Infrastructure provisioning.
- **Lefthook**: For managing Git hooks.
- **TFLint**: For advanced Terraform linting.
- **Terraform Docs**: For automatic documentation generation.

**MacOS (Homebrew):**
```bash
brew install terraform lefthook tflint terraform-docs
```

### 2. Install Git Hooks

We use Lefthook to manage pre-commit hooks. This is **required** for all contributors.
This ensures your code is formatted (`terraform fmt`), validated (`terraform validate`), and documented (`terraform-docs`) before you commit.

```bash
lefthook install
```

> **Note**: Git handles hooks locally. You must run this command once after cloning the repository. It is not automatic for security reasons.

## Workflow

1.  Create a new branch for your feature or fix.
2.  Make your changes.
3.  **Commit**: Lefthook will automatically run checks.
    - If a check fails (e.g., auto-formatting), fix the issue or stage the formatted files and commit again.
4.  Push to `main` (or open a PR).

## File Structure

- `main.tf`: Core resource logic.
- `variables.tf`: Input definitions.
- `examples/`: usage examples.
- `templates/`: scripts (e.g., `startup.sh`).
