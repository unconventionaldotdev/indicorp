FROM getindico/indico:latest

ARG pip="${INDICO_VIRTUALENV}/bin/pip"

# Copy built wheels into the image
# TODO: build the wheels in a multi-stage Docker build instead
COPY --chown=indico:indico dist/. /opt/indico/dist/

# Copy config files
COPY --chown=indico:indico etc/. /opt/indico/etc/

# Install wheels
RUN set -ex && \
    python -m venv ${INDICO_VIRTUALENV} && \
    ${pip} install /opt/indico/dist/*.whl
