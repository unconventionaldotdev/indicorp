FROM ghcr.io/astral-sh/uv:python3.12-bookworm AS builder

# install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

ENV NVM_DIR=/root/.nvm

COPY / /opt/indicorp

WORKDIR /opt/indicorp

RUN <<EOF
. $NVM_DIR/nvm.sh
nvm install
uv venv

# After having assets on plugin side we can start using simply `make deps`
make deps-py
make deps-core-js

uv run indico/bin/maintenance/build-wheel.py plugin --no-git /opt/indicorp/
EOF

FROM getindico/indico:latest

# Copy built wheels into the image
COPY --chown=indico:indico --from=builder /opt/indicorp/dist/. /opt/indico/dist/

# Copy config files
COPY --chown=indico:indico etc/. /opt/indico/etc/

# Install wheels
RUN <<EOF
/opt/indico/.venv/bin/pip install /opt/indico/dist/*.whl
/opt/indico/.venv/bin/pip cache purge
EOF
