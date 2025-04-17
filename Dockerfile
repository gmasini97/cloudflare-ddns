# FROM alpine:3.18 AS build
FROM --platform=linux/amd64 alpine:3.21 AS build

ENV ZIG_VERSION=0.13.0

ARG TARGETPLATFORM
RUN echo "Building for $TARGETPLATFORM"

WORKDIR /root/build
COPY . .

# RUN ash .devcontainer/install-requirements.sh
# RUN mkdir /zigtmp
# RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then ash .devcontainer/install-zig.sh /zigtmp x86_64 0.13.0; fi
# RUN if [ "$TARGETPLATFORM" = "linux/arm/v7" ] ; then ash .devcontainer/install-zig.sh /zigtmp armv7a 0.13.0; fi
# RUN zig build -Doptimize=ReleaseSmall

RUN apk add --no-cache zig
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then zig build -Doptimize=ReleaseSmall; fi
RUN if [ "$TARGETPLATFORM" = "linux/arm/v7" ] ; then zig build -Doptimize=ReleaseSmall -Dtarget=arm-linux -Dcpu=generic+v7a+strict_align+thumb2; fi



FROM --platform=$TARGETPLATFORM alpine:3.21
COPY --from=build /root/build/zig-out/bin/cfddns /app/cfddns
# COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["/app/cfddns"]


