# Copyright (c) 2016-present Sonatype, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM       deepsecs/nexus3_ssl:3.3.1-01

MAINTAINER DeepSecs <13841495@qq.com>

RUN apt-get update \
  && apt-get install -y sudo \
  && apt-get clean

ENV NEXUS_VOLUMN="/dev/nexus"

USER root

COPY ["start-container.bash","/"]
RUN ["chmod","755","/start-container.bash"]

RUN echo "nexus ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/nexus
RUN echo "127.0.0.1	deepsecs.com" > /etc/hosts

USER nexus
WORKDIR ${NEXUS_HOME}

# CMD ["bin/nexus", "run"]
ENTRYPOINT ["/start-container.bash"]
