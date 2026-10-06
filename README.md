# Autonomous Project Template 🤖⚡

[![Template Status](https://img.shields.io/badge/GitHub-Template%20Repository-blue.svg)](https://github.com/vibe-maribit/autonomous-project-template)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![OpenCode Version](https://img.shields.io/badge/OpenCode-2.x-purple.svg)](https://opencode.ai)
[![CI Compatibility](https://img.shields.io/badge/CI-GitHub%20%7C%20Gitea%20%7C%20GitLab-orange.svg)](#cross-platform-support)

A universal, cross-platform starter template designed for **autonomous, AI-driven software development** powered by [OpenCode](https://opencode.ai).

When issues or feature requests are opened, OpenCode autonomously analyzes requirements (including screenshots/mockups), crafts an implementation plan, develops code with test coverage, performs an automated code review, creates pull requests, and merges them.

---

## 🌟 Key Features

- **Multi-Platform CI Orchestration**: Native workflows for:
  - **GitHub Actions** (`.github/workflows/opencode.yml`)
  - **Gitea / Forgejo Actions** (`.gitea/workflows/opencode.yaml`)
  - **GitLab CI** (`.gitlab-ci.yml`)
- **4-Stage Autonomous Pipeline**:
  1. 👁️ **Visual Inspection**: Detects images in issues/comments and processes UI mockups using visual models (`space-bunny-free` fallback).
  2. 📝 **Deterministic Planning**: Read-only planner agent writes a detailed plan (`.opencode/plan.md`) and commits it.
  3. 💻 **Implementation**: Coding agent builds the solution following the plan and executes automated tests.
  4. 🧐 **Independent Code Review**: Read-only reviewer agent (`.opencode/agents/reviewer.md`) validates security, test coverage, and code hygiene before merge.
- **Configurable Models & Privacy Fallback**:
  - Per-run model override via `inputs.model` / `OPENCODE_MODEL`.
  - Default fallback: `opencode/big-pickle` (or custom provider).
  - Visual fallback: `space-bunny-free` (conditional on image detection).
  - Optional `OPENCODE_API_KEY` for paid, privacy-compliant subscriptions (falls back seamlessly to free tiers when omitted).
- **Graceful Timeout Checkpoint (360 min)**:
  - Workflow max timeout configured to 360 minutes (6 hours).
  - Safety checkpointing pushes work-in-progress code and comments on the issue if a timeout or cancellation is imminent.
- **Full Best-Practice Compliance**:
  - `LICENSE` (MIT)
  - `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1)
  - `CONTRIBUTING.md`
  - `SECURITY.md`
  - GitHub Issue Templates (Bug Report & Feature Request YAMLs)
  - Pull Request Template
  - Standard Labels configuration (`scripts/setup-labels.sh`)

---

## 🚀 How to Use This Template

### 1. Create a Repository from this Template
Click the green **"Use this template"** button on GitHub, or clone this repository:
```bash
gh repo create my-awesome-project --template vibe-maribit/autonomous-project-template
```

### 2. Configure Secrets (Optional)
If you require paid model access or private API subscriptions, configure your repository secrets:
- `OPENCODE_API_KEY`: *(Optional)* Your OpenCode subscription key for privacy-compliant paid models.
- `GH_PAT` / `GITHUB_TOKEN`: Standard repository token with read/write permissions for issues and pull requests.

### 3. Setup Standard Labels
Run the helper script to create the necessary status and workflow labels:
```bash
./scripts/setup-labels.sh owner/my-awesome-project
```

### 4. Trigger Autonomous Development
- **Via Issue Label**: Apply the `autonomous` label to any issue.
- **Via Comment**: Comment `/oc please implement this feature` on any issue.
- **Via Manual Dispatch**: Run the workflow manually from the Actions tab with optional model overrides.

---

## 🏗️ Architecture

```
autonomous-project-template/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   ├── feature_request.yml
│   │   └── config.yml
│   ├── workflows/
│   │   └── opencode.yml        # GitHub Actions orchestrator
│   ├── labels.yml              # Standard label schema
│   └── pull_request_template.md
├── .gitea/
│   └── workflows/
│       └── opencode.yaml       # Gitea / Forgejo Actions
├── .gitlab-ci.yml              # GitLab CI pipeline
├── .opencode/
│   ├── agents/
│   │   ├── planner.md          # Read-only planning agent
│   │   └── reviewer.md         # Read-only code reviewer agent
│   └── ci/
│       └── runner.sh           # Portable pipeline execution script
├── scripts/
│   └── setup-labels.sh         # Label bootstrap script
├── src/                        # Your application source code
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── LICENSE
├── SECURITY.md
└── README.md
```

---

## 🔒 Security & Privacy

For private projects, set the `OPENCODE_API_KEY` repository secret. When provided, OpenCode routes requests through paid, zero-data-retention endpoints. When omitted, it safely falls back to standard community endpoints.

For reporting security vulnerabilities in this template, see [SECURITY.md](SECURITY.md).

---

## 📄 License

This template is licensed under the [MIT License](LICENSE).
