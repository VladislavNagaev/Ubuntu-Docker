# Образ на основе которого будет создан контейнер
FROM --platform=linux/amd64 ubuntu:22.04

LABEL maintainer="Vladislav Nagaev <vladislav.nagaew@gmail.com>"

# Изменение рабочего пользователя
USER root

# Выбор рабочей директории
WORKDIR /

ENV \ 
    # Задание переменных пользователя
    USER=admin \
    UID=1001 \
    GROUP=admin \
    GID=1001 \
    GROUPS="admin,root,sudo" \
    # Выбор time zone
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Moscow \
    # Директория пользовательских приложений
    APPS_HOME=/opt \
    # Задание версий сервисов
    JAVA_VERSION=8

ENV \
    # Задание домашних директорий
    HOME=/home/${USER} \
    JAVA_HOME=/usr/lib/jvm/java 

ENV \
    # Обновление переменных путей
    PATH=${PATH}:${JAVA_HOME}/bin \
    # Задание директорий 
    WORK_DIRECTORY=/workspace \
    LOG_DIRECTORY=/tmp/logs \
    ENTRYPOINT_DIRECTORY=/entrypoint

RUN \
    # --------------------------------------------------------------------------
    # Базовая настройка операционной системы
    # --------------------------------------------------------------------------
    # Создание группы и назначение пользователя в ней
    groupadd --gid ${GID} --non-unique ${GROUP} && \
    useradd --system --create-home --home-dir ${HOME} --shell /bin/bash --gid ${GID} --groups ${GROUPS} --uid ${UID} ${USER} && \
    # Замена ссылок на зеркало (https://launchpad.net/ubuntu/+archivemirrors)
    sed -i 's/htt[p|ps]:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/mirror.truenetwork.ru\/ubuntu/g' /etc/apt/sources.list && \
    # Обновление путей
    apt -y update && \
    # Установка timezone
    apt install -y tzdata && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    # Установка языкового пакета
    apt install -y locales && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen  && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Установка базовых пакетов
    # --------------------------------------------------------------------------
    apt install -y apt-utils && \
    echo Y | apt install -y curl && \
    echo Y | apt install -y wget && \
    apt install -y unzip && \
    apt install -y ssh && \
    apt install -y pdsh && \
    apt install -y gettext-base && \
    apt install -y netcat && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Установка C compiler (GCC)
    # --------------------------------------------------------------------------
    echo Y | apt install -y build-essential && \
    apt install -y manpages-dev && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Установка Java
    # --------------------------------------------------------------------------
    # Install OpenJDK
    apt install -y openjdk-${JAVA_VERSION}-jdk && \
    # Install Apache Ant
    apt install -y ant && \
    # Создание символической ссылки на Java
    ln -s /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64 /usr/lib/jvm/java && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Подготовка директорий
    # --------------------------------------------------------------------------
    # Директория логов
    mkdir -p ${LOG_DIRECTORY} && \
    chown -R ${USER}:${GID} ${LOG_DIRECTORY} && \
    chmod -R a+rw ${LOG_DIRECTORY} && \
    # Рабочая директория
    mkdir -p ${WORK_DIRECTORY} && \
    chown -R ${USER}:${GID} ${WORK_DIRECTORY} && \
    chmod -R a+rwx ${WORK_DIRECTORY} && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Очистка кэша
    # --------------------------------------------------------------------------
    rm -rf /var/lib/apt/lists/*
    # --------------------------------------------------------------------------

ENV \
    # Выбор языкового пакета
    LC_CTYPE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Точка входа
ENTRYPOINT ["/bin/bash"]
