# reference: https://medium.com/@albertazzir/blazing-fast-python-docker-builds-with-poetry-a78a66f5aed0
FROM python:3.12.0-bookworm AS builder

RUN pip install poetry==1.8.3

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

COPY pyproject.toml ./

RUN poetry install --without dev,eval,test --no-root && rm -rf $POETRY_CACHE_DIR

# -------- Runtime stage --------
FROM python:3.12.0-slim-bookworm AS runtime

RUN apt-get update && apt-get install -y netcat-traditional

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

# Copiamos el entorno virtual construido en la etapa anterior
COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# --- código de la aplicación ---
COPY src src                 
COPY src/config.yaml src/    

COPY entrypoint.sh /app/entrypoint.sh
COPY pyproject.toml pyproject.toml

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
