# ITSD 85 Lab <no>: Automated CI/CD Pipeline

Student(s): Mark P. Importante | Section: BSIT 4Cx | Instructor: Rinante Buntod

## What this project does

A minimal Node.js (Express) web API with automated tests (`node:test`), linting (`eslint`), Docker packaging, and a GitHub Actions CI/CD pipeline that tests on a GitHub-hosted runner and deploys to a self-hosted Ubuntu Server VM via Docker Compose.

## Pipeline diagram

![CI/CD Pipeline](docs/pipeline.png)

## How to run locally

```bash
npm install
npm run lint
npm test
npm run dev
```

Open `http://localhost:3000` and `http://localhost:3000/health`.

## How the deployment works

1. Every push or pull request to `main` triggers the `test` job on `ubuntu-latest` (`npm ci`, `npm run lint`, `npm test`).
2. Only pushes to `main` (after `test` passes) trigger the `deploy` job on the self-hosted runner (`[self-hosted, linux, deploy]`).
3. The runner builds and starts the container with `APP_VERSION=${{ github.sha }}` and verifies `http://localhost:8080/health` returns the new commit SHA.

## Results

| Test | Expected result | Actual result | Push-to-live time (min:sec) | Screenshot no. |
| --- | --- | --- | --- | --- |
| A – good change | test ✓, deploy ✓, new name and commit ID live | test ✓ (12s on PR), deploy ✓ (`MARK P. IMPORTANTE` & `7652c103...` live) | | `Screenshot 2026-11-22 124633.png`, `125103.png` |
| B – broken change | test ✗, merge blocked, server unchanged | test ✗ (1 failing check on `eb93b27`), merge blocked | n/a | `Screenshot 2026-11-22 125202.png` |
| C – rollback (Method 1) | old content and a new commit ID live | | | |
| C – rollback (Method 2) | previous commit ID live within seconds | | | |

## Screenshots

- [Manual Dry Run Build (Kali)](docs/screenshots/Screenshot%202026-11-22%20121339.png)
- [Checkpoint 5 – Manual Deploy Live](docs/screenshots/Screenshot%202026-11-22%20121628.png)
- [Runner Service Active (Kali)](docs/screenshots/Screenshot%202026-11-22%20122636.png)
- [Checkpoint 6a – Runner Labels & Idle](docs/screenshots/Screenshot%202026-11-22%20122807.png)
- [Test A – PR Checks Passed & Deploy Skipped](docs/screenshots/Screenshot%202026-11-22%20124633.png)
- [Test A – Personalized Portfolio Live](docs/screenshots/Screenshot%202026-11-22%20125103.png)
- [Test B – Broken Change Blocked](docs/screenshots/Screenshot%202026-11-22%20125202.png)

## Paper

- [Final Paper PDF](docs/paper.pdf)
