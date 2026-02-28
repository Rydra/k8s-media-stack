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

deploy:
	helm upgrade --install $(chart) charts/$(chart) -n $(chart) --create-namespace

destroy:
	helm uninstall $(chart) -n $(chart)

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
