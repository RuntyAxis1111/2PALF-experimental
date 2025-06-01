#!/bin/bash
set -e

########################################
# VARIABLES ---------------------------
########################################
INTERVAL=1
TIMEOUT=60

# Railway → expone automáticamente $PORT.
# Si no existe (desarrollo local) usamos 8000.
SERVICE_PORT="${PORT:-8000}"

# Qdrant suele escuchar en 6333; permite sobre-escribirlo.
QDRANT_PORT="${QDRANT_PORT:-6333}"

########################################
# ESPERA A QDRANT ---------------------
########################################
echo "Waiting for qdrant to start on $QDRANT_HOST:$QDRANT_PORT …"
current=0
while ! nc -z "$QDRANT_HOST" "$QDRANT_PORT"; do
    sleep "$INTERVAL"
    current=$((current + INTERVAL))
    if [ "$current" -eq "$TIMEOUT" ]; then
        echo "Timeout: qdrant did not start within $TIMEOUT seconds"
        exit 1
    fi
done
echo "qdrant has started."

########################################
# ARRANCA WREN-AI-SERVICE -------------
########################################
uvicorn src.__main__:app \
        --host 0.0.0.0 \
        --port "$SERVICE_PORT" \
        --loop uvloop --http httptools &

########################################
# (OPCIONAL) FORCED DEPLOY ------------
########################################
if [[ -n "$SHOULD_FORCE_DEPLOY" ]]; then
    echo "Waiting for wren-ai-service to start on port $SERVICE_PORT …"
    current=0
    while ! nc -z localhost "$SERVICE_PORT"; do
        sleep "$INTERVAL"
        current=$((current + INTERVAL))
        if [ "$current" -eq "$TIMEOUT" ]; then
            echo "Timeout: wren-ai-service did not start within $TIMEOUT seconds"
            exit 1
        fi
    done
    echo "wren-ai-service has started."

    # Espera opcional a wren-ui (puerto configurado en $WREN_UI_PORT)
    echo "Waiting for wren-ui to start …"
    current=0
    while ! nc -z wren-ui "$WREN_UI_PORT" && \
          ! nc -z host.docker.internal "$WREN_UI_PORT"; do
        sleep "$INTERVAL"
        current=$((current + INTERVAL))
        if [ "$current" -eq "$TIMEOUT" ]; then
            echo "Timeout: wren-ui did not start within $TIMEOUT seconds"
            exit 1
        fi
    done
    echo "wren-ui has started."

    echo "Forcing deployment …"
    python -m src.force_deploy
fi

########################################
# MANTIENE EL PROCESO EN 1er PLANO ----
########################################
wait
