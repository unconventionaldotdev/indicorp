FROM getindico/indico:latest

# Copy built wheels into the image
# TODO: build the wheels in a multi-stage Docker build instead
COPY --chown=indico:indico dist/. /opt/indico/dist/

# Copy config files
COPY --chown=indico:indico etc/. /opt/indico/etc/

# Install wheels
RUN /opt/indico/.venv/bin/pip install /opt/indico/dist/*.whl
