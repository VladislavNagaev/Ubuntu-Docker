# Ubuntu Docker

Base Docker image for building big data tools from Apache: Hadoop, Hive, Spark, Livy and so on.

Build image:
~~~
make --jobs=$(nproc --all) --file Makefile 
~~~

## Technologies
---
Project is created with:
* Ubuntu verion: 18.04
* Java version: OpenJDK 8
* Docker verion: 20.10.22
* Docker-compose version: v2.11.1
