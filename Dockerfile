FROM rust:bookworm AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y build-essential libasound2-dev libpulse-dev git
WORKDIR /src
RUN git clone https://github.com/librespot-org/librespot.git librespot
WORKDIR /src/librespot
RUN cargo fetch 
RUN cargo build --release --no-default-features --features pulseaudio-backend

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libpulse0 ca-certificates && rm -rf /var/lib/apt/lists/* && apt-get clean
COPY --from=builder /src/librespot/target/release/librespot /usr/local/bin/librespot
RUN /usr/local/bin/librespot --version
RUN /usr/local/bin/librespot --help
CMD ["/usr/local/bin/librespot", "--bitrate", "320", "--name", "librespot", "--device-type", "speaker", "--backend", "pulseaudio"]
