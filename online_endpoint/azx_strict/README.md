# Deploy a strict custom container

```bash
conda env list
# conda environments:
#
base                  *  /opt/miniconda
amlenv                   /opt/miniconda/envs/amlenv
userenv                  /opt/miniconda/envs/userenv

printenv
CONDA_EXE=/opt/miniconda/bin/conda
_CE_M=
HOSTNAME=b0158f8b5c70
XML_CATALOG_FILES=file:///opt/miniconda/etc/xml/catalog file:///etc/xml/catalog
WORKER_TIMEOUT=300
AZUREML_MODEL_DIR=/var/azureml-app/azureml-models
PWD=/
AZUREML_CONDA_ENVIRONMENT_PATH=/opt/miniconda/envs/userenv
CONDA_PREFIX=/opt/miniconda
AZUREML_INFERENCE_SERVER_HTTP_ENABLED=True
HOME=/home/dockeruser
LANG=C.UTF-8
LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:
CONDA_ENV_DIR=/opt/miniconda/envs
SVDIR=/var/runit
CONDA_PROMPT_MODIFIER=(base)
TERM=xterm
_CE_CONDA=
CONDA_SHLVL=1
SHLVL=1
CONDA_PYTHON_EXE=/opt/miniconda/bin/python
LD_LIBRARY_PATH=/opt/miniconda/envs/userenv/lib:
CONDA_DEFAULT_ENV=base
LC_ALL=C.UTF-8
PATH=/opt/miniconda/bin:/opt/miniconda/condabin:/opt/miniconda/envs/userenv/bin:/opt/miniconda/envs/amlenv/bin:/opt/miniconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
DEBIAN_FRONTEND=noninteractive
_=/usr/bin/printenv
```

```bash
base_path=./online_endpoint/azx_strict
dockerfile_path="$base_path/Dockerfile"
image_name="online_endpoint/azx_strict:latest"
artifact_path="./artifacts/iris_model"

# Build image
docker build --build-arg "ARG_ARTIFACT_PATH=$artifact_path" --build-arg "ARG_BASE_PATH=$base_path" -t "$image_name" -f "${dockerfile_path}" .

# Run container
docker run -p 5001:5001 -p 31311:31311 "$image_name"

# Interactive shell
docker run -it --entrypoint /bin/bash -p 5001:5001 -p 31311:31311  "$image_name"
# Start service in container
# $ exec azmlinfsrv --entry_script /var/azureml-app/score.py --port 31311
./tmp/entrypoint.sh

# Connect to running image
docker exec -it $(docker ps --filter "ancestor=$image_name"  -q ) /bin/bash

# Check liveness
curl -p 127.0.0.1:5001
curl --header "Content-Type: application/json" --request GET http://localhost:5000/

# Check prediction
curl -p 127.0.0.1:5001/score --data "{'data': [[5.1, 3.5, 1.4, 0.2]]}"
curl --header "Content-Type: application/json" --request POST --data @"${artifact_path}/input_example.json" http://localhost:5001/score

```
