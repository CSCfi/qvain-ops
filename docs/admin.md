
# Admin guide

Qvain is a metadata description service, one of the main services for the [Fairdata](https://www.fairdata.fi/) project of the Finnish [Ministry of Culture and Education](https://minedu.fi/).

This document is the _admin guide_, a short manual for administering Qvain.

## Architecture

The application consists of a [frontend web application](https://github.com/CSCfi/qvain-js) written in Javascript ([Vue](http://vuejs.org/)) and a [backend service](https://github.com/CSCfi/qvain-api) written in [Go](http://golang.org/).

The most common setup would be a reverse proxy such as [nginx](nginx.org) serving both the frontend's static web pages and proxying anything under the URL `/api/` to the backend process – which is a web server itself.


### Frontend

The Javascript frontend includes some basic HTML pages and a handful of images and is served by a web server ([nginx](nginx.org)). These are relatively small, static files that can be cached. Once unpacked on installation, they should not change except for software updates.

The directory that holds these files should be the root of the web server that serves the Qvain website: the `index.html` file will load the Javascript interface which will then make API calls to the backend throught the proxying web server.


### Backend

The backend is a collection of binary commands compiled from Go code. It is written in library style, with commands importing functionality from library modules. Most binaries are command-line interfaces that execute some specific feature of Qvain; one of them is the actual backend service, a web server, which we will discuss here.

#### Managing the service

The Qvain backend service is a background process that listens and (hopefully) responds to HTTP requests.

Qvain uses [systemd](https://www.freedesktop.org/wiki/Software/systemd/) and comes with a systemd unit file. This unit file makes sure the service starts after Postgresql, which is a hard dependency. Qvain can run without systemd, but you'll have to figure out your own start-up scripts.

The backend process looks like this in `ps` output:

```
qvain    25826  0.0  0.0 286960  7500 ?        Ssl  Aug17   0:19 /srv/qvain/bin/qvain-backend
```

You can start, stop and restart qvain just like any other system service, it doesn't need special care.

```shell
# systemctl stop qvain
# systemctl start qvain
# systemctl is-active qvain
active
```

You can check the service status:

```shell
# systemctl status qvain
● qvain.service - Qvain backend service
   Loaded: loaded (/etc/systemd/system/qvain.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2018-08-30 13:35:09 EEST; 2min 4s ago
 Main PID: 11853 (qvain-backend)
   CGroup: /system.slice/qvain.service
           └─11853 /srv/qvain/bin/qvain-backend

Aug 30 13:35:09 qvain-test.novalocal systemd[1]: Started Qvain backend service.
Aug 30 13:35:09 qvain-test.novalocal systemd[1]: Starting Qvain backend service...
Aug 30 13:35:09 qvain-test.novalocal qvain[11853]: {"level":"warn","component":"main","at":"main.go:131","time":"2018-08-30T13:35:09+03:00","msg":"environment variable APP_ENV_CHECK is not set"}
Aug 30 13:35:09 qvain-test.novalocal qvain[11853]: {"level":"info","component":"main","hash":"7f7943e","tag":"7f7943e","port":"8080","host":"qvain.example.com","iface":"localhost","standalone":false,"debug":true,"at":"main.go:188","time":"2018-08-30T13:35:09+03:00","msg":"starting http server"}
```

The log output is in JSON. If the server starts successfully, it will show (some variation possible depending on version):

```json
{"level":"info","component":"main","hash":"7f7943e","tag":"7f7943e","port":"8080","host":"qvain.example.com","iface":"localhost","standalone":false,"debug":true,"at":"main.go:188","time":"2018-08-30T13:35:09+03:00","msg":"starting http server"}
```

This gives you the message `"starting http server"` on host `"qvain.example.com"` listening on interface `"localhost"` port `"8080"`.

You can follow the live log with journalctl:

```shell
# journalctl -fu qvain
```


#### Configuration

Qvain gets its configuration from the environment. When starting the backend with systemd, the unit file will point to a file with environment variables that will place those variables in the process' environment.

If you want to run Qvain commands – most of which need some configuration – you need to export the `env` file manually, so they find the necessary environment variables. For instance:

```shell
set -a; source ~/.env/qvain.env; set +a
```

... this will export the environment variables to your current shell. On production systems, the environment file can be found in the home of the user the service runs as: `~qvain/.env`, if that user is `qvain`.

The service binary also has a handful of command line flags, most of which allow overriding environment variables:

```shell
$ bin/qvain-backend -h
Usage of bin/qvain-backend:
  -d    log debug output (env APP_DEBUG) (default true)
  -dev
        dev mode: debug, http-only, CORS:all (env APP_DEV_MODE)
  -http
        use http for generated links (env APP_FORCE_HTTP_SCHEME)
  -nrl
        disable http request logging
  -port string
        port to run web server on (env APP_HTTP_PORT) (default "8080")
  -q    quiet: disable all logging
```

These options are probably only useful for developing the software or doing load testing.


#### Locale

Make sure that the system has a Unicode utf-8 locale configured either system-wide or for Qvain and especially Postgresql.


#### Errors, crashes and start-up problems

Qvain has a recovery middleware handler that should catch any program crashes that might occur inside the web server code. Code outside of the web server as well as the web server itself are not protected. In practice, ignoring extreme situations, that means only the start-up code and web server initialisation have the potential to crash the process.

Hence, the only obvious reason Qvain might not start properly is if it can't bind to its network ports.

If the backend process would fail to start, it should output an error message to `STDERR` which you can find in the journald log. But this should be rare.


#### Logs

Qvain writes its logs to `STDOUT` in JSON format. If started from its systemd unit file, those logs go to `journald` and can be queried in many ways with `journalctl`.

Systemd service and Qvain log output:

```shell
# journalctl -u qvain
```

Only Qvain logging output for the last hour (note the `-t`):

```shell
# journalctl -t qvain --since "1 hour ago"
```

Qvain does not log a lot: non-debug output is estimated at about 2-3 lines per request, and about double that when debug is set.

Debug logs are only interesting to developers (well, *interesting* is strongly put...).


#### Permissions

Qvain should run as its own user, e.g. `qvain`. You might need to create such a user. The systemd unit file will run the backend process as that user.

Qvain needs [`CAP_NET_BIND_SERVICE`](http://man7.org/linux/man-pages/man7/capabilities.7.html) to bind to ports below 1024. If the installation package grants Qvain certain unix permissions or capabilities, do not revoke them, as debugging resulting errors can be tricky.


#### Versions

You can get information on the backend version by checking the start-up line in the logs or by visiting the URL `/api/version` on the server Qvain runs on. Output is in JSON:

```json
{
	"name": "Qvain",
	"description": "Qvain API",
	"version": "0.0.1",
	"tag": "5bc14fa-dev",
	"hash": "5bc14fa",
	"repo": "https://github.com/CSCfi/qvain-api/tree/5bc14fa"
}
```


#### Maintenance

Since it's preferred to store the systemd logs to disk, these logs can grow over time. Be sure to keep an eye on `/var/log/journal/`:

```shell
# journalctl --disk-usage
Archived and active journals take up 784.1M on disk.
```

If you want to get rid of old systemd logs, consider extracting the Qvain log output and archive it somewhere, for instance:

```shell
journalctl -o cat -t qvain --until "1 month ago" | gzip -9 > qvain.log
```

## Dependencies

### Postgresql

Qvain requires Postgresql 9.6.x. It will run without, but it won't do much useful without its main data store.

It uses the standard [`psql` environment variables](https://www.postgresql.org/docs/9.6/static/libpq-envars.html) to connect to the database. The default Qvain configuration file is configured to connect over a unix domain socket.

Upgrading: You can safely upgrade to any Postgresql 9.6.x version. Make sure to check if Postgresql restarts correctly.

### Redis

Qvain can make use of [Redis](https://redis.io/) >3.2.0. Again, the default configuration is to connect over a local unix socket.

Qvain will run without Redis, but login sessions might be short and will not be resumed if the backend process is restarted.

Upgrading: You can safely upgrade to any newer Redis version offered by the system package manager. Make sure to check if Redis restarts correctly.


### Web server

Qvain by default runs behind a web server (e.g. [nginx](http://nginx.org/)) that acts as a reverse proxy and serves the static files of the frontend.

Qvain can also run stand-alone if pointed to the right TLS certificates and the [`CAP_NET_BIND_SERVICE`](http://man7.org/linux/man-pages/man7/capabilities.7.html) capability is set.

In the default configuration, Qvain runs behind a proxy on `localhost` port `8080`.

Any recent version of Nginx or other web server with a fast reverse proxy should do.

Upgrading: It is safe to update the web server as long as the configuration file works correctly with the new version.
