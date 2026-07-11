#!/bin/sh
# automated smoke test for the fauxmo container
# builds the image, starts it with a single CommandLinePlugin device and asserts
# fauxmo actually comes up and serves the WeMo setup.xml for that device.
#
# this test is the guard that lets us keep 'FROM alpine' (unpinned/latest) in the
# Dockerfile: if a future alpine/python/fauxmo bump breaks startup or the HTTP
# emulation, this fails instead of silently publishing a broken image.
set -eu

IMAGE=fauxmo-test
NAME=fauxmo-test-run
DEVICE_PORT=49915
DEVICE_NAME="test device"

FAILED=0
fail() {
  echo "FAIL: $*" >&2
  FAILED=1
}

cleanup() {
  echo ">> cleanup: removing container $NAME"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

echo ">> building image $IMAGE"
docker build -t "$IMAGE" .

echo ">> (re)starting container $NAME"
docker rm -f "$NAME" >/dev/null 2>&1 || true
# minimal one-device config via env: a CommandLinePlugin device on DEVICE_PORT.
# the on/off/state commands are no-ops (true) - we only care that fauxmo starts
# and serves the WeMo HTTP emulation for the device.
docker run -d --name "$NAME" \
  -e FAUXMO_PLUGIN_COMMANDLINE_DEVICE_1_test="{ \"name\": \"$DEVICE_NAME\", \"port\": $DEVICE_PORT, \"on_cmd\": \"true\", \"off_cmd\": \"true\", \"state_cmd\": \"true\" }" \
  "$IMAGE"

echo ">> waiting for fauxmo to start (up to ~40s)"
READY=0
i=0
while [ "$i" -lt 20 ]; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
    echo "!! container is not running anymore, dumping logs:" >&2
    docker logs "$NAME" >&2 2>&1 || true
    fail "container exited during startup"
    break
  fi
  # fauxmo up AND the device port is listening
  if docker exec "$NAME" sh -c 'ps aux | grep -q "[f]auxmo"' 2>/dev/null \
     && docker exec "$NAME" sh -c "netstat -ltn 2>/dev/null | grep -q ':$DEVICE_PORT '" 2>/dev/null; then
    READY=1
    break
  fi
  i=$((i + 1))
  sleep 2
done

if [ "$READY" -ne 1 ] && [ "$FAILED" -eq 0 ]; then
  echo "!! fauxmo did not come up in time, dumping logs:" >&2
  docker logs "$NAME" >&2 2>&1 || true
  fail "timed out waiting for fauxmo / device port"
fi

# only run the deeper assertions if the container is still up
if docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then

  echo ">> assert: container is running"
  docker ps --format '{{.Names}}' | grep -q "^${NAME}$" \
    && echo "ok - container running" || fail "container not running"

  echo ">> assert: config.json was generated with our device"
  if docker exec "$NAME" grep -q "$DEVICE_NAME" /etc/fauxmo/config.json; then
    echo "ok - /etc/fauxmo/config.json contains the device"
  else
    fail "generated config.json is missing the device"
  fi

  echo ">> assert: fauxmo python process present"
  if docker exec "$NAME" sh -c 'ps aux | grep -q "[f]auxmo"'; then
    echo "ok - fauxmo process running"
  else
    fail "fauxmo process not found"
  fi

  echo ">> assert: device HTTP port $DEVICE_PORT is listening"
  if docker exec "$NAME" sh -c "netstat -ltn 2>/dev/null | grep -q ':$DEVICE_PORT '"; then
    echo "ok - port $DEVICE_PORT listening"
  else
    fail "device port $DEVICE_PORT not listening"
  fi

  # fauxmo binds to the container's resolved interface IP ("ip_address": "auto"),
  # not 127.0.0.1, so probe the actual bound address from inside the container.
  echo ">> assert: device serves WeMo setup.xml over HTTP"
  SETUP=$(docker exec "$NAME" sh -c "curl -s -i \"http://\$(hostname -i):$DEVICE_PORT/setup.xml\"" 2>/dev/null || true)
  if echo "$SETUP" | grep -q '200 OK' \
     && echo "$SETUP" | grep -q 'urn:Belkin:device:controllee' \
     && echo "$SETUP" | grep -q "$DEVICE_NAME"; then
    echo "ok - setup.xml served (WeMo/Belkin emulation responding for '$DEVICE_NAME')"
  else
    echo "!! unexpected setup.xml response:" >&2
    echo "$SETUP" >&2
    fail "device did not serve a valid WeMo setup.xml"
  fi

  echo ">> assert: fauxmo identifies itself as Fauxmo in HTTP headers"
  if echo "$SETUP" | grep -qi 'X-User-Agent: Fauxmo'; then
    echo "ok - X-User-Agent: Fauxmo header present"
  else
    fail "missing 'X-User-Agent: Fauxmo' header"
  fi

fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "SOME TESTS FAILED"
  exit 1
fi
