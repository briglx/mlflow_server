# Server App

The server app runs on an MLFlow server and is triggered when a new artifact is registered. The client triggers the GitHub CICD pipeline with the model artifact details.

- Configure a GitHub App. See [Creating GitHub Apps](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app)

```bash
# Optional - load .env vars
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Run the server app code
model_name="$MODEL_NAME"
model_version="$MODEL_VERSION"
python ./server_app/main.py --model_name "$model_name" --model_version "$model_version"
```

# References

- https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app
