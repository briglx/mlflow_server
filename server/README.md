# MLFlow Server

Example project to show how to run an MLFlow tracking server and artifact store.

![Architecture Overview](./docs/architecture_overview.svg)

## Provision Server

Create a new VM in Azure and run the following commands to provision the server.

```bash
# Setup virtual environment and install dependencies
./script/setup.sh

# Start Dependencies
docker compose up -d

# Start MLFlow server
./script/start.sh
```

Configure systemd file `/etc/systemd/system/mlflow.service` to start the MLFlow server on boot.

```bash
sudo cp ./mlflow.service /etc/systemd/system/mlflow.service

# Start the service
sudo systemctl daemon-reload
sudo systemctl start mlflow
sudo systemctl enable mlflow

# Check the status
sudo systemctl start mlflow
sudo systemctl stop mlflow
sudo systemctl restart mlflow
sudo systemctl status mlflow
journalctl -u mlflow
```

## Tracking Server

Login to the tracking server `http://<TRACKING_SERVER_IP>:5000`

```bash
# SSH into the Tracking Server
ssh -i ~/.ssh/id_rsa azureuser@$TRACKING_SERVER_IP
```
