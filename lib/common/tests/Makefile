PYTHON ?= python3

.PHONY: test build list clean
test build list:
	$(PYTHON) run.py $(if $(filter test,$@),check,$@)

clean:
	$(PYTHON) -B run.py clean
