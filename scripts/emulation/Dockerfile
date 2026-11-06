# Image du banc d'émulation mémoire : un « faux boîtier » x86 dont la mémoire
# est bridée par Docker (--memory) à ce que la box laisse vraiment à Linux.
# Chromium n'est pas installé ici : lancer.sh monte celui de Playwright.
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      xvfb ffmpeg python3 procps fonts-dejavu-core \
      libgtk-3-0t64 libegl1 libgles2 libgl1 libgbm1 \
      libnss3 libatk-bridge2.0-0t64 libasound2t64 libxkbcommon0 \
      libxcomposite1 libxdamage1 libxrandr2 libpango-1.0-0 libcups2t64 \
      libdrm2 libxshmfence1 \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /banc
ENTRYPOINT ["python3", "-u", "/banc/banc.py"]
