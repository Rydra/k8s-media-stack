# Gamevault helm chart

This helm chart will deploy the Gamevault service in the cluster, and exposed
by the gateway in the hostname `gamevault.local`

## Setting up locally

This setup assumes you're using the values established in this values.yaml.
Tweak the values accordingly if you decide to you change them!

### 1. Add hostname to /etc/hosts

This is necessary to be able to access http://gamevault.local from the browser. Run

```bash
sudo nano /etc/hosts
```

and make sure this line is present:

```
127.0.0.1      gamevault.local
```


### 2. Passing in the secrets

From the root of the repository, run

```bash
make set-secrets name=gamevault-secrets
```

and write or paste these secrets in an `env` format, setting up the appropriate values.
These will be used as environment variables for the deploy of gamevault (Press Ctrl+D when finished):

```env
POSTGRES_PASSWORD=yourpass
IGDB_CLIENT_ID=yourclientID
IGDB_CLIENT_SECRET=YourClientSecret
```

Consult the [gamevault documentation on how to obtain the IGDB client ID and Secret](https://gamevau.lt/docs/server-docs/metadata-enrichment/provider-igdb) (you'll need a Twitch account)

### 3. Testing

Open your browser and access [http://gamevault.local](http://gamevault.local). Vault
should show up.
