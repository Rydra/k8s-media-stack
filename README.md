## Preface

This project contains Kubernetes Helm charts for a complete **media stack homelab** with services like Jellyfin, Radarr, Sonarr, Komga, and more.

While optimized for **K3S** on a home server (because K3S integrates seamlessly with local storage via hostPath storage classes), this setup can be deployed anywhere Kubernetes runs — including cloud providers like AWS, DigitalOcean, or Linode by configuring appropriate storage classes and ingress controllers.

## Quick Start (15-20 minutes, depending on what services you deploy)

If you already have K3S running and want to get started immediately:

### 1. Configure Storage Paths

This project stores all data (configs, media, photos) on the host filesystem. Edit `charts/volumes/values.yaml` and update the paths to match your setup:

```yaml
storage:
  config: /mnt/storage/config       # Where service configs are stored
  media: /mnt/storage/media         # Where media library lives
  immich: /mnt/storage/immich       # Where Immich photos are stored
```

### 2. Setting Up Secrets

Before proceeding, Some services require credentials (API keys, database passwords, etc.). These are stored as Kubernetes Secrets and must be created before or after deploy.

If you are not going to deploy those services that require secrets you can skip this section and move to the next

#### Charts Requiring Secrets

The following charts have secret requirements — check their individual READMEs for details:

- **romm** - Requires IGDB and screenscraper API credentials
- **homepage** - Requires service authentication credentials

#### Creating Secrets

Use the safe stdin method (keeps secrets out of shell history):

```bash
make set-secrets name=service-secret-name
```

Then paste your secrets in `.env` format and press Ctrl+D:

```env
API_KEY=your-key-here
DATABASE_PASSWORD=your-password-here
```

For detailed steps on which secrets each service needs, refer to the individual chart READMEs in `charts/[service-name]/README.md`.

### 3. Bootstrap the Cluster

Run a single command to deploy the entire stack:

```bash
make bootstrap
```

This will:
- Copy Traefik configuration to expose the cluster on ports 80 and 443
- Deploy storage volumes and PVCs
- Deploy cert-manager for HTTPS certificates
- Deploy all media stack services

If you want finer control on what you deploy, you can start with this:

```bash
sudo cp traefik/values.yaml /var/lib/rancher/k3s/server/manifests/traefik-custom.yaml
make update-deps-all
make deploy-support
```

and then deploy the services you're interested in one by one with:

```bash
make deploy chart={the chart name}
```

Check the section [Available Services (Deployable Charts)](#available-services-deployable-charts) (or look at the source code)
to have a complete list of deployable charts.

### 4. Restart Traefik

```bash
sudo systemctl restart k3s
```

K3S needs a restart to apply the Traefik configuration changes.

### 5. Add Service Hostnames (Local Access)

Add these entries to your `/etc/hosts` file (`sudo nano /etc/hosts`):

```
127.0.0.1	qbit.local vault.local home.local immich.local sabnzbd.local romm.local gamevault.local gaseous.local retrom.local amule.local
```

## What Bootstrap Deploys

The `make bootstrap` command deploys:

**Infrastructure:**
- Volumes & Storage (PVCs for config, media, and immich)
- cert-manager (for HTTPS certificates)
- Shared resources

**Services:**
Some of the 20+ media stack services including Jellyfin, Radarr, Sonarr, Komga, Lidarr, Prowlarr, qBittorrent, Paperless-NGX, Vaultwarden, Immich, and more.

## Available Services (Deployable Charts)

All services can be deployed individually with `make deploy chart=<service-name>` or together with `make deploy-all`.

### Media Servers
- **jellyfin** - Open-source media server (movies, TV, music)
- **immich** - Self-hosted photo and video management
- **komga** - Manga and comic book server

### Content Discovery & Management
- **radarr** - Movie tracker and organizer
- **sonarr** - TV show tracker and organizer
- **lidarr** - Music tracker and organizer
- **readarr** - eBook and audiobook tracker
- **mylar3** - Comic book collection manager
- **kapowarr** - Manga/comic tracker
- **prowlarr** - Indexer/tracker for *arr suite
- **homepage** - Customizable dashboard/homepage

### Download Clients
- **qbittorrent** - Torrent client
- **sabnzbd** - Usenet downloader
- **metube** - YouTube video downloader
- **flaresolverr** - Cloudflare CDN bypasser

### Game Libraries
- **romm** - ROM library manager
- **retrom** - ROM library with metadata
- **gamevault** - Game vault with IGDB integration
- **gaseous** - Game manager and organizer
- **gameyfin** - Game aggregation platform
- **amule** - File sharing (P2P)

### Utilities
- **vaultwarden** - Bitwarden-compatible password manager
- **paperless-ngx** - Document management and OCR

## Architecture

- **basechart** - Reusable Kubernetes Deployment template used by all services
- **Individual service charts** - Customize per-service via values.yaml
- **volumes chart** - Creates storage PVCs on the host
- **traefik** - HTTP gateway routing services to external URLs
- **cert-manager** - Automatic HTTPS certificate management

## Deployment Methods

**Single Service:**
```bash
make deploy chart=jellyfin
```

**All Services:**
```bash
make deploy-all
```

**Scale Down (pause services):**
```bash
make scale-down-all
```

**Scale Up (resume services):**
```bash
make scale-up-all
```

**Destroy Services:**
```bash
make destroy-all
```

## Troubleshooting

**Services not accessible?**
- Ensure K3S is running: `systemctl status k3s`
- Check Traefik restart: `sudo systemctl restart k3s`
- Verify hostnames in `/etc/hosts`

**Pods stuck in pending?**
- Check volume paths exist and are readable
- View logs: `kubectl logs deployment/jellyfin -n media-stack`

**Secrets not working?**
- Verify secrets exist: `kubectl get secrets -n media-stack`
- Check secret names match chart values exactly

## Additional Notes

- All services run in the `media-stack` namespace
- Data persists on the host filesystem as configured in `charts/volumes/values.yaml`
- Services auto-restart on pod failure
- Check individual chart READMEs for service-specific configuration

## Legal Notice

- This project provides deployment tools for media services. Users are responsible for ensuring their
use complies with applicable laws and service terms. These tools have legitimate uses
for personal media management, but may not be legal in all jurisdictions or for all use cases.

- This project is for educational purposes. The author does not condone or support the use of these tools for copyright infringement.
