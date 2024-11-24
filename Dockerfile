FROM rust:bookworm AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y build-essential libasound2-dev libpulse-dev git
WORKDIR /src
RUN git clone https://github.com/librespot-org/librespot.git librespot
WORKDIR /src/librespot
RUN cargo fetch 
RUN cargo build --release --no-default-features --features pulseaudio-backend,with-libmdns

ARG VERSION="666"
RUN git pull --rebase # Make sure we have the latest changes; do this after ARG is declared so we bust cacheing
# Now bake the build version into package.version in Cargo.toml and Cargo.lock and build again.
# Use 'sed' to edit lines 'version = "0.6.0-dev"' with 'version = "0.6.0-dev-${VERSION}"' in both Cargo.toml and Cargo.lock at the same time.
RUN sed -i "s/version = \"0.6.0-dev\"/version = \"0.6.0-dev-build-${VERSION}\"/g" Cargo.lock $(find . -name Cargo.toml)
RUN git diff
RUN cargo build --release --no-default-features --features pulseaudio-backend,with-libmdns

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libpulse0 ca-certificates pamixer && rm -rf /var/lib/apt/lists/* && apt-get clean
COPY --from=builder /src/librespot/target/release/librespot /usr/local/bin/librespot
RUN /usr/local/bin/librespot --version
RUN /usr/local/bin/librespot --help
CMD ["/usr/local/bin/librespot", "--bitrate", "320", "--name", "librespot", "--device-type", "speaker", "--backend", "pulseaudio"]
