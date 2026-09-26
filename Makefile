# Football Agent — dev loop
#
#   make dev      both halves at once (API on :8000, web on :3000)
#   make api      just the FastAPI service
#   make web      just the Next.js dev server
#   make dev-pwa-phone  browser PWA over this Mac's LAN (the native app needs no server)
#   make test     engine + API tests

.PHONY: dev dev-pwa-phone api web test
PYTHON ?= $(if $(wildcard .venv/bin/python),.venv/bin/python,python3)

api:
	$(PYTHON) -m uvicorn api.main:app --reload --port 8000 --host 127.0.0.1 --workers 1

web:
	cd web && npm run dev

dev:
	@$(MAKE) api & $(MAKE) web & wait

dev-pwa-phone:
	@$(MAKE) api & (cd web && npm run dev -- --hostname 0.0.0.0) & wait

test:
	$(PYTHON) -m pytest tests/ -q
