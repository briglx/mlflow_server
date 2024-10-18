FROM mcr.microsoft.com/azureml/minimal-ubuntu22.04-py39-cpu-inference:latest
WORKDIR /app
COPY ./online_endpoint/score.py /app
RUN python -m pip install azureml-inference-server-http
EXPOSE 5000
CMD ["azmlinfsrv", "--entry_script", "score.py", "--port", "5000"]
# CMD ["bash"]
