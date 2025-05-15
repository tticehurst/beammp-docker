FROM debian:bookworm-slim AS build

WORKDIR /build

RUN apt-get update && \
    apt-get install -y curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    LATEST_VERSION=$(curl -s https://api.github.com/repos/BeamMP/BeamMP-Server/releases/latest | jq -r .tag_name) && \
    BASE_OS=$(awk -F= '/^ID=/{gsub(/"/,""); print $2}' /etc/os-release || echo debian) && \
    BASE_VERSION=$(awk -F= '/^VERSION_ID=/{gsub(/"/,""); print $2}' /etc/os-release || echo 12) && \
    CURRENT_ARCH=$(uname -m | sed 's/aarch64/arm64/') && \
    echo "Latest version: ${LATEST_VERSION}" && \
    DOWNLOAD_URL="https://github.com/BeamMP/BeamMP-Server/releases/download/${LATEST_VERSION}/BeamMP-Server.${BASE_OS}.${BASE_VERSION}.${CURRENT_ARCH}" && \
    echo "Downloading ${DOWNLOAD_URL}" && \
    curl -fsSL -o BeamMP-Server "${DOWNLOAD_URL}" && \
    chmod +x BeamMP-Server


RUN test -f /build/BeamMP-Server
RUN test -x /build/BeamMP-Server

# # # # #
#	Runner
# # # # #
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends liblua5.3-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /server
RUN mkdir -p Resources/{Server,Client}

VOLUME ["/beammp/Resources/Server", "/beammp/Resources/Client"]

COPY --from=build /build/BeamMP-Server ./beammp-server
COPY entrypoint.sh .

# Create non-root user and set permissions in one layer
RUN useradd -u 1000 -M beammp && \
    chown -R beammp:beammp /server && \
    chmod +x /server/beammp-server /server/entrypoint.sh

USER beammp
ENTRYPOINT ["/server/entrypoint.sh"]

EXPOSE 30814
