.PHONY: up down restart logs build status backup update

PODMAN ?= podman
COMPOSE ?= $(PODMAN) compose
IMAGE_NAME ?= localhost/windrose-ds:stable

# Start the server (build image if needed)
up:
	$(MAKE) build
	IMAGE_NAME=$(IMAGE_NAME) $(COMPOSE) up -d

# Stop the server gracefully
down:
	$(COMPOSE) stop

# Restart the server
restart:
	$(COMPOSE) down && IMAGE_NAME=$(IMAGE_NAME) $(COMPOSE) up -d

# Follow live logs
logs:
	$(COMPOSE) logs -f windrose

# Build image only
build:
	$(PODMAN) build --pull=missing -t $(IMAGE_NAME) .

# Container status + health
status:
	$(COMPOSE) ps

# Manual backup of saves
backup:
	tar --warning=no-file-changed -czf windrose-backup-$$(date +%F-%H%M).tar.gz data/R5/Saved
	@echo "Backup saved: windrose-backup-$$(date +%F-%H%M).tar.gz"

# Force game update (stops, re-downloads, starts)
update:
	$(COMPOSE) stop
	$(COMPOSE) run --rm windrose /opt/steamcmd/steamcmd.sh \
		+force_install_dir /data \
		+login anonymous \
		+app_update 4129620 validate \
		+quit
	IMAGE_NAME=$(IMAGE_NAME) $(COMPOSE) up -d

# Show server invite code
invite:
	@grep -o '"InviteCode": "[^"]*"' data/R5/ServerDescription.json || echo "Server not yet started — run 'make up' first"
