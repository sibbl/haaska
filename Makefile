
SHELL := /bin/bash

# Function name in AWS Lambda:
FUNCTION_NAME=haaska

BUILD_DIR=build

haaska.zip: haaska.py config/*
	mkdir -p $(BUILD_DIR)
	cp $^ $(BUILD_DIR)
	pip install -t $(BUILD_DIR) requests
	cd $(BUILD_DIR); zip ../$@ -r *

.PHONY: deploy
deploy: haaska.zip
	aws lambda update-function-configuration \
		--function-name $(FUNCTION_NAME) \
		--handler haaska.event_handler
	aws lambda update-function-code \
		--function-name $(FUNCTION_NAME) \
		--zip-file fileb://$<

TEST_PAYLOAD:='                                \
{                                              \
  "header": {                                  \
    "payloadVersion": "2",                     \
    "namespace": "Alexa.ConnectedHome.System", \
    "name": "HealthCheckRequest"               \
  },                                           \
  "payload": {                                 \
    "accessToken": "..."                       \
  }                                            \
}'

.PHONY: test
test:
	@aws lambda invoke \
		--function-name $(FUNCTION_NAME) \
		--payload ${TEST_PAYLOAD} \
		/dev/fd/3 3>&1 >/dev/null | jq -e '., .payload.isHealthy'

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) haaska.zip

