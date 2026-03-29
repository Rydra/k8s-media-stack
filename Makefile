generate-deployment-yaml:
	kubectl create deployment komga --image=gotson/komga:latest --dry-run=client -o yaml > deployment.yaml

generate-configmap-yaml:
	kubectl create configmap komga-config --dry-run=client -o yaml > configmap.yaml

generate-svc-yaml:
	kubectl create service clusterip komga --tcp=8080:8080 --dry-run=client -o yaml > service.yaml

generate-httproute-yaml:
	kubectl create -f charts/komga/templates/httproute.yaml --dry-run=client -o yaml > httproute.yaml

create-ingress:
	kubectl create ingress komga-ingress --rule="/=komga:25600"

chart := komga
namespace := media-stack

### Deployments

deploy:
	helm upgrade --install $(chart) charts/$(chart) -n $(namespace) --create-namespace

service := radarr

deploy-volumes:
	helm upgrade --install volumes charts/volumes -n volumes

destroy-volumes:
	helm uninstall volumes -n volumes

deploy-support:
	$(MAKE) deploy-volumes
	$(MAKE) install-cert-manager-crds
	$(MAKE) deploy chart=cert-manager
	$(MAKE) deploy chart=shared

deploy-all:
	$(MAKE) deploy chart=bazarr
	$(MAKE) deploy chart=komga
	$(MAKE) deploy chart=kapowarr
	$(MAKE) deploy chart=prowlarr
	$(MAKE) deploy chart=radarr
	$(MAKE) deploy chart=sonarr
	$(MAKE) deploy chart=metube
	$(MAKE) deploy chart=qbittorrent
	$(MAKE) deploy chart=paperless-ngx
	$(MAKE) deploy chart=jellyfin
	$(MAKE) deploy chart=flaresolverr
	$(MAKE) deploy chart=vaultwarden
	$(MAKE) deploy chart=immich
	$(MAKE) deploy chart=homepage
	$(MAKE) deploy chart=romm

destroy-all:
	-$(MAKE) destroy chart=bazarr
	-$(MAKE) destroy chart=komga
	-$(MAKE) destroy chart=kapowarr
	-$(MAKE) destroy chart=prowlarr
	-$(MAKE) destroy chart=radarr
	-$(MAKE) destroy chart=sonarr
	-$(MAKE) destroy chart=metube
	-$(MAKE) destroy chart=qbittorrent
	-$(MAKE) destroy chart=paperless-ngx
	-$(MAKE) destroy chart=jellyfin
	-$(MAKE) destroy chart=flaresolverr
	-$(MAKE) destroy chart=vaultwarden
	-$(MAKE) destroy chart=immich
	-$(MAKE) destroy chart=homepage
	-$(MAKE) destroy chart=romm


destroy:
	helm uninstall $(chart) -n $(namespace)

install-cert-manager-crds:
	# cert-manager is a dependency of some of our charts, so we'll install it first
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

### Scaling services

scale-down:
	kubectl scale deployment $(service) --replicas=0 -n $(namespace)

scale-up:
	kubectl scale deployment $(service) --replicas=1 -n $(namespace)

scale-down-all:
	kubectl scale deployment bazarr --replicas=0 -n $(namespace)
	kubectl scale deployment komga --replicas=0 -n $(namespace)
	kubectl scale deployment lidarr --replicas=0 -n $(namespace)
	kubectl scale deployment mylar3 --replicas=0 -n $(namespace)
	kubectl scale deployment prowlarr --replicas=0 -n $(namespace)
	kubectl scale deployment radarr --replicas=0 -n $(namespace)
	kubectl scale deployment sonarr --replicas=0 -n $(namespace)
	kubectl scale deployment readarr --replicas=0 -n $(namespace)
	kubectl scale deployment qbittorrent --replicas=0 -n $(namespace)
	kubectl scale deployment paperless-ngx --replicas=0 -n $(namespace)
	kubectl scale deployment jellyfin --replicas=0 -n $(namespace)
	kubectl scale deployment flaresolverr --replicas=0 -n $(namespace)
	kubectl scale deployment metube --replicas=0 -n $(namespace)


scale-up-all:
	kubectl scale deployment bazarr --replicas=1 -n $(namespace)
	kubectl scale deployment komga --replicas=1 -n $(namespace)
	kubectl scale deployment lidarr --replicas=1 -n $(namespace)
	kubectl scale deployment mylar3 --replicas=1 -n $(namespace)
	kubectl scale deployment prowlarr --replicas=1 -n $(namespace)
	kubectl scale deployment radarr --replicas=1 -n $(namespace)
	kubectl scale deployment sonarr --replicas=1 -n $(namespace)
	kubectl scale deployment readarr --replicas=1 -n $(namespace)
	kubectl scale deployment qbittorrent --replicas=1 -n $(namespace)
	kubectl scale deployment paperless-ngx --replicas=1 -n $(namespace)
	kubectl scale deployment jellyfin --replicas=1 -n $(namespace)
	kubectl scale deployment flaresolverr --replicas=1 -n $(namespace)
	kubectl scale deployment metube --replicas=1 -n $(namespace)

### Immich has high memory usage, so we'll scale it down separately

update-deps:
	helm dependency update charts/$(chart)

scale-down-immich:
	kubectl scale deployment immich-server --replicas=0 -n $(namespace)
	kubectl scale deployment immich-db --replicas=0 -n $(namespace)
	kubectl scale deployment immich-machine-learning --replicas=0 -n $(namespace)
	kubectl scale deployment immich-valkey --replicas=0 -n $(namespace)

scale-up-immich:
	kubectl scale deployment immich-server --replicas=1 -n $(namespace)
	kubectl scale deployment immich-db --replicas=1 -n $(namespace)
	kubectl scale deployment immich-machine-learning --replicas=1 -n $(namespace)
	kubectl scale deployment immich-valkey --replicas=1 -n $(namespace)

scale-down-paperless:
	kubectl scale deployment paperless-ngx --replicas=0 -n $(namespace)

scale-up-paperless:
	kubectl scale deployment paperless-ngx --replicas=1 -n $(namespace)

scale-down-gamevault:
	$(MAKE) scale-down service=gamevault
	$(MAKE) scale-down service=gamevault-db

### Management

env_vars ?=
CONSTRUCTED_ARGS = $(foreach item,$(MY_LIST),--arg=$(item))

set-homepage-secrets:
	-kubectl delete secret homepage-secret-env -n $(namespace)
	kubectl create secret generic homepage-secret-env -n $(namespace) \
	$(foreach item,$(env_vars),--from-literal $(item))

set-secrets:
	-kubectl delete secret $(name) -n $(namespace)
	kubectl create secret generic $(name) -n $(namespace) \
	$(foreach item,$(env_vars),--from-literal $(item))


install-gateway-crds:
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml
	kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.6/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml
	# install nginx gateway controller
	# helm install ngf oci://ghcr.io/nginxinc/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway

install-ingress-controller:
	minikube addons enable ingress

configure-traefik:
	# In k3s you need to configure traefik
	helm install traefik traefik/traefik -f charts/traefik/values.yaml --wait

install-reloader:
	helm repo add stakater https://stakater.github.io/stakater-charts
	helm repo update
	helm install reloader stakater/reloader -n default
