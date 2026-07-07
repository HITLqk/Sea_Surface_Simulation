# GitHub CLI status

## Check result

GitHub CLI (`gh`) is not currently available in the active PowerShell environment.

Commands checked:

```powershell
gh --version
gh auth status
```

Both commands returned:

```text
The term 'gh' is not recognized as a name of a cmdlet, function, script file, or executable program.
```

## Current GitHub workflow impact

This does not block normal Git operations such as `git push`, because the repository was already pushed successfully using Git HTTPS credentials.

However, `gh`-dependent workflows are not available until GitHub CLI is installed and authenticated, including:

- checking GitHub authentication with `gh auth status`
- creating pull requests with `gh pr create`
- inspecting GitHub Actions checks with `gh run` or `gh pr checks`
- using GitHub CLI as a fallback for PR and CI workflows

## Suggested fix

Install GitHub CLI for Windows and then authenticate:

```powershell
winget install --id GitHub.cli
gh auth login
```

After installation, restart PowerShell or Codex so the updated PATH is visible.

