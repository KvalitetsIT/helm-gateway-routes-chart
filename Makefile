all: lint docs

lint:
	docker run --rm --name chart-testing -w /data -v $(PWD):/data quay.io/helmpack/chart-testing:v3.14.0 ct lint --config /data/ct.yaml

docs:
	docker run --rm --name helm-docs -v "$(PWD):/helm-docs" jnorwood/helm-docs:v1.14.2 --sort-values-order file --chart-search-root charts/ --output-file README.md --values-file values-docs.yaml
