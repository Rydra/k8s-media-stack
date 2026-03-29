# Helm Chart Standards & Guidelines

This document defines quality and consistency standards for all Helm charts in the media-stack project.

## Versioning

- **Version scheme**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Initial version**: Start all new charts at `0.1.0` (development mode)
- **Progression**: Charts move to `1.0.0` only when production-ready and documented
- **appVersion**: Tracks the application version (e.g., `jellyfin: 10.9.x`), not chart version
- **Chart.yaml**: Always include both `version` and `appVersion`

Example:
```yaml
apiVersion: v2
name: example-service
version: 0.1.0
appVersion: "1.2.3"
```

## Naming Conventions

### Chart Names & Files
- Use **kebab-case** for all chart names and directories
- Chart name in `Chart.yaml` must match directory name
- Example: `jellyfin`, `gamevault`, `paperless-ngx` ✓

### Labels & Selectors
- **Immutable selector labels** required on all Deployments/StatefulSets
- Standard label format:
  ```yaml
  labels:
    app.kubernetes.io/name: {{ .Values.service.name }}
    app.kubernetes.io/version: {{ chart.appVersion }}
    app.kubernetes.io/component: {{ component }}
    app.kubernetes.io/part-of: media-stack
  ```
- Use consistent indentation (2 spaces)

### Environment Variables
- Use **SCREAMING_SNAKE_CASE** for all environment variables
- Prefix service-specific vars with service name when helpful (e.g., `PAPERLESS_REDIS`)
- Document required vs. optional environment variables in values comments

### Resources & Volumes
- Volume names: Use descriptive **kebab-case** names:
  - `config` — configuration data
  - `media` — media library data
  - `db-storage` — database persistence
  - `cache` — temporary cache data
- PersistentVolumeClaim names: Match volume names (e.g., `config-pvc`, `media-pvc`)

## Resource Management

### Tier-Based Defaults

Three resource tiers are defined (requests & limits):

| Tier | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------|-------------|-----------|-----------------|--------------|
| **Small** | 200m | 500m | 512Mi | 1Gi |
| **Medium** | 500m | 1000m | 1Gi | 2Gi |
| **Large** | 1000m | 2000m | 2Gi | 4Gi |

**Assignment guidelines**:
- **Small**: Stateless services with minimal compute (komga, jellyfin frontend, flaresolverr)
- **Medium**: General services with moderate load (radarr, sonarr, paperless)
- **Large**: Processing-heavy or stateful services (gamevault backend, immich, media processing)

**Usage**:
```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi
```

### Requirements
- **MUST**: All services must define both `requests` and `limits`
- **MUST**: No commented-out resource limits
- **OPTIONAL**: Override defaults per-service if justified (document the reason)
- Services without defined tiers: use Small tier as baseline
- **Test locally**: All resource values should be tested in your K3S environment before merging

## Chart Structure

### Application Charts (Single Service)

Use the **basechart** pattern for single-service deployments.

```
charts/basechart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── env.yaml (ConfigMap)
    └── httproute.yaml
```

**When to use**: Services like komga, jellyfin, radarr (no companion services)

### Custom Charts (Complex Services)

Create a custom chart for services with multiple components (sidecars, companion DBs, special routing).

```
charts/gamevault/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── deployment-db.yaml
    ├── service.yaml
    ├── service-db.yaml
    ├── env.yaml
    ├── env-db.yaml
    └── httproute.yaml
```

**When to use**: Services like gamevault, romm, immich (with databases, multiple containers, special configs)

**Decision helper**:
- Single container? → basechart
- Multiple containers in same pod? → custom chart
- Requires separate sidecar deployment? → custom chart
- Has companion database pod? → custom chart

## Health Checks (Liveness & Readiness Probes)

### Guidelines
- Health checks are **optional** but **recommended** where the service explicitly supports them
- Only add probes if the service has a health endpoint and responds reliably
- Services without HTTP health endpoints: leave probes empty or commented (document why)

### Probe Template
When adding health checks, follow this structure:

```yaml
livenessProbe:
  httpGet:
    path: /health  # or service-specific path
    port: 8000     # or service port
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 5

readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 2
  timeoutSeconds: 3
```

### Per-Service Notes
- **komga**: Supports `/komga/actuator/health` ✓
- **jellyfin**: HTTP health endpoint available ✓
- **paperless-ngx**: No standard health endpoint (leave empty, document)
- **Database services**: Use TCP probes or leave empty if HTTP not available
- Document probe status in `values.yaml` comments for clarity

