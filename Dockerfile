FROM ubuntu:bionic

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PHP
RUN apt-get update \
    && apt-get install -y \
    php \
    php-cli \
    php-common \
    php-curl \
    php-mysql \
    php-intl \
    curl \
    php-pear \
    php-dev \
    php-xml \
    libmcrypt-dev \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pecl install mcrypt-1.0.1

# Install MSSQL for PHP
RUN apt-get update -yqq && apt-get install -y apt-transport-https \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update -yqq \

# Install Dependencies
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc unixodbc-dev \

# Install pdo_sqlsrv and sqlsrv from PECL. Replace pdo_sqlsrv-4.1.8preview with preferred version.
    &&  pecl install sqlsrv pdo_sqlsrv \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update \
    && apt-get install apache2 libapache2-mod-php -y \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get update \
    && apt-get install mysql-common mysql-server mysql-client -y \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update \
    && apt-get install -y git nano tree sudo dnsmasq dnsutils supervisor iputils-ping unzip \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mkdir -p /var/log/supervisor
RUN sudo /bin/su -c "echo \"user=root\" >> /etc/dnsmasq.conf"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates socat \
    && apt-get install -y --no-install-recommends xvfb x11vnc fluxbox xterm \
    && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /usr/bin

#INSTALL NPM

RUN apt-get update && apt-get install -y php-mbstring php-zip && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - && apt-get install -y nodejs

RUN echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
    && sudo apt-get update && sudo apt-get install yarn -y \
    && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /var/www

VOLUME /dev/shm

WORKDIR /var/www

EXPOSE 80 9515 5900 3306 443

# COPY SCRIPTS
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY . /usr/sbin
RUN chmod +x /usr/sbin/docker-php-ext-enable
RUN /usr/sbin/docker-php-ext-enable pdo_sqlsrv sqlsrv
RUN chmod +x /usr/sbin/entry_point.sh
COPY entry_point.sh /usr/bin/boot_services
RUN chmod +x /usr/bin/boot_services

COPY server.crt /etc/apache2/ssl/server.crt
COPY server.key /etc/apache2/ssl/server.key
COPY dev.conf /etc/apache2/sites-enabled/dev.conf
RUN a2enmod rewrite
RUN a2enmod ssl

CMD ["/bin/sh", "-c", "/usr/sbin/entry_point.sh > /var/www/boot.log"]
