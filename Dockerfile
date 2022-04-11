FROM quay.io/ibmgaragecloud/ibmcloud-dev:v2.0.4

RUN GRPC_HEALTH_PROBE_VERSION=v0.4.6 && wget -qO ./grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && chmod +x ./grpc_health_probe && sudo mv ./grpc_health_probe /usr/bin/grpc_health_probe

ENTRYPOINT ["/bin/sh"]
