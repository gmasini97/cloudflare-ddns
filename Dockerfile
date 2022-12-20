FROM rust:1.66.0 as builder
WORKDIR /root/app/
COPY src ./src
COPY Cargo.toml .
RUN cargo install --path .
RUN echo $(ls -lh /usr/local/cargo/bin/cfddns)
CMD ls -lh /usr/local/cargo/bin/cfddns

# FROM debian:buster-slim
# RUN apt-get update && apt-get install -y extra-runtime-dependencies && rm -rf /var/lib/apt/lists/*
# COPY --from=builder /usr/local/cargo/bin/myapp /usr/local/bin/myapp
# CMD ["myapp"]