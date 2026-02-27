# Probe server (target): distroless Python 3, minimal HTTP server on 8081
FROM gcr.io/distroless/python3-debian12
COPY probe_server.py /app/
WORKDIR /app
CMD ["/app/probe_server.py"]
