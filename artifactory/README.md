# Artifactory

## Container Registry Option

Steps to install Artifactory JCR on an Azure VM

```bash
# Create vm - Debian bullseye/sid 11
ssh -i ~/.ssh/id_rsa "azureuser@${ARTIFACTORY_VM_IP}"

# Install gnupg for keys
sudo apt-get update
sudo apt install gnupg
sudo apt install nginx

# Configure nginx
cat artifactory.nginx.conf >> /etc/nginx/sites-available/artifactory
sudo ln -s /etc/nginx/sites-available/artifactory.nginx.conf /etc/nginx/sites-enabled/artifactory.nginx.conf
sudo nginx -t # verify configuration
sudo systemctl stop nginx
sudo systemctl start nginx
sudo systemctl restart nginx
# verify nginx is running
curl -I -k -v "http://${ARTIFACTORY_VM_IP}/access/api/v1/system/ping"

# Install artifactory jcr
distribution=bullseye
wget -qO - https://releases.jfrog.io/artifactory/api/gpg/key/public | sudo apt-key add -;
echo "deb https://releases.jfrog.io/artifactory/artifactory-debs $distribution main" | sudo tee -a /etc/apt/sources.list;
sudo apt-get update && sudo apt-get install jfrog-artifactory-jcr

systemctl status artifactory.service
systemctl start artifactory.service

# Test setup
registry_host="${ARTIFACTORY_VM_IP}:8082"
curl -I -k -v "http://${registry_host}/api/system/ping"

# Success!!
# navigate to http://${ARTIFACTORY_VM_IP}:8082 or http://${ARTIFACTORY_VM_IP}
```

## Artifactory Option

### Artifactory Pro
Steps to provision trial pro version of artifactory on local machine with docker.

Find the latest version at [https://jfrog.com/download-legacy/](https://jfrog.com/download-legacy/)

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

project_root="$PROJECT_PATH"
sub_project_root="${project_root}/artifactory"
JFROG_HOME="${project_root}/artifactory/home"
image_name="artifactory-pro"
artifactory_version="7.84.17"

mkdir -p $JFROG_HOME/artifactory/var/etc/
cd $JFROG_HOME/artifactory/var/etc/
touch ./system.yaml
sudo chown -R 1030:1030 $JFROG_HOME/artifactory/var

cd "$sub_project_root"
docker run --name artifactory -v $JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory -d -p 8081:8081 -p 8082:8082 "releases-docker.jfrog.io/jfrog/artifactory-pro:$artifactory_version"

#Success!!
# Navigate to http://localhost:8082

```

### Artifactory OSS

Steps to provision and deploy Artifactory OSS (Open Source Software) on Azure Container instances.

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Build image
project_root="$PROJECT_PATH"
sub_project_root="${project_root}/artifactory"
dockerfile_path="${project_root}/artifactory/Dockerfile"
image_name="artifactory-oss"

JFROG_HOME="${project_root}/artifactory/home"
mkdir -p "$JFROG_HOME/artifactory/var/etc/"
cd "$JFROG_HOME/artifactory/var/etc/"
touch ./system.yaml
chown -R 1030:1030 "$JFROG_HOME/artifactory/var"

# docker run --name "$image_name" -v "$JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory" -d -p 8081:8081 -p 8082:8082 releases-docker.jfrog.io/jfrog/artifactory-oss:latest
docker run --name "$image_name" -v "./home/artifactory/var/:/var/opt/jfrog/artifactory" -d -p 8081:8081 -p 8082:8082 releases-docker.jfrog.io/jfrog/artifactory-oss:7.63.12
# Success!!
```

## Unsuccessful Options

### Custom Image
Test running with custom image

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Build image
project_root="$PROJECT_PATH"
sub_project_root="${project_root}/artifactory"
dockerfile_path="${project_root}/artifactory/Dockerfile"
image_name="artifactory-oss"

JFROG_HOME="${project_root}/artifactory/home"
mkdir -p "$JFROG_HOME/artifactory/var/etc/"
cd "$JFROG_HOME/artifactory/var/etc/"
touch ./system.yaml
chown -R 1030:1030 "$JFROG_HOME/artifactory/var"

cd "$sub_project_root"
docker build -t "$image_name" -f "${dockerfile_path}" "${project_root}"

# Run container
docker run -p 5000:5000 "$image_name"

# Interactive shell
docker run -it --entrypoint /bin/bash  -v "$JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory" -p 8081:8081 -p 8082:8082  "$image_name"

# Fails to load
```

### Azure Container Instance
Attempt to host artifactory as container on Azure Container Instances

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

az login --use-device-code --tenant "$AZURE_TENANT_ID"

# Create container
image_name="artifactory-oss"
image="releases-docker.jfrog.io/jfrog/artifactory-oss:latest"
JFROG_HOME=/opt/jfrog

az container create --resource-group "$ACI_RESOURCE_GROUP" \
    --name "$image_name" --image "$image" \
    --dns-name-label aci-demo --ports 80 \
    --environment-variables JFROG_HOME="$JFROG_HOME" \
    --azure-file-volume-share-name "$VOLUME_SHARE_NAME" \
    --azure-file-volume-account-name "$VOLUME_SHARE_ACCOUNT_NAME" \
    --azure-file-volume-account-key "$VOLUME_SHARE_ACCOUNT_KEY" \
    --azure-file-volume-mount-path "$JFROG_HOME"

# Fails to deploy
```

# Publish image to JFrog Container Registry

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Login to remote registry
registry_host="${ARTIFACTORY_VM_IP}"
# Configure Docker client to use http instead of https. See reference below
docker login -u "$ARTIFACTORY_USERNAME" -p "$ARTIFACTORY_PASSWORD"  "$registry_host"

namespace="aimodelserving"
image="dev.mlflow-sample-model-test_script_v4"
tag="2024.7.1.dev20240723T1400"
source_image="$image:$tag"
target_image="${registry_host}/${namespace}/${image}:${tag}"

docker tag "$source_image" "$target_image"
docker push "$$target_image"
```

# References
* Installing Artifactory https://jfrog.com/help/r/jfrog-installation-setup-documentation/install-artifactory-single-node-with-docker
* Artifactory Release Notes https://jfrog.com/help/r/jfrog-release-information/artifactory-7.84?tocId=7KSaWMhZ7x9kMbH1ST4u5A
* Artifactory distribution https://releases.jfrog.io/artifactory/artifactory-debs/dists/
* Configure Nginx https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-debian-11
* JFrog Artifactory Reverse Proxy Settings https://jfrog.com/help/r/jfrog-artifactory-documentation/reverse-proxy-settings
* Configure Docker Client to use http instead of https https://docs.docker.com/reference/cli/dockerd/#on-linux
