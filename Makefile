.DEFAULT_GOAL := help

.PHONY: help prerequisites cluster-create argocd-install bootstrap verify service-a-check lint validate destroy

help:
	@echo "Targets: prerequisites cluster-create argocd-install bootstrap verify service-a-check lint validate destroy"

prerequisites:
	@./scripts/check-prerequisites.sh

cluster-create:
	@./bootstrap/kind/create-cluster.sh

argocd-install:
	@./bootstrap/argocd/install.sh

bootstrap:
	@./scripts/bootstrap-platform.sh

verify:
	@./scripts/verify-platform.sh

service-a-check:
	@./scripts/check-service-a.sh

lint:
	@./scripts/lint.sh

validate:
	@./scripts/validate.sh

destroy:
	@./bootstrap/destroy.sh
