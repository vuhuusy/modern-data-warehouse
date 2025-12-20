# Copilot Instructions - Modern Data Warehouse

## Project Overview

This is a **modern data warehouse project** for grocery sales analytics using:
- **dbt** (dbt-core + dbt-athena) for data transformations
- **Terraform** for AWS infrastructure provisioning
- **PostgreSQL-compatible** database schemas (targeting AWS Athena/Redshift)

## Architecture

```
Source Data (CSV) → S3 → Athena/Redshift → dbt Transformations → Analytics
```

**Key directories:**
- `infra/modules/` - Terraform modules for AWS resources (S3, Athena, Redshift, IAM)
- `scripts/database/` - SQL DDL scripts for schema management
- `docs/images/` - Architecture diagrams (`architecture/`) and ERD (`database/`)
- `.github/dataset-instructions.md` - Authoritative data dictionary (7 tables, grocery sales domain)

## Data Model

The schema follows a **star schema pattern** with `sales` as the fact table:
- **Fact**: `sales` (transaction grain)
- **Dimensions**: `customers`, `employees`, `products`, `categories`, `cities`, `countries`

Reference [.github/dataset-instructions.md](.github/dataset-instructions.md) for complete schema definitions, relationships, and data characteristics.

## Developer Workflows
This section outlines how GitHub Copilot should assist developers in managing code changes, commits, and pull requests for this project.
## Commit and Pull Request

This section defines how GitHub Copilot should assist developers in creating commits and pull requests.

### Commit

When summarizing code changes:
- Analyze staged files and identify the primary intent of the change.
- Group related changes logically.
- Generate a conventional commit message.

Commit message format:
```
<type>(<scope>): <short description>
```

Commit types:
- `feat`: New feature or functionality
- `fix`: Bug fix
- `refactor`: Code restructuring without behavior change
- `docs`: Documentation changes
- `chore`: Maintenance tasks (dependencies, configs)
- `test`: Adding or updating tests

Guidelines:
- Use imperative mood (e.g., "add", "fix", "update").
- Keep the subject line under 72 characters.
- Scope is optional but recommended (e.g., `feat(schema):`).
- Do not end the subject line with a period.

### Pull Request

When generating a PR:
- Title: Use the same format as commit messages, summarizing the overall change.
- Description: Use Markdown with clear sections.

Required sections in PR description:
- **What changed**: List of changes in bullet points.
- **Why the change is needed**: Brief justification.
- **Breaking changes**: Explicitly state `None` if there are no breaking changes.

### PR Description Template

Use this exact template:

```markdown
## Summary

Brief one-line summary of the PR.

---

### What Changed

- Change 1
- Change 2
- Change 3

---

### Why This Change Is Needed

Explain the motivation or context.

---

### Breaking Changes

None.

---

### Checklist

- [ ] Code reviewed
- [ ] Documentation updated (if applicable)
- [ ] Tests passing (if applicable)
```

### Submission

Steps to push and create a PR:

1. Stage and commit changes:
   ```bash
   git add .
   git commit -m "<type>(<scope>): <description>"
   ```

2. Push the feature branch:
   ```bash
   git push origin <branch-name>
   ```

3. Create a PR using GitHub CLI:
   ```bash
   gh pr create --base main --head <branch-name> --title "<PR title>" --body "<PR description>"
   ```

   Or interactively:
   ```bash
   gh pr create --base main --head <branch-name>
   ```

Notes:
- Copilot generates the commit message, PR title, and PR description.
- The developer reviews, adjusts if needed, and submits the PR.
- Always verify the target branch (`--base`) before submission.
