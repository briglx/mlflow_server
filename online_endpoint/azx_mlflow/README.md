# Deploy a mlflow container

From [azureml-examples mlflow](https://github.com/Azure/azureml-examples/blob/main/cli/endpoints/online/custom-container/mlflow/multideployment-scikit/README.md)

```bash
base_path=./online_endpoint/azx_mlflow
image_name="online_endpoint/azx_mlflow:latest"
dockerfile_path="./online_endpoint/azx_mlflow/Dockerfile"
artifact_path="./artifacts/iris_model"

# Build image
docker build --build-arg "ARTIFACT_PATH=$artifact_path" --build-arg "BASE_PATH=$base_path" -t "$image_name" -f "${dockerfile_path}" .

# Run container
docker run -p 5000:5000 -p 31311:31311 "$image_name"

# Interactive shell
docker run -it --entrypoint /bin/bash -p 5000:5000 -p 31311:31311  "$image_name"
# Start service in container
$ runsvdir /var/runit
# $ azmlinfsrv --entry_script score.py --port 5000
# $ azmlinfsrv --entry_script ./onlinescoring/score.py --model_dir ./ --port 5000

# Connect to running image
docker exec -it $(docker ps --filter "ancestor=$image_name"  -q ) /bin/bash


# Check liveness
curl -p 127.0.0.1:5000
curl --header "Content-Type: application/json" --request GET http://localhost:5000/

# Check prediction
curl -p 127.0.0.1:5000/score
curl --header "Content-Type: application/json" --request GET http://localhost:5000/score
curl -X POST 127.0.0.1:31311/score -H "Content-Type: application/json" -d @$base_path/input_example.json
```

# Debugging

Various debugging notes On the Docker image

## General Startup

```bash
$ conda env list
# conda environments:
#
base                     /opt/miniconda
amlenv                   /opt/miniconda/envs/amlenv
userenv               *  /opt/miniconda/envs/userenv

$ printenv
CONDA_SHLVL=2
AZUREML_MODEL_DIR=/var/azureml-app/model
LC_ALL=C.UTF-8
LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:
LD_LIBRARY_PATH=/opt/miniconda/envs/userenv/lib:
CONDA_EXE=/opt/miniconda/bin/conda
SVDIR=/var/runit
LANG=C.UTF-8
HOSTNAME=b15fccff0f1e
MLFLOW_MODEL_FOLDER=
AZUREML_ENTRY_SCRIPT=mlflow_score_script.py
CONDA_PREFIX=/opt/miniconda/envs/userenv
_CE_M=
CONDA_PREFIX_1=/opt/miniconda
PWD=/
AML_APP_ROOT=/var/mlflow_resources
HOME=/home/dockeruser
CONDA_PYTHON_EXE=/opt/miniconda/bin/python
APP_SERVER_PATH=/var/azureml-app/server
CONDA_ENV_DIR=/opt/miniconda/envs
DEBIAN_FRONTEND=noninteractive
WORKER_TIMEOUT=300
APP_PATH=/var/azureml-app
_CE_CONDA=
APP_MODEL_PATH=/var/azureml-app/model
CONDA_PROMPT_MODIFIER=(userenv)
TERM=xterm
SHLVL=1
AZUREML_INFERENCE_SERVER_HTTP_ENABLED=True
PATH=/opt/miniconda/envs/userenv/bin:/opt/miniconda/condabin:/opt/miniconda/envs/userenv/bin:/opt/miniconda/envs/amlenv/bin:/opt/miniconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER_ENV=userenv
AZUREML_CONDA_ENVIRONMENT_PATH=/opt/miniconda/envs/userenv
CONDA_DEFAULT_ENV=userenv
_=/usr/bin/printenv

$ ps -eaf
UID        PID  PPID  C STIME TTY          TIME CMD
dockeru+     1     0  0 19:07 pts/0    00:00:00 /bin/bash
dockeru+    23     1  0 19:09 pts/0    00:00:00 runsvdir /var/runit
dockeru+    24    23  0 19:09 pts/0    00:00:00 runsv gunicorn
dockeru+    25    23  0 19:09 pts/0    00:00:00 runsv rsyslog
dockeru+    26    23  0 19:09 pts/0    00:00:00 runsv nginx
dockeru+    27    26  0 19:09 pts/0    00:00:00 nginx: master process /usr/sbin/nginx -g daemon off;
dockeru+    28    25  0 19:09 pts/0    00:00:00 rsyslogd -n
dockeru+    29    24  0 19:09 pts/0    00:00:00 /opt/miniconda/envs/userenv/bin/python3.10 /opt/miniconda/envs/userenv/bin/azmlinfsrv --entry_script mlflow_score_script.py --port 31311
dockeru+    48    27  0 19:09 pts/0    00:00:00 nginx: worker process
dockeru+    50    27  0 19:09 pts/0    00:00:00 nginx: worker process
dockeru+    51    27  0 19:09 pts/0    00:00:00 nginx: worker process
dockeru+    52    27  0 19:09 pts/0    00:00:00 nginx: worker process
dockeru+    54    27  0 19:09 pts/0    00:00:00 nginx: worker process
dockeru+    55    27  0 19:09 pts/0    00:00:00 nginx: worker process
dockeru+    56    27  0 19:09 pts/0    00:00:00 nginx: worker process
dockeru+    57    27  0 19:09 pts/0    00:00:00 nginx: worker process
dockeru+    91    29  0 19:09 pts/0    00:00:02 /opt/miniconda/envs/userenv/bin/python3.10 /opt/miniconda/envs/userenv/bin/azmlinfsrv --entry_script mlflow_score_script.py --port 31311
dockeru+   108     0  1 19:14 pts/1    00:00:00 /bin/bash
dockeru+   126   108  0 19:14 pts/1    00:00:00 ps -eaf

# In the var_runit_gunicore_script
ENTRY_SCRIPT_DIR=/var/mlflow_resources/.

```

## gunicorn

This is started from `runsvdir` in the `/var/runit/gunicorn/run` script. It calls:

```bash
exec azmlinfsrv --entry_script /var/mlflow_resources/mlflow_score_script.py --port 31311


```

`azmlinfsrv` is mapped to `amlserver:run` in [`azureml-inference-server` `run`](https://github.com/microsoft/azureml-inference-server/blob/main/azureml_inference_server_http/amlserver.py)

The `run` method calls the `amlserver_linux:run`

```python
# amlserver.py
srv.run(DEFAULT_HOST, int(os.environ[ENV_PORT]), int(os.environ[ENV_WORKER_COUNT]))
srv.run("0.0.0.0", 31311, 1)

# amlserver_linux.py
run(host, port, worker_count, health_port=None)

sys.argv =
[
    "/var/mlflow_resources/mlflow_score_script.py", # Or gunciorn
    "-b", "0.0.0.0:31311",     # Bind to the port
    "-w", "1",                 # Number of workers
    "--timeout", "300",        # Worker timeout (30 seconds)
    "--access-logfile", "-",   # Access log output to stdout
    "--error-logfile", "/dev/null"  # Discard error logs
    "-b",  "127.0.0.1:9999",    # Bind to the health port
    "azureml_inference_server_http.server.entry:app"
]

# Start gunicorn with args
# TODO Better understand this line
gunicorn.app.wsgiapp.WSGIApplication("%(prog)s [OPTIONS] [APP_MODULE]").run()
# similar to
# gunicorn -b 0.0.0.0:31311 -w 1 --timeout 300 --access-logfile - --error-logfile /dev/null azureml_inference_server_http.server.entry:app

# Points back to flask app defined in azureml_inference_server_http.server.entry:app

# loads configs in server/config.py AMLInferenceServerConfig

```

```bash
$ gunicorn --help
usage: gunicorn [OPTIONS] [APP_MODULE]

options:
  -h, --help            show this help message and exit
  -v, --version         show program's version number and exit
  -c CONFIG, --config CONFIG
                        :ref:`The Gunicorn config file<configuration_file>`. [./gunicorn.conf.py]
  -b ADDRESS, --bind ADDRESS
                        The socket to bind. [['127.0.0.1:8000']]
  --backlog INT         The maximum number of pending connections. [2048]
  -w INT, --workers INT
                        The number of worker processes for handling requests. [1]
  -k STRING, --worker-class STRING
                        The type of workers to use. [sync]
  --threads INT         The number of worker threads for handling requests. [1]
  --worker-connections INT
                        The maximum number of simultaneous clients. [1000]
  --max-requests INT    The maximum number of requests a worker will process before restarting. [0]
  --max-requests-jitter INT
                        The maximum jitter to add to the *max_requests* setting. [0]
  -t INT, --timeout INT
                        Workers silent for more than this many seconds are killed and restarted. [30]
  --graceful-timeout INT
                        Timeout for graceful workers restart. [30]
  --keep-alive INT      The number of seconds to wait for requests on a Keep-Alive connection. [2]
  --limit-request-line INT
                        The maximum size of HTTP request line in bytes. [4094]
  --limit-request-fields INT
                        Limit the number of HTTP headers fields in a request. [100]
  --limit-request-field_size INT
                        Limit the allowed size of an HTTP request header field. [8190]
  --reload              Restart workers when code changes. [False]
  --reload-engine STRING
                        The implementation that should be used to power :ref:`reload`. [auto]
  --reload-extra-file FILES
                        Extends :ref:`reload` option to also watch and reload on additional files [[]]
  --spew                Install a trace function that spews every line executed by the server. [False]
  --check-config        Check the configuration and exit. The exit status is 0 if the [False]
  --print-config        Print the configuration settings as fully resolved. Implies :ref:`check-config`. [False]
  --preload             Load application code before the worker processes are forked. [False]
  --no-sendfile         Disables the use of ``sendfile()``. [None]
  --reuse-port          Set the ``SO_REUSEPORT`` flag on the listening socket. [False]
  --chdir CHDIR         Change directory to specified directory before loading apps. [/home/dockeruser]
  -D, --daemon          Daemonize the Gunicorn process. [False]
  -e ENV, --env ENV     Set environment variables in the execution environment. [[]]
  -p FILE, --pid FILE   A filename to use for the PID file. [None]
  --worker-tmp-dir DIR  A directory to use for the worker heartbeat temporary file. [None]
  -u USER, --user USER  Switch worker processes to run as this user. [1000]
  -g GROUP, --group GROUP
                        Switch worker process to run as this group. [1000]
  -m INT, --umask INT   A bit mask for the file mode on files written by Gunicorn. [0]
  --initgroups          If true, set the worker process's group access list with all of the [False]
  --forwarded-allow-ips STRING
                        Front-end's IPs from which allowed to handle set secure headers. [127.0.0.1]
  --access-logfile FILE
                        The Access log file to write to. [None]
  --disable-redirect-access-to-syslog
                        Disable redirect access logs to syslog. [False]
  --access-logformat STRING
                        The access log format. [%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"]
  --error-logfile FILE, --log-file FILE
                        The Error log file to write to. [-]
  --log-level LEVEL     The granularity of Error log outputs. [info]
  --capture-output      Redirect stdout/stderr to specified file in :ref:`errorlog`. [False]
  --logger-class STRING
                        The logger you want to use to log events in Gunicorn. [gunicorn.glogging.Logger]
  --log-config FILE     The log config file to use. [None]
  --log-config-json FILE
                        The log config to read config from a JSON file [None]
  --log-syslog-to SYSLOG_ADDR
                        Address to send syslog messages. [udp://localhost:514]
  --log-syslog          Send *Gunicorn* logs to syslog. [False]
  --log-syslog-prefix SYSLOG_PREFIX
                        Makes Gunicorn use the parameter as program-name in the syslog entries. [None]
  --log-syslog-facility SYSLOG_FACILITY
                        Syslog facility name [user]
  -R, --enable-stdio-inheritance
                        Enable stdio inheritance. [False]
  --statsd-host STATSD_ADDR
                        The address of the StatsD server to log to. [None]
  --dogstatsd-tags DOGSTATSD_TAGS
                        A comma-delimited list of datadog statsd (dogstatsd) tags to append to []
  --statsd-prefix STATSD_PREFIX
                        Prefix to use when emitting statsd metrics (a trailing ``.`` is added, []
  -n STRING, --name STRING
                        A base to use with setproctitle for process naming. [None]
  --pythonpath STRING   A comma-separated list of directories to add to the Python path. [None]
  --paste STRING, --paster STRING
                        Load a PasteDeploy config file. The argument may contain a ``#`` [None]
  --proxy-protocol      Enable detect PROXY protocol (PROXY mode). [False]
  --proxy-allow-from PROXY_ALLOW_IPS
                        Front-end's IPs from which allowed accept proxy requests (comma separate). [127.0.0.1]
  --keyfile FILE        SSL key file [None]
  --certfile FILE       SSL certificate file [None]
  --ssl-version SSL_VERSION
                        SSL version to use (see stdlib ssl module's). [_SSLMethod.PROTOCOL_TLS]
  --cert-reqs CERT_REQS
                        Whether client certificate is required (see stdlib ssl module's) [VerifyMode.CERT_NONE]
  --ca-certs FILE       CA certificates file [None]
  --suppress-ragged-eofs
                        Suppress ragged EOFs (see stdlib ssl module's) [True]
  --do-handshake-on-connect
                        Whether to perform SSL handshake on socket connect (see stdlib ssl module's) [False]
  --ciphers CIPHERS     SSL Cipher suite to use, in the format of an OpenSSL cipher list. [None]
  --paste-global CONF   Set a PasteDeploy global config variable in ``key=value`` form. [[]]
  --strip-header-spaces
                        Strip spaces present between the header name and the the ``:``. [False]
  --permit-unconventional-http-method
                        Permit HTTP methods not matching conventions, such as IANA registration guidelines [False]
  --permit-unconventional-http-version
                        Permit HTTP version not matching conventions of 2023 [False]
  --casefold-http-method
                        Transform received HTTP methods to uppercase [False]
  --header-map HEADER_MAP
                        Configure how header field names are mapped into environ [drop]
  --tolerate-dangerous-framing
                        Process requests with both Transfer-Encoding and Content-Length [False]
```

# References

- https://github.com/microsoft/azureml-inference-server
