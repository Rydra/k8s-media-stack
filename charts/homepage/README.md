# Gamevault helm chart

This helm chart will deploy the Homepage service in the cluster, and exposed
by the gateway in the hostname `home.local`

## Setting up locally

This setup assumes you're using the values established in this values.yaml.
Tweak the values accordingly if you decide to you change them!

### 1. Add hostname to /etc/hosts

This is necessary to be able to access http://home.local from the browser. Run

```bash
sudo nano /etc/hosts
```

and make sure this line is present:

```
127.0.0.1      home.local
```


### 2. Passing in the secrets

From the root of the repository, run

```bash
make set-secrets name=homepage-secret-env
```

and write or paste these secrets in an `env` format, setting up the appropriate values.
These will be used as environment variables for the deploy of Homepage (Press Ctrl+D when finished):

```env
HOMEPAGE_VAR_KOMGA_USER=your@mail.com
HOMEPAGE_VAR_KOMGA_PW=Yourpass
HOMEPAGE_VAR_RADARR_APIKEY=YourApiKey
HOMEPAGE_VAR_SONARR_APIKEY=YourApiKey
HOMEPAGE_VAR_IMMICH_APIKEY=YourApiKey
HOMEPAGE_VAR_PROWLARR_APIKEY=YourApiKey
HOMEPAGE_VAR_MYLAR3_APIKEY=YourApiKey
HOMEPAGE_VAR_QBT_USER=youruser
HOMEPAGE_VAR_QBT_PW=yourpass
HOMEPAGE_VAR_PAPERLESS_USER=youruser
HOMEPAGE_VAR_PAPERLESS_PW=yourpass
HOMEPAGE_VAR_JELLYFIN_APIKEY=YourApiKey
HOMEPAGE_VAR_KAPOWARR_APIKEY=YourApiKey
```

Consult the [homepage documentation on further configuration details](https://gethomepage.dev/installation/k8s/)

### 3. Testing

Open your browser and access [http://home.local](http://home.local). Homepage
should show up.
