# Образ на основе которого будет создан контейнер
FROM --platform=linux/amd64 ubuntu:18.04

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
    GROUPS="admin,root" \
    # Выбор time zone
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Moscow \
    # Задание версий сервисов
    JAVA_VERSION=8

ENV \
    # Задание домашних директорий
    HOME=/home/${USER} \
    JAVA_HOME=/usr/lib/jvm/java 

ENV \
    # Обновление переменных путей
    PATH=${JAVA_HOME}/bin:${PATH} \
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
    apt --yes update && \
    # Установка timezone
    apt install --no-install-recommends --yes tzdata && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    # Установка языкового пакета
    apt install --no-install-recommends --yes locales && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen  && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Установка базовых пакетов
    # --------------------------------------------------------------------------
    apt install --no-install-recommends --yes apt-utils && \
    apt install --no-install-recommends --yes curl && \
    apt install --no-install-recommends --yes software-properties-common && \
    apt install --no-install-recommends --yes netcat && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Установка Java
    # --------------------------------------------------------------------------
    # Install OpenJDK
    apt install --no-install-recommends --yes openjdk-${JAVA_VERSION}-jdk && \
    # Создание символической ссылки на Java
    ln -s /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64 /usr/lib/jvm/java && \
    # Smoke test
    java -version && \
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
    # Директория entrypoint
    mkdir -p ${ENTRYPOINT_DIRECTORY} && \
    chown -R ${USER}:${GID} ${ENTRYPOINT_DIRECTORY} && \
    chmod -R a+rx ${ENTRYPOINT_DIRECTORY} && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Подготовка shell-скриптов
    # --------------------------------------------------------------------------
    # Ожидание запуска сервиса
    echo \
'''#!/bin/bash \n\
function wait_for_it() { \n\
    local serviceport=$1 \n\
    local service=${serviceport%%:*} \n\
    local port=${serviceport#*:} \n\
    local retry_seconds=5 \n\
    local max_try=100 \n\
    let i=1 \n\
    nc -z $service $port \n\
    result=$? \n\
    until [ $result -eq 0 ]; do \n\
      echo "[$i/$max_try] check for ${service}:${port}..." \n\
      echo "[$i/$max_try] ${service}:${port} is not available yet" \n\
      if (( $i == $max_try )); then \n\
        echo "[$i/$max_try] ${service}:${port} is still not available; giving up after ${max_try} tries. :/" \n\
        exit 1 \n\
      fi \n\
      echo "[$i/$max_try] try in ${retry_seconds}s once again ..." \n\
      let "i++" \n\
      sleep $retry_seconds \n\
      nc -z $service $port \n\
      result=$? \n\
    done \n\
    echo "[$i/$max_try] $service:${port} is available." \n\
} \n\
for i in ${SERVICE_PRECONDITION[@]} \n\
do \n\
    wait_for_it ${i} \n\
done \n\
''' > ${ENTRYPOINT_DIRECTORY}/wait_for_it.sh && \
    cat ${ENTRYPOINT_DIRECTORY}/wait_for_it.sh && \
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # Настройка прав доступа скопированных файлов/директорий
    # --------------------------------------------------------------------------
    # Директория/файл entrypoint
    chown -R ${USER}:${GID} ${ENTRYPOINT_DIRECTORY} && \
    chmod -R a+x ${ENTRYPOINT_DIRECTORY} && \
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

# Выбор рабочей директории
WORKDIR ${WORK_DIRECTORY}

# Точка входа
ENTRYPOINT ["/bin/bash"]
