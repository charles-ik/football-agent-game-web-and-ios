# Football Agent — dev loop
#
#   make dev      both halves at once (API on :8000, web on :3000)
#   make api      just the FastAPI service
#   make web      just the Next.js dev server
#   make dev-ios  both halves, reachable by the iPhone app on this Mac's LAN
#   make test     engine + API tests

.PHONY: dev dev-ios api web test
PYTHON ?= $(if $(wildcard .venv/bin/python),.venv/bin/python,python3)

api:
	$(PYTHON) -m uvicorn api.main:app --reload --port 8000 --host 127.0.0.1 --workers 1

web:
	cd web && npm run dev

dev:
	@$(MAKE) api & $(MAKE) web & wait

dev-ios:
	@$(MAKE) api & (cd web && npm run dev -- --hostname 0.0.0.0) & wait

test:
	$(PYTHON) -m pytest tests/ -q
