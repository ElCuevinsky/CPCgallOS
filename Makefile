.PHONY: build password validate clean

build:
	./scripts/run-build-container.sh

password:
	docker build --quiet -t cpcgallos-builder:26.04 . >/dev/null
	docker run --rm -it cpcgallos-builder:26.04 grub-mkpasswd-pbkdf2

validate:
	./scripts/validate.sh

clean:
	@echo "Elimina manualmente work/, .cache/ u out/ según lo que quieras regenerar."
