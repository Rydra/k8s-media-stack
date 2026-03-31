# Gamevault helm chart

This helm chart will deploy the RomM service in the cluster, and exposed
by the gateway in the hostname `romm.local`

## Setting up locally

This setup assumes you're using the values established in this values.yaml.
Tweak the values accordingly if you decide to you change them!

### 1. Add hostname to /etc/hosts

This is necessary to be able to access http://romm.local from the browser. Run

```bash
sudo nano /etc/hosts
```

and make sure this line is present:

```
127.0.0.1      romm.local
```

### 2. Passing in the secrets

From the root of the repository, run

```bash
make set-secrets name=romm-secrets
```

and write or paste these secrets in an `env` format, setting up the appropriate values.
These will be used as environment variables for the deploy of Homepage (Press Ctrl+D when finished):

```env
MARIADB_ROOT_PASSWORD=AnyPass
MARIADB_PASSWORD=AnyPass
# Generate the value with `openssl rand -hex 32`
ROMM_AUTH_SECRET_KEY=thevalue
SCREENSCRAPER_USER=YourUser
SCREENSCRAPER_PASSWORD=YourPass
RETROACHIEVEMENTS_API_KEY=YourApiKey
STEAMGRIDDB_API_KEY=YourApiKey
IGDB_CLIENT_ID=YourClientId
IGDB_CLIENT_SECRET=YourSecret
```

Consult the [RomM documentation on further configuration details and setting up the metadata scrappers](https://docs.romm.app/latest/Getting-Started/Quick-Start-Guide/#build)

### 3. Testing

Open your browser and access [http://romm.local](http://romm.local). RomM
should show up.
