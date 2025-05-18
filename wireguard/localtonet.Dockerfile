FROM ubuntu:25.04

# Setup workspace
WORKDIR /

# Install dependencies
RUN apt-get update \
 && apt-get install -y \
  libicu66 \
  unzip \
  bash \
  wget

# Download and install localtonet
RUN wget https://localtonet.com/download/localtonet-linux-x64.zip
RUN unzip localtonet-linux-x64.zip
RUN chmod 744 localtonet

# Set entrypoint
ENTRYPOINT [ "./localtonet" ]
