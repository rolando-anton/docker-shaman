# This Dockerfile is based in the official release of Microsoft for the PowerShell distribution for Alpine, plus the installation of other tools I need.
# 2020 - rolando@anton.sh

ARG fromTag=3.8
ARG imageRepo=alpine

FROM ${imageRepo}:${fromTag} AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=6.2.0-preview.3
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-alpine-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=6-preview

# Download the Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz

# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

# Unzip the Linux tar.gz
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER}

# Start a new stage so we lose all the tar.gz layers from the final image
FROM ${imageRepo}:${fromTag}

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

# Define Args and Env needed to create links
ARG PS_INSTALL_VERSION=6-preview
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache
# Install Terraform
ENV TERRAFORM_VERSION=0.12.16
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
ADD ${TERRAFORM_URL} /tmp/terraform.zip



# Install dependencies and other cool stuff
RUN apk update && \
    apk add curl \
    jq \
    figlet \
    vim \
    python \
    bash \
    openssl \
    git \
    unzip \
    wget \
    gcc \
    openssh-client \
    sshpass \
    musl-dev \
    openssl \
    go \
    ca-certificates \
    less \
    \
    # PSReadline/console dependencies
    ncurses-terminfo-base \
    \
    # .NET Core dependencies
    krb5-libs \
    libgcc \
    bash \
    libintl \
    libssl1.0 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust \
    \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    \
    # Create the pwsh-preview symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview \
    # intialize powershell module cache
    && pwsh \
        -NoLogo \
        -NoProfile \
        -Command " \
          \$ErrorActionPreference = 'Stop' ; \
          \$ProgressPreference = 'SilentlyContinue' ; \
          while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
            Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
            Start-Sleep -Seconds 6 ; \
          }"

# Define args needed only for the labels
ARG PS_VERSION=6.2.0-preview.2
ARG IMAGE_NAME=mcr.microsoft.com/powershell:preview-alpine-3.8
ARG VCS_REF="none"

# Add label last as it's just metadata and uses a lot of parameters
LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
    readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
    description="This Dockerfile will install the latest release of PowerShell." \
    org.label-schema.usage="https://github.com/PowerShell/PowerShell/tree/master/docker#run-the-docker-image-you-built" \
    org.label-schema.url="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
    org.label-schema.vcs-url="https://github.com/PowerShell/PowerShell-Docker" \
    org.label-schema.name="powershell" \
    org.label-schema.vendor="PowerShell" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.version=${PS_VERSION} \
    org.label-schema.schema-version="1.0" \
    org.label-schema.docker.cmd="docker run ${IMAGE_NAME} pwsh -c '$psversiontable'" \
    org.label-schema.docker.cmd.devel="docker run ${IMAGE_NAME}" \
    org.label-schema.docker.cmd.test="docker run ${IMAGE_NAME} pwsh -c Invoke-Pester" \
    org.label-schema.docker.cmd.help="docker run ${IMAGE_NAME} pwsh -c Get-Help"

# More extra stuff
RUN echo "set mouse-=a" > /root/.vimrc
RUN go get -u github.com/vmware/govmomi/govc
RUN mv /root/go/bin/govc /usr/bin
RUN pwsh-preview -noni -c "Install-Module -Force -Name VMware.PowerCLI" > /dev/null 2>&1

RUN cd /tmp && \
    unzip terraform.zip -d /usr/bin && \
    go get -u github.com/vmware/govmomi/govc && \
    mv /root/go/bin/govc /usr/bin && \
    rm -rf /tmp/* && \
    rm -rf /root/go && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/*
