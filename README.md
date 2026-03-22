## Preface

This Kubernetes setup is prepared to build a homelab with K3S (though with some
small configuration changes this setup can actually be deployed everywhere). K3S
has the advantage that it integrates very well in the setup of a homelab, providing
storage classes that map to actual folders of your filesystem.

## Getting Started

1. Spin up K3S in your computer
2. Add the HTTPs certificate secret keys

```bash
make install-cert-manager-crds
make deploy chart=cert-manager
```

3. Copy the file `traefik/values.yaml` to `/var/lib/rancher/k3s/server/manifests/traefik-custom.yaml`

```bash
sudo cp traefik/values.yaml /var/lib/rancher/k3s/server/manifests/traefik-custom.yaml
```

This setup will expose the cluster in your local machine via the ports 80 (http)
and 443 (https)

4. Configure the volumes where you are going to have all your contents. I like to reserve a folder
called `storage` somewhere, where all the data from the pods will be placed. Modify the file
`charts/volumes/values.yaml`, set the appropriate paths where you'd like to store the configs for all
services, the immich data and the media data (I decided to separate immich from the rest of
the media), and deploy the volumes and the persistence volume claims -by default the claims will
be installed in the `media-stack` namespace-:

```bash
make deploy-volumes
make deploy chart=shared
```

5. Now you're ready to install all the services:

```bash
make deploy-all
```

6. Add this entry to the `/etc/hosts` of your machine:

```
127.0.0.1 qbit.local vault.local home.local immich.local
```

7. Done! Access `http://home.local` to access the dashboard. From there you will
be able to navigate all the services:

| Service name | URL |
| ------------ | --- |
| Homepage | http://home.local |
| Bazarr | http://localhost/bazarr |
| Jellyfin | http://localhost/jellyfin |
| Komga | http://localhost/komga |
| Metube | http://localhost/metube |
| Mylar3 | http://localhost/mylar3 |
| Prowlarr | http://localhost/prowlarr |
| Qbittorrent | http://qbit.local |
| Radarr | http://localhost/radarr |
| Sonarr | http://localhost/sonarr |
| Vaultwarden | https://vault.local |

## Charts

* **basechart**: This chart is generic enough to be used by services that are not too complex. Deploying this chart
with the `charts/value-files/values-*` files yields to a successful deployment.
* **cert-manager**: This chart is used a secret key called `local-tls` that is used by _Traefik_
to provide HTTPs capabilities to your localhost. This move was necessary since _Vaultwarden_
requires HTTPs to function properly.
* **flaresolverr**: A simple chart that exposes _Flaresolverr_, require by *arr applications
to resolve CloudFlare blockings.
* **homepage**: A nice homepage to

## Traefik configuration

