ARG fromTag=3.11
ARG imageRepo=alpine

FROM ${imageRepo}:${fromTag} AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=7.0.0
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-alpine-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-lts

# Download the Linux tar.gz and save it
# ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz
RUN wget -O /tmp/linux.tar.gz ${PS_PACKAGE_URL}
# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

# Unzip the Linux tar.gz
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER} -v

# Start a new stage so we lose all the tar.gz layers from the final image
FROM ${imageRepo}:${fromTag}

ARG fromTag=3.11

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

# Define Args and Env needed to create links
ARG PS_INSTALL_VERSION=7-lts
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Alpine-${fromTag}


# Install Terraform
ENV TERRAFORM_VERSION=0.12.16
RUN wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install dotnet dependencies and ca-certificates
RUN apk add --no-cache \
    ca-certificates \
    less \
    \
    # PSReadline/console dependencies
    ncurses-terminfo-base \
    \
    # .NET Core dependencies
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    #extra stuff
    curl \
    jq \
    vim \
    python3 \
    python3-dev  \
    ansible \
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
    less \
    expect \
    qemu-img \
    figlet \
    pigz \
    && apk -X http://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust \
    \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    \
    # Create the pwsh-preview symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview \
    # Give all user execute permissions and remove write permissions for others
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    # Upgrade pip
    && pip3 install --no-cache-dir --upgrade pip \
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

ADD ./vmware-ovftool /usr/lib/vmware-ovftool
RUN cd /tmp && \
    unzip terraform.zip -d /usr/bin && \
    wget -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub &&\
    wget -O /tmp/glibc-2.31-r0.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk &&\
    apk add /tmp/glibc-2.31-r0.apk &&\
    chmod +x /usr/lib/vmware-ovftool/ovftool* &&\
    ln -s /usr/lib/vmware-ovftool/ovftool /usr/bin/ovftool &&\
    echo "set mouse-=a" > /root/.vimrc &&\
    export PATH="/usr/local/go/bin:$PATH" &&\
    go get -u github.com/vmware/govmomi/govc &&\
    mv /root/go/bin/govc /usr/bin &&\
    pwsh-preview -noni -c "Install-Module -Force -Name VMware.PowerCLI" > /dev/null 2>&1 &&\
    rm -rf /tmp/* && \
    rm -rf /root/go && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/*
