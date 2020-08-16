CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := cloud-events-orchestration-http
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /tekton/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /tekton/home/basic-auth-pass.json)

init:
	helm init --client-only

setup: init
	helm repo add jenkins-x http://chartmuseum.jenkins-x.io
	helm repo add zeebe http://helm.zeebe.io
	helm repo add releases ${CHART_REPO}

build: clean setup
	helm dependency build cloud-events-orchestration-http
	helm lint cloud-events-orchestration-http

install: clean build
	helm upgrade ${NAME} cloud-events-orchestration-http --install

upgrade: clean build
	helm upgrade ${NAME} cloud-events-orchestration-http --install

delete:
	helm delete --purge ${NAME} cloud-events-orchestration-http

clean:
	rm -rf cloud-events-orchestration-http/charts
	rm -rf cloud-events-orchestration-http/${NAME}*.tgz
	rm -rf cloud-events-orchestration-http/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" cloud-events-orchestration-http/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" cloud-events-orchestration-http/Chart.yaml
else
	exit -1
endif
	helm package cloud-events-orchestration-http
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
	jx step changelog  --verbose --version $(VERSION) --rev $(PULL_BASE_SHA)
