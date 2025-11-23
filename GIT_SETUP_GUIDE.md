# Git Setup & Upload Guide

## Current Status

Your project has been initialized as a Git repository at:
```
C:\projects\self\
```

Files ready to commit:
- `README.md` - Complete Technical Design Document with ADRs
- `.gitignore` - Java/Maven project gitignore

---

## Option 1: Upload to GitHub

### Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and log in
2. Click the **"+"** icon (top right) → **"New repository"**
3. Repository settings:
   - **Name**: `tax-filing-microservices`
   - **Description**: `Production-grade Tax Filing System - Spring Boot Microservices with Kafka, PostgreSQL, Redis`
   - **Visibility**: Choose Private or Public
   - **DO NOT** initialize with README (we already have one)
4. Click **"Create repository"**

### Step 2: Configure Git Locally

```bash
# Navigate to project directory
cd C:\projects\self

# Set your Git identity (if not already set globally)
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Add all files to staging
git add .

# Create initial commit
git commit -m "Initial commit: Technical Design Document with comprehensive ADRs

- Complete system architecture with Mermaid diagrams
- API contracts for Filing and Payment services
- Kafka event schemas with DLQ configuration
- PostgreSQL schemas for all 3 databases
- Architectural patterns: Saga, CQRS, Idempotency
- Cross-cutting concerns: JWT, Tracing, Caching
- Deployment architecture: Docker Compose + AWS ECS
- 11 comprehensive ADRs justifying technology choices"

# Add remote repository (replace <username> with your GitHub username)
git remote add origin https://github.com/<username>/tax-filing-microservices.git

# Push to GitHub
git push -u origin main
```

**Note:** If you get an error about `master` vs `main`:
```bash
# Rename branch to main
git branch -M main
git push -u origin main
```

### Step 3: Authenticate

**Option A: Personal Access Token (Recommended)**
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Select scopes: `repo` (full control of private repositories)
4. Copy the token
5. When pushing, use the token as your password

**Option B: GitHub CLI (Easiest)**
```bash
# Install GitHub CLI
winget install GitHub.cli

# Authenticate
gh auth login

# Push
git push -u origin main
```

---

## Option 2: Upload to GitLab

### Step 1: Create GitLab Project

