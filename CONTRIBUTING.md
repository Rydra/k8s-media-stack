# Contributing to Media Stack Charts

This guide walks you through adding new services, maintaining existing charts, and preparing changes for deployment.

## Table of Contents
- [Adding a New Service](#adding-a-new-service)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Linting & Validation](#linting--validation)
- [Testing](#testing)
- [Documentation](#documentation)

## Adding a New Service

### Step 1: Decide Chart Type

Before creating any files, determine which pattern to use:

**Use basechart + values file** if:
- Service is a single container
- No companion databases or sidecars
- Can be deployed standalone with one helm release

**Examples**: komga, jellyfin, radarr, sonarr, paperless-ngx

→ Go to [Step 2A](#step-2a-using-basechart)

**Use custom chart** if:
- Service requires multiple containers in same pod
- Requires companion sidecar or database deployment
- Needs specialized routing/ingress configuration
- Has multiple templates with different configurations

**Examples**: gamevault (with postgres DB), romm (with mariadb), immich (complex setup)

→ Go to [Step 2B](#step-2b-creating-custom-chart)

### Step 2A: Using basechart

#### 1. Create values file
Create `charts/value-files/values-{service-name}.yaml`:

```yaml
service:
  name: {service-name}
  image: "{registry}/{image}:latest"
  replicas: 1
  servicePort: 8080  # Adjust to service's actual port
  resources:
    requests:
      cpu: 200m       # Choose: Small (200m), Medium (500m), or Large (1000m)
      memory: 512Mi   # Choose: Small (512Mi), Medium (1Gi), or Large (2Gi)
    limits:
      cpu: 500m       # Choose: Small (500m), Medium (1000m), or Large (2000m)
      memory: 1Gi     # Choose: Small (1Gi), Medium (2Gi), or Large (4Gi)
  
  livenessProbe:
    # Leave empty if service doesn't support health checks
    # httpGet:
    #   path: /health
    #   port: 8080
    # initialDelaySeconds: 30
    # periodSeconds: 10
    # failureThreshold: 3
  
  readinessProbe:
    # Leave empty if service doesn't support health checks
  
  httpRoutePath: "/{service-name}"
  
  volumeMounts:
    - name: config
      mountPath: /config  # Adjust to service needs
      subPath: {service-name}
    - name: media
      mountPath: /data    # Adjust to service needs
      subPath: media
  
  env:
    # Service-specific environment variables
    # Example: SERVICE_PORT: "8080"

  envSecrets: []
    # If service needs secrets (passwords, API keys)
    # - name: DATABASE_PASSWORD
    #   secretName: {service-name}-secrets
    #   key: db-password

securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  # Or omit/set to null if image doesn't support non-root

hostnames: []  # For HTTPRoute pattern matching, usually empty for local setup

storage:
  configClaimName: config-pvc
  mediaClaimName: media-pvc

gatewayClassName: traefik
```

#### 2. Deploy with basechart
```bash
make deploy-base service={service-name}
```

Or manually:
```bash
helm upgrade --install {service-name} charts/basechart \
  -n media-stack \
  --create-namespace \
  --values charts/value-files/values-{service-name}.yaml
```

### Step 2B: Creating Custom Chart

#### 1. Create chart directory structure
```bash
mkdir -p charts/{service-name}/templates
touch charts/{service-name}/Chart.yaml
touch charts/{service-name}/values.yaml
touch charts/{service-name}/templates/deployment.yaml
touch charts/{service-name}/templates/service.yaml
```

#### 2. Create Chart.yaml
```yaml
apiVersion: v2
name: {service-name}
description: A Helm chart for {Service Description}
type: application
version: 0.1.0
appVersion: "1.0.0"
maintainers:
  - name: Your Name
    email: your.email@example.com
keywords:
  - {service-name}
  - media
home: https://github.com/yourusername/media-stack
sources:
  - https://github.com/{upstream-project}
```

#### 3. Create values.yaml
Follow the basechart pattern, but expand for your custom needs:

```yaml
service:
  name: {service-name}
  image: "{registry}/{image}:latest"
  replicas: 1
  servicePort: 8080
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
  livenessProbe: {}
  readinessProbe: {}
  volumeMounts: []
  env: {}
  envSecrets: []

securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000

# For services with companion databases
database:
  enabled: true
  name: {service-name}-db
  image: "postgres:15"  # or mysql:8, mariadb:11, etc.
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 500m
      memory: 1Gi
  env: {}
  envSecrets: []

storage:
  configClaimName: config-pvc
  mediaClaimName: media-pvc
```

#### 4. Create templates
Reference [basechart templates](charts/basechart/templates/) as a starting point. Use consistent naming, labels, and annotations.

#### 5. Test & deploy
```bash
helm template {service-name} charts/{service-name} \
  --values charts/{service-name}/values.yaml

helm upgrade --install {service-name} charts/{service-name} \
  -n media-stack \
  --create-namespace
```

---

## Pre-Deployment Checklist

Before committing or deploying any changes, verify:

### Chart Metadata
- [ ] Chart name in `Chart.yaml` matches directory name
- [ ] `version` field correctly incremented (follow semver)
- [ ] `appVersion` matches actual application version
- [ ] `description` is accurate and descriptive
- [ ] Metadata (maintainers, keywords) are populated

### Values & Configuration
- [ ] All required values have sensible defaults in `values.yaml`
- [ ] No commented-out resource limits (all requests/limits uncommented)
- [ ] Resource tier chosen (Small/Medium/Large per CHART_STANDARDS.md)
- [ ] Security context defined (uid 1000) or documented exception
- [ ] All volume names follow naming convention (config, media, db-storage)
- [ ] Environment variables documented with comments

### Templates
- [ ] All templates use consistent 2-space indentation
- [ ] Labels follow standard format: `app.kubernetes.io/name`, etc.
- [ ] Selector labels are immutable (use `label` not `labels` for pod selectors)
- [ ] No hardcoded service names (use `.Values.service.name`)
- [ ] Health checks filled in or explicitly documented as unavailable
- [ ] All references use `{{ .Release.Namespace }}`

### Security
- [ ] Security context configured or exception documented
- [ ] No secrets in ConfigMaps (use Secret resources)
- [ ] Image pulls from trusted registry
- [ ] No hardcoded credentials in templates

### Documentation
- [ ] `Chart.yaml` description is accurate
- [ ] Complex values documented with inline comments
- [ ] If custom chart: `charts/{service}/README.md` created with usage examples
- [ ] Special configurations (probes, mounts, routes) explained

---

## Linting & Validation

### Run Helm Lint
```bash
# Lint a single chart
helm lint charts/{service-name}

# Lint all charts
helm lint charts/*/
```

**Expected output**: No errors or warnings (or only acknowledged warnings documented in the chart)

### Validate Templates
Generate template output to check for errors:

```bash
# Render a single chart
helm template {service-name} charts/{service-name}

# Render with custom values
helm template {service-name} charts/{service-name} \
  --values charts/value-files/values-{service-name}.yaml
```

**Expected output**: Valid Kubernetes YAML (no template errors)

### Run Makefile Validation (once Phase 5 complete)
```bash
make lint-charts
make validate-all
```

---

## Testing

### Local Deployment Test
1. **Dry-run**:
   ```bash
   helm upgrade --install {service} charts/{service} \
     -n media-stack \
     --dry-run \
     --debug
   ```
   
   ✓ Check output for any template errors
   ✓ Verify resource definitions are valid YAML

2. **Actual deployment** (in test namespace):
   ```bash
   helm upgrade --install {service} charts/{service} \
     -n media-stack-test \
     --create-namespace
   ```
   
   ✓ Wait for pod to become Ready
   ✓ Check pod logs: `kubectl logs -n media-stack-test deployment/{service}`
   ✓ Verify service is accessible: `kubectl port-forward -n media-stack-test svc/{service} 8000:PORT`

3. **Clean up test**:
   ```bash
   helm uninstall {service} -n media-stack-test
   kubectl delete namespace media-stack-test
   ```

### Health Check Testing
If adding health checks:
```bash
# Port-forward to service
kubectl port-forward -n media-stack svc/{service} 8000:SERVICE_PORT

# Test probe endpoint
curl http://localhost:8000/health
```

---

## Documentation

### Chart-Level README
For custom charts, create `charts/{service}/README.md`:

```markdown
# {Service Name} Chart

## Overview
Brief description of what this chart deploys.

## Configuration
- Explain any non-obvious configuration options
- Document resource defaults and when to adjust
- List required secrets (if any)

## Examples
Show example values files or deployment commands.

## Troubleshooting
Common issues and solutions specific to this service.
```

### Project README Updates
If adding a new major service to `media-stack`:
1. Update root `README.md` to list the new service
2. Add entry to deployment guide section

### Comments in values.yaml
Always include brief comments explaining:
- Non-obvious configuration options
- Resource choices (why this tier?)
- Required vs. optional values
- Any hardcoded assumptions

Example:
```yaml
resources:
  requests:
    cpu: 500m      # Medium tier: suitable for general media services
    memory: 1Gi    # Increase to 2Gi if experiencing memory pressure
```

---

## Making Changes to Existing Charts

### Version Bumping

When modifying an existing chart:

1. **Patch bump** (0.1.x → 0.1.y): Bug fixes, template formatting, non-breaking config changes
2. **Minor bump** (0.x.y → 0.(x+1).0): New features, new optional config options
3. **Major bump** (0.x.y → 1.0.0): Only when chart is production-ready (complete, tested, documented)

Update `Chart.yaml`:
```yaml
version: 0.2.0  # Bumped from 0.1.0
appVersion: "1.2.3"  # If upgrading to new app version
```

### Backwards Compatibility
- **Keep existing `values.yaml` keys unchanged** wherever possible
- If removing a config option, give 1-2 versions notice in comments
- Document breaking changes prominently in comments

---

## Common Tasks

### View deployment status
```bash
kubectl get pods -n media-stack
kubectl describe pod {pod-name} -n media-stack
kubectl logs {pod-name} -n media-stack -f
```

### Update service helm release
```bash
helm upgrade {service} charts/{service} \
  -n media-stack \
  --values charts/value-files/values-{service}.yaml
```

### Rollback to previous version
```bash
helm history {service} -n media-stack
helm rollback {service} {REVISION} -n media-stack
```

### Uninstall service
```bash
helm uninstall {service} -n media-stack
```

---

## Questions?

Refer to:
- **CHART_STANDARDS.md** — Quality and style guidelines
- **docs/TROUBLESHOOTING.md** — Common issues
- Existing charts in `charts/*/` — Best practices by example
