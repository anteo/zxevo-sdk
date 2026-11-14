PYTHON ?= python3
TEST_RUNNER := ../../../tools/test_runner/runner.py

.PHONY: test build list clean
test build list:
	@$(PYTHON) $(TEST_RUNNER) common $(if $(filter test,$@),check,$@)

clean:
	$(PYTHON) -B $(TEST_RUNNER) common clean
	rm -rf -- build