1. Go to [GitLab](https://gitlab.com) and log in
2. Click **"New project"** → **"Create blank project"**
3. Project settings:
   - **Project name**: `tax-filing-microservices`
   - **Visibility Level**: Private or Public
   - **Initialize repository with a README**: Uncheck
4. Click **"Create project"**

### Step 2: Push to GitLab

```bash
cd C:\projects\self

# Add all files
git add .

# Commit
git commit -m "Initial commit: Technical Design Document with ADRs"

# Add GitLab remote (replace <username> with your GitLab username)
git remote add origin https://gitlab.com/<username>/tax-filing-microservices.git

# Push
git push -u origin main
```

---

## Option 3: Upload to Azure DevOps

### Step 1: Create Azure DevOps Repository

1. Go to [Azure DevOps](https://dev.azure.com)
2. Create a new project: `tax-filing-microservices`
3. Go to Repos → Files → Import repository OR create empty repo

### Step 2: Push to Azure DevOps

```bash
cd C:\projects\self

git add .
git commit -m "Initial commit: Technical Design Document"

# Add Azure DevOps remote
git remote add origin https://dev.azure.com/<organization>/<project>/_git/tax-filing-microservices

git push -u origin main
```

---

## Verify Upload

After pushing, verify on your Git platform:
- ✅ README.md displays as the project homepage with rendered Mermaid diagrams
- ✅ .gitignore is present
- ✅ Commit message is clear and descriptive

---

## Next Steps After Upload

### 1. Add Branch Protection (Recommended)

**GitHub:**
- Go to Settings → Branches → Add branch protection rule
- Branch name pattern: `main`
- Enable:
  - ✅ Require pull request reviews before merging
  - ✅ Require status checks to pass before merging
  - ✅ Require conversation resolution before merging

**GitLab:**
- Settings → Repository → Protected branches
- Protect `main` branch
- Allowed to merge: Maintainers
- Allowed to push: No one

### 2. Add Collaborators

**GitHub:** Settings → Collaborators → Add people

**GitLab:** Settings → Members → Invite members

### 3. Set Up Project Board (Optional)

**GitHub Projects:**
- Projects tab → New project → Board view
- Add columns: Backlog, Phase 1, Phase 2, Phase 3, In Review, Done

**GitLab Boards:**
- Issues → Boards → Create new board

---

## Future Git Workflow

### For Phase 2 (Infrastructure & Scaffolding)

```bash
# Create feature branch
git checkout -b phase-2-infrastructure

# Make changes (Maven POMs, Dockerfiles, etc.)
# ...

# Commit incrementally
git add pom.xml
git commit -m "Add Maven parent POM with dependency management"

git add api-gateway/
git commit -m "Add API Gateway service scaffold"

# Push feature branch
git push -u origin phase-2-infrastructure

# Create Pull Request on GitHub/GitLab for review
```

### For Phase 3 (Service Implementation)

```bash
# Create feature branch per service
git checkout -b feature/auth-service-implementation

# Implement Auth Service
# ...

# Commit with clear messages
git commit -m "Implement Auth Service: User registration and JWT generation

- Add UserController with POST /register and POST /login endpoints
- Implement JwtTokenProvider with RS256 signing
- Add BCrypt password hashing
- Configure Spring Security
- Add integration tests with Testcontainers"

# Push and create PR
git push -u origin feature/auth-service-implementation
```

---

## Recommended Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Examples:**

```
feat(filing-service): Add tax return submission endpoint

- Implement POST /api/v1/filings/{id}/submit
- Add state machine transition: DRAFT → SUBMITTED
- Publish TaxReturnFiledEvent to Kafka
- Add validation for required fields

Closes #123
```

```
fix(payment-service): Resolve duplicate payment processing

- Add idempotency check using event_id in processed_events table
- Prevent duplicate charges when Kafka consumer retries
- Add integration test for duplicate event handling

Fixes #456
```

```
docs(readme): Update deployment architecture section

- Add AWS ECS Fargate task definition example
- Include CloudWatch logging configuration
- Update Mermaid diagram with ALB
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Build/config changes
- `perf`: Performance improvements

---

## Troubleshooting

### Issue: "fatal: refusing to merge unrelated histories"

```bash
git pull origin main --allow-unrelated-histories
```

### Issue: Authentication failed

**For HTTPS:**
```bash
# Use Personal Access Token as password
# Or switch to SSH
```

**Switch to SSH:**
```bash
# Generate SSH key (if not already)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add public key to GitHub/GitLab
# Copy: cat ~/.ssh/id_ed25519.pub

# Change remote URL
git remote set-url origin git@github.com:<username>/tax-filing-microservices.git
```

### Issue: Large files rejected

```bash
# Remove from history
git rm --cached path/to/large/file
git commit --amend

# Or use Git LFS
git lfs install
git lfs track "*.jar"
```

---

## Recommended GitHub Repository Settings

### Topics (for discoverability)

Add these topics to your repository:
- `spring-boot`
- `microservices`
- `kafka`
- `postgresql`
- `redis`
- `docker`
- `aws-ecs`
- `tax-filing`
- `java-21`
- `event-driven`
- `saga-pattern`
- `cqrs`

### About Section

**Description:**
```
Production-grade Tax Filing Microservices System built with Spring Boot 3.2, Apache Kafka, PostgreSQL, and Redis. Features event-driven architecture, CQRS, Saga pattern, and comprehensive observability.
```

**Website:**
```
https://github.com/<username>/tax-filing-microservices
```

---

## CI/CD Setup (Phase 2)

In Phase 2, we'll add:
- `.github/workflows/ci.yml` (GitHub Actions)
- OR `.gitlab-ci.yml` (GitLab CI)

This will automate:
- ✅ Maven build and test
- ✅ Code quality checks (Spotless, Checkstyle)
- ✅ Docker image build and push to ECR
- ✅ Deploy to AWS ECS (staging/production)

---

## Summary

✅ Git repository initialized locally
✅ README.md with comprehensive ADRs ready
✅ .gitignore configured for Java/Maven projects
✅ Ready to push to GitHub/GitLab/Azure DevOps

**Choose your platform and follow the steps above to upload your project!**
