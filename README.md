# jcollins-cloud

My personal website — a small Flask app with a home page and an about page,
containerized and hosted on AWS.

## Architecture

```
                    ┌────────────────────┐
   Browser ───────► │     CloudFront      │
      │             └─────────┬──────────┘
      │                       │ /static/*
      │                       ▼
      │             ┌────────────────────┐
      │             │   S3 (static assets)│
      │             └────────────────────┘
      │
      └──────────► App Runner (containerized Flask app, pulled from ECR)
```

- **App**: Flask, served by gunicorn, containerized.
- **Static assets** (images, CSS, resume PDF): S3, fronted by CloudFront on
  their own subdomain. The app never proxies these files itself — see
  `static_url()` in `src/main.py`.
- **Compute**: AWS App Runner, running the image built from the `Dockerfile`.
- **Infrastructure**: Terraform, in [`.platform/terraform/`](.platform/terraform/).
- **CI/CD**: GitHub Actions ([`.github/workflows/deploy.yaml`](.github/workflows/deploy.yaml))
  builds the image, pushes to ECR, deploys to App Runner, and syncs static
  assets to S3 on every push to `main`. Auth is via GitHub OIDC — no static
  AWS credentials are stored in this repo.

This is a migration in progress from a previous GCP App Engine deployment.
`app.yaml` and `.gcloudignore` are the last remnants of that and will be
removed once the AWS hosting is fully cut over.

## Repo layout

```
src/                    Flask app (main.py, templates/, static_local/)
Dockerfile              Multi-stage build (uv for deps, gunicorn for serving)
pyproject.toml, uv.lock Python dependencies, managed with uv
.platform/terraform/    Infrastructure as code (S3, CloudFront, ECR, App Runner, IAM/OIDC)
.github/workflows/      CI/CD pipeline
```

## Local development

Requires [uv](https://docs.astral.sh/uv/).

```bash
uv sync
uv run python src/main.py
```

This runs the Flask dev server on `http://localhost:5000`. Static assets are
served straight out of `src/static_local/` (no `STATIC_BASE_URL` needed
locally — see `static_url()` in `src/main.py` for the fallback logic).

### Running the production container locally

```bash
docker build -t jcollins-cloud .
docker run --rm -p 8080:8080 jcollins-cloud
```

Then visit `http://localhost:8080`.

## Deploying infrastructure

See [`.platform/terraform/`](.platform/terraform/) — copy
`terraform.tfvars.example` to `terraform.tfvars`, adjust as needed, then the
usual `terraform init` / `plan` / `apply`. `terraform output` afterward gives
you the values to populate as GitHub Actions repository variables
(`AWS_DEPLOY_ROLE_ARN`, `ECR_REPOSITORY`, `APPRUNNER_SERVICE_ARN`,
`STATIC_BUCKET_NAME`, `CLOUDFRONT_DISTRIBUTION_ID`) so the pipeline can
deploy.