### Anti-Pattern
❌ Empty probe blocks:
```yaml
livenessProbe:
readinessProbe:
```

✓ Documented absence:
```yaml
# Health checks not configured: service does not expose HTTP health endpoint
# Consider polling http://service-name:port/health once available
livenessProbe: null
readinessProbe: null
```

## Security Context

### Default Standard
All services should define security context unless the Docker image is not prepared for non-root:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
```

### Exceptions
If a service's container image **cannot run as non-root** (e.g., requires root capabilities):
1. Document the exception in `values.yaml` comments
2. Include service name in [exception list at bottom of this document](#security-exceptions)
3. Security context can be omitted or set to `null`

### Pod-Level Context
Consider adding pod-level restrictions where appropriate:
```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
  fsGroupChangePolicy: OnRootMismatch
```

## Templates

### Required Elements
All templates must include:
1. **Metadata labels**: `app.kubernetes.io/name`, `app.kubernetes.io/version`, `app.kubernetes.io/part-of`
2. **Annotations**: `managed-by: helm`
3. **Namespace**: All resources should respect `{{ .Release.Namespace }}`

### Template Syntax
- **Indentation**: Always 2 spaces (use `nindent` in Helm for nested YAML)
- **Comments**: Use `{{- /* comment */ -}}` for Helm template comments
- **Conditionals**: Use `-` in `{{ }}` to strip whitespace when needed
- **Example**:
  ```yaml
  metadata:
    name: {{ .Values.service.name }}
    labels:
      app.kubernetes.io/name: {{ .Values.service.name }}
      {{- if .Values.labels }}
      {{- toYaml .Values.labels | nindent 4 }}
      {{- end }}
  ```

### ConfigMaps & Secrets
- ConfigMaps for non-sensitive configuration (use `env.yaml`)
- Secrets for sensitive data (database passwords, API keys)
- Always use `envFrom` with `configMapRef` or `secretRef` when possible
- Only use `env` entries for template-generated values

## HTTPRoute & Ingress

### Gateway Routing
All services expose via **HTTPRoute** to Traefik Gateway:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .Values.service.name }}-http-route
spec:
  parentRefs:
    - name: traefik-gateway
      namespace: kube-system
  hostnames:
    {{- toYaml .Values.hostnames | nindent 4 }}
  rules:
    - matches:
      - path:
          type: PathPrefix
          value: {{ .Values.service.httpRoutePath }}
      backendRefs:
        - name: {{ .Values.service.name }}
          port: {{ .Values.service.servicePort }}
```

### Path Strategy
- Use **PathPrefix** matching for main service paths
- Document any custom routing in `values.yaml`
- Ensure paths don't conflict (e.g., `/jellyfin` vs `/jellyfin/api`)

## Documentation Requirements

### Per-Chart
Every chart should include inline documentation:

1. **Chart.yaml**: Accurate description and metadata
2. **values.yaml**: Comments explaining non-obvious configurations
3. **README.md** (at chart root): Usage instructions, example values, special considerations

### Project-Level
- **CONTRIBUTING.md**: How to add new services
- **docs/TROUBLESHOOTING.md**: Common issues and debugging

## Common Anti-Patterns

| ❌ Anti-Pattern | ✓ Correct Approach |
|----------------|-------------------|
| Hardcoded image tags: `image: "komga:latest"` | Use `values.yaml` with container registry control |
| Mixed naming: `media` + `media-storage` volumes | Consistent volume names across charts |
| Commented-out resources limits | Uncomment and set to appropriate tier |
| Empty probe blocks | Document why or remove entire block |
| No selector labels on Deployments | Always include immutable selectors |
| Secrets in ConfigMaps | Use Secret resources for sensitive data |
| Service-specific labels only | Use standard Kubernetes label format |

## Chart Maturity Model

### Development (Version 0.x)
- Feature-complete but not thoroughly tested in production
- May have incomplete probes or commented sections
- Documentation is work-in-progress

### Production (Version 1.0.0+)
- Fully tested and stable
- All health checks completed and validated
- Comprehensive documentation
- All resource limits defined and tuned
- Ready for long-term maintenance

## Security Exceptions

Services that cannot run with default security context (uid 1000):
- *None currently documented*

(Updates to be added as exceptions are discovered)

## Version History

- **v1.0** (2026-03-29): Initial standards document for media-stack Helm refactoring
