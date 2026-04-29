# SIREN

## 폴더구조

```shell
siren/
  ├── app/                 ← Flutter (MVP, 현장 태블릿)
  │     ├── pubspec.yaml
  │     └── .gitignore
  ├── dashboard/           ← Next.js (Phase 2, 대시보드)
  │     ├── package.json
  │     └── .gitignore
  ├── api/                 ← FastAPI
  │     ├── requirements.txt
  │     └── .gitignore
  ├── vision/              ← YOLOv8
  │     ├── requirements.txt
  │     ├── configs/
  │     └── .gitignore
  ├── docker-compose.yml
  ├── .github/
  │     ├── ISSUE_TEMPLATE/
  │     │     ├── feature.md
  │     │     ├── bug.md
  │     │     └── experiment.md
  │     ├── PULL_REQUEST_TEMPLATE.md
  │     └── workflows/
  │           ├── ci-app.yml
  │           ├── ci-dashboard.yml
  │           ├── ci-api.yml
  │           └── ci-vision.yml
  ├── CONTRIBUTING.md
  ├── CLAUDE.md
  └── README.md
```

- dashboard MVP에서 벗어나므로 아직 생성 X
