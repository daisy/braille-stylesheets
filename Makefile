EPUB := Leonie_Martin.epub Hope_V1.4.epub
CSS := $(patsubst %.epub,%.scss,$(EPUB))
OBFL := $(patsubst %.epub,obfl/%.obfl,$(EPUB))
BRF := $(patsubst %.epub,result/%_vol-1.brf,$(EPUB))
PIPELINE_VERSION := 1.15.1
MOUNT_POINT := /mnt
PORT=8181

.PHONY : run-testsuite
run-testsuite : $(BRF)

dp2 =                                                                           \
	test "$$(                                                                   \
	    docker container inspect -f '{{.State.Running}}' pipeline 2>/dev/null   \
	)" = true;                                                                  \
	docker_mode=$$?;                                                            \
	if [ $${docker_mode} = 0 ]; then                                            \
	    network_option="--link pipeline";                                       \
	    host_option="--host http://pipeline";                                   \
	    mount_point="$(MOUNT_POINT)";                                           \
	else                                                                        \
	    network_option="--network host";                                        \
	    host_option="--host http://localhost";                                  \
	    mount_point="$(CURDIR)";                                                \
	fi &&                                                                       \
	eval                                                                        \
	docker run --name cli                                                       \
	           --rm                                                             \
	           $${network_option}                                               \
	           -v "'$(CURDIR):$${mount_point}:rw'"                              \
	           --entrypoint /opt/daisy-pipeline2/cli/dp2                        \
	           daisyorg/pipeline:$(PIPELINE_VERSION)                            \
	           $${host_option}                                                  \
	           --starting false                                                 \
	           '$1';

$(BRF) : result/%_vol-1.brf : obfl/%.obfl
	if [[ "$<" -nt "$@" ]]; then                                                     \
	    rm -f $@ $(patsubst result/%_vol-1.brf,result/%_vol-*.brf,$@) &&             \
	    $(call dp2, obfl-to-pef --persistent                                         \
	                            --output "$${mount_point}"                           \
	                            --source "$${mount_point}/$<"                        \
	                            --output-file-format "(locale:en-US)(pad:BEFORE)"    \
	                            --allow-text-overflow-trimming true)                 \
	    if ! [ -e "$@" ]; then                                                       \
	        exit 1;                                                                  \
	    else                                                                         \
	        touch $(patsubst result/%_vol-1.brf,result/%_vol-*.brf,$@);              \
	    fi                                                                           \
	fi

$(OBFL) : obfl/%.obfl : %.epub %.scss xavier-society.scss bana.scss | pipeline-up
	rm -f $@ $(patsubst obfl/%.obfl,result/%_vol-*.brf,$@) &&                     \
	$(call dp2, epub3-to-pef --persistent                                         \
	                         --include-obfl true                                  \
	                         --output "$${mount_point}"                           \
	                         --source "$${mount_point}/$<"                        \
	                         --output-file-format "(locale:en-US)(pad:BEFORE)"    \
	                         --stylesheet "$${mount_point}/$(word 2,$^)"          \
	                         --stylesheet-parameters "(                           \
	                           reuse-print-toc: true,                             \
	                           maximum-number-of-sheets: 70,                      \
	                           allow-volume-break-inside-leaf-section-factor: 5,  \
	                           prefer-volume-break-before-higher-level-factor: 0  \
	                         )")                                                  \
	if ! [ -e "$(patsubst obfl/%.obfl,result/%_vol-1.brf,$@)" ]; then             \
	    exit 1;                                                                   \
	else                                                                          \
	    touch $(patsubst obfl/%.obfl,result/%_vol-*.brf,$@);                      \
	fi

$(CSS) : | xavier-society.scss
xavier-society.scss : | bana.scss

local_main_branch = $(shell git remote show origin | grep 'pushes to main ' | sed -e 's/  *//' -e 's/ .*//')
LOCAL_MAIN_BRANCH = $(eval LOCAL_MAIN_BRANCH := $$(local_main_branch))$(LOCAL_MAIN_BRANCH)

bana.scss :
	MAIN_BRANCH=$(LOCAL_MAIN_BRANCH);          \
	MAIN_BRANCH=$${MAIN_BRANCH:-origin/main};  \
	git checkout $${MAIN_BRANCH} -- bana/$@;   \
	git restore --staged bana/$@
	mv bana/$@ $@
	[ "$(ls -A bana)" ] || rm -r bana

.PHONY : get-latest-bana-css
get-latest-bana-css :
	$(MAKE) -B bana.scss

Leonie_Martin.epub :
	curl -L "https://github.com/PaulXSB/Daisy-Pipeline-UEB/raw/refs/heads/main/Leonie%20Martin/L%C3%A9onie%20Martin%20Remediated.epub" -o $@

.PHONY : clean
clean :
	rm -rf result obfl

.PHONY : pipeline-up
pipeline-up :
	if ! curl localhost:$(PORT)/ws/alive >/dev/null 2>/dev/null;        \
	then                                                                \
	    docker run --platform linux/amd64                               \
	               --name pipeline                                      \
	               -d                                                   \
	               -e PIPELINE2_WS_HOST=0.0.0.0                         \
	               -e PIPELINE2_WS_PORT=$(PORT)                         \
	               -e PIPELINE2_WS_LOCALFS=true                         \
	               -e PIPELINE2_WS_AUTHENTICATION=false                 \
	               -p $(PORT):$(PORT)                                   \
	               -v "$(CURDIR):$(MOUNT_POINT):rw"                     \
	               daisyorg/pipeline:$(PIPELINE_VERSION) &&             \
	    sleep 5 &&                                                      \
	    tries=3 &&                                                      \
	    while ! curl localhost:$(PORT)/ws/alive >/dev/null 2>/dev/null; \
	    do                                                              \
	        if [[ $$tries > 0 ]]; then                                  \
	            echo "Waiting for web service to be up..." >&2;         \
	            sleep 5;                                                \
	            (( tries-- ));                                          \
	        else                                                        \
	            echo "Gave up waiting for web service" >&2;             \
	            docker logs pipeline;                                   \
	            $(MAKE) pipeline-down;                                  \
	            exit 1;                                                 \
	        fi                                                          \
	    done                                                            \
	fi

.PHONY : pipeline-down
pipeline-down :
	docker stop pipeline;  \
	docker rm pipeline

.PHONY : log
log : pipeline.log
pipeline.log ::
	docker logs pipeline > $@
