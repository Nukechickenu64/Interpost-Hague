FROM ubuntu:22.04

# Create workspace
RUN mkdir -p /marrow

# Enable 32-bit architecture for BYOND
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	 unzip make wget ca-certificates \
	 libc6:i386 libstdc++6:i386 libmariadb3:i386 \
 && rm -rf /var/lib/apt/lists/*

# Download and install BYOND (pinned)
WORKDIR /marrow
RUN wget -q https://www.byond.com/download/build/516/516.1669_byond_linux.zip \
 && unzip -q 516.1669_byond_linux.zip \
 && rm 516.1669_byond_linux.zip

# Copy source
COPY . /marrow/Marrow

# Build BYOND userland and compile the game
RUN /bin/bash -lc '\
cd /marrow/byond; \
make here >/dev/null; \
source bin/byondsetup; \
cd ../Marrow; \
ln -sf /usr/lib/i386-linux-gnu/libmariadb.so.3 libmariadb.so || true; \
DreamMaker Marrow.dme; \
'

# Default port (override with -p in docker run / compose)
EXPOSE 8000

# Run DreamDaemon
ENTRYPOINT bash -lc ". /marrow/byond/bin/byondsetup && cd /marrow/Marrow && DreamDaemon Marrow.dmb 8000 -invisible -trusted -logself"