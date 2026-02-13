# Blocky Helm Chart

[![Lint and Test Chart](https://github.com/leventyalcin/blocky-helm-chart/actions/workflows/ci.yaml/badge.svg)](https://github.com/leventyalcin/blocky-helm-chart/actions/workflows/ci.yaml)
[![Release Chart](https://github.com/leventyalcin/blocky-helm-chart/actions/workflows/release.yaml/badge.svg)](https://github.com/leventyalcin/blocky-helm-chart/actions/workflows/release.yaml)

A Helm chart for [Blocky DNS Server](https://github.com/0xERR0R/blocky) - Fast and lightweight DNS proxy with ad-blocking.

## Quick Start

```bash
helm repo add leventyalcin https://leventyalcin.github.io/blocky-helm-chart
helm repo update
helm install blocky leventyalcin/blocky
```

## Versioning

All chart versions are preserved and can be installed at any time.

```bash
# List all available versions
helm search repo leventyalcin/blocky --versions

# Install a specific version
helm install blocky leventyalcin/blocky --version 1.0.0

# Upgrade to a specific version
helm upgrade blocky leventyalcin/blocky --version 1.0.5
```

See the [Releases](https://github.com/leventyalcin/blocky-helm-chart/releases) page for changelog.

## Installation

### From Helm Repository

```bash
# Add the Helm repository
helm repo add leventyalcin https://leventyalcin.github.io/blocky-helm-chart
helm repo update

# Install with default values
helm install blocky leventyalcin/blocky

# Install in a specific namespace
helm install blocky leventyalcin/blocky -n dns --create-namespace

# Install with custom values file
helm install blocky leventyalcin/blocky -f my-values.yaml
```

### From Source

```bash
git clone https://github.com/leventyalcin/blocky-helm-chart.git
cd blocky-helm-chart
helm install blocky .
```

## Configuration

See [values.yaml](values.yaml) for the full list of configurable parameters.

### Key Parameters

| Parameter                               | Description                                                           | Default                  |
|-----------------------------------------|-----------------------------------------------------------------------|--------------------------|
| `replicaCount`                          | Number of replicas                                                    | `1`                      |
| `image.repository`                      | Blocky container image                                                | `ghcr.io/0xerr0r/blocky` |
| `image.tag`                             | Image tag                                                             | `latest`                 |
| `dnsService.type`                       | DNS service type                                                      | `LoadBalancer`           |
| `dnsService.port`                       | DNS port                                                              | `53`                     |
| `webService.type`                       | Blocky API service type                                               | `ClusterIP`              |
| `webService.port`                       | Blocky API port                                                       | `4000`                   |
| `blockyUI.enabled`                      | Enable Blocky UI sidecar                                              | `false`                  |
| `blockyUI.ingress.enabled`              | Enable ingress for Blocky UI                                          | `false`                  |
| `config.queryLog.type`                  | Query logging: `none`, `mysql`, `postgresql`, `console`               | `none`                   |
| `config.blocking.loading.refreshPeriod` | How often to refresh blocklists (Go duration, e.g. `168h` for 7 days) | `168h`                   |
| `config.blocking.loading.strategy`      | List loading strategy: `fast`, `failOnError`, `blocking`              | `fast`                   |
| `config.redis.enabled`                  | Enable Redis for cache synchronization                                | `false`                  |
| `config.redis.external.address`         | External Redis address (disables sidecar if set)                      | `""`                     |
| `serviceMonitor.enabled`                | Enable ServiceMonitor                                                 | `true`                   |

### Examples

#### Basic Installation with Custom Upstream DNS

```yaml
# values.yaml
config:
  upstreams:
    groups:
      default:
        - https://dns.cloudflare.com/dns-query
        - https://dns.google/dns-query
```

#### Enable Blocky UI with Ingress

[Blocky UI](https://github.com/gabeduartem/blocky-ui) provides a web interface for managing Blocky. It runs as a sidecar container in the same pod.

```yaml
# values.yaml
blockyUI:
  enabled: true
  image:
    repository: ghcr.io/gabeduartem/blocky-ui
    tag: "1.5.0"
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    hostname: blocky.example.com
    tls:
      secretName: blocky-tls
```

#### Node Affinity and Tolerations

```yaml
# values.yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node-role.kubernetes.io/dns
              operator: Exists

tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "dns"
    effect: "NoSchedule"
```

#### Custom DNS Entries

```yaml
# values.yaml
config:
  customDNS:
    customTTL: 1h
    mapping:
      printer.home: 192.168.1.100
      nas.home: 192.168.1.50
```

## Blocky UI

This chart includes optional support for [Blocky UI](https://github.com/gabeduartem/blocky-ui), a web interface for Blocky.

| Parameter                         | Description              | Default                         |
|-----------------------------------|--------------------------|---------------------------------|
| `blockyUI.enabled`                | Enable Blocky UI sidecar | `false`                         |
| `blockyUI.image.repository`       | Blocky UI image          | `ghcr.io/gabeduartem/blocky-ui` |
| `blockyUI.image.tag`              | Blocky UI image tag      | `v1.1.0`                        |
| `blockyUI.port`                   | Blocky UI port           | `3000`                          |
| `blockyUI.ingress.enabled`        | Enable ingress           | `false`                         |
| `blockyUI.ingress.className`      | Ingress class            | `""`                            |
| `blockyUI.ingress.hostname`       | Ingress hostname         | `blocky-ui.local`               |
| `blockyUI.ingress.tls.secretName` | TLS secret name          | `""`                            |

## Monitoring

The chart creates a ServiceMonitor with `release: prometheus` label by default, compatible with [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).

Import the Grafana dashboard: [Dashboard ID 13768](https://grafana.com/grafana/dashboards/13768)

## Query Logging

The chart supports query logging to MySQL, PostgreSQL, or console. Only **one** type can be enabled at a time.

| Parameter                       | Description                                            | Default                                                                      |
|---------------------------------|--------------------------------------------------------|------------------------------------------------------------------------------|
| `config.queryLog.type`          | Logging type: `none`, `mysql`, `postgresql`, `console` | `none`                                                                       |
| `config.queryLog.fields`        | Fields to log                                          | `[clientIP, clientName, responseReason, responseAnswer, question, duration]` |
| `config.queryLog.flushInterval` | Flush interval                                         | `30s`                                                                        |

### MySQL

```yaml
config:
  queryLog:
    type: mysql
    mysql:
      database: blocky
      user: blocky
      # Use existing secret (must have 'mysql-root-password' and 'mysql-password' keys)
      existingSecret: ""  # If empty, a secret is auto-generated
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
      persistence:
        enabled: true
        storageClass: ""  # Uses default if empty
        size: 5Gi
```

#### External MySQL

Use an external MySQL database instead of deploying one:

```yaml
config:
  queryLog:
    type: mysql
    mysql:
      database: blocky
      user: blocky
      external:
        hostname: mysql.example.com
        port: 3306
        secretName: my-mysql-secret
        secretKey: password
```

### PostgreSQL

```yaml
config:
  queryLog:
    type: postgresql
    postgresql:
      database: blocky
      user: blocky
      # Use existing secret (must have 'postgresql-password' key)
      existingSecret: ""  # If empty, a secret is auto-generated
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
      persistence:
        enabled: true
        storageClass: ""
        size: 5Gi
```

#### External PostgreSQL

Use an external PostgreSQL database instead of deploying one:

```yaml
config:
  queryLog:
    type: postgresql
    postgresql:
      database: blocky
      user: blocky
      external:
        hostname: postgresql.example.com
        port: 5432
        secretName: my-postgresql-secret
        secretKey: password
```

### Console

```yaml
config:
  queryLog:
    type: console
```

## Default Lists

* StevenBlack
  * Unified hosts <https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts>
* blocklistproject
  * Abuse: <https://blocklistproject.github.io/Lists/abuse.txt>
  * Ads: <https://blocklistproject.github.io/Lists/ads.txt>
  * Crypto: <https://blocklistproject.github.io/Lists/crypto.txt>
  * Drugs: <https://blocklistproject.github.io/Lists/drugs.txt>
  * Fraud: <https://blocklistproject.github.io/Lists/fraud.txt>
  * Gambling: <https://blocklistproject.github.io/Lists/gambling.txt>
  * Malware: <https://blocklistproject.github.io/Lists/malware.txt>
  * Phishing: <https://blocklistproject.github.io/Lists/phishing.txt>
  * Piracy: <https://blocklistproject.github.io/Lists/piracy.txt>
  * Ransomware: <https://blocklistproject.github.io/Lists/ransomware.txt>
  * Redirect: <https://blocklistproject.github.io/Lists/redirect.txt>
  * Scam: <https://blocklistproject.github.io/Lists/scam.txt>
  * Tracking: <https://blocklistproject.github.io/Lists/tracking.txt>
  * Smart TV: <https://blocklistproject.github.io/Lists/smart-tv.txt>
* Firebog
  * Suspicious Lists
    * <https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt>
    * <https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts>
    * <https://v.firebog.net/hosts/static/w3kbl.txt>
  * Advertising Lists
    * <https://adaway.org/hosts.txt>
    * <https://v.firebog.net/hosts/AdguardDNS.txt>
    * <https://v.firebog.net/hosts/Admiral.txt>
    * <https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt>
    * <https://v.firebog.net/hosts/Easylist.txt>
    * <https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext>
    * <https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts>
    * <https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts>
  * Tracking & Telemetry Lists
    * <https://v.firebog.net/hosts/Easyprivacy.txt>
    * <https://v.firebog.net/hosts/Prigent-Ads.txt>
    * <https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts>
    * <https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt>
    * <https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt>
  * Malicious Lists
    * <https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt>
    * <https://v.firebog.net/hosts/Prigent-Crypto.txt>
    * <https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts>
    * <https://phishing.army/download/phishing_army_blocklist_extended.txt>
    * <https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt>
    * <https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt>
    * <https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts>
    * <https://urlhaus.abuse.ch/downloads/hostfile/>
    * <https://lists.cyberhost.uk/malware.txt>
* hagezi
  * Multi PRO - Extended protection (Recommended): <https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/wildcard/pro.txt>
* kboghdady
  * <https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/youtubelist.txt>
* osid.nl
  * Big: <https://big.oisd.nl/domainswild>

## Resources

* [Blocky Documentation](https://0xerr0r.github.io/blocky/)
* [Blocky GitHub](https://github.com/0xERR0R/blocky)
* [Blocky UI GitHub](https://github.com/gabeduartem/blocky-ui)
* [Configuration Reference](https://0xerr0r.github.io/blocky/latest/configuration/)

## License

Apache 2.0
