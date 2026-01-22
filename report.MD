##  Part 1. Docker Compose ##
### Создание докерфайлов:  
Ознакомившись со структурой предложенного микросервисного приложения, перешел к написанию докерфайлов, для создания образов.  

Предоставленные микросервисы можно собрать разными методами, на примере одного сервиса описал и сравнил эти подходы:  
**1. Локальная сборка jar-пакетов.**  
В данном случае сборка происходит локально, на хосте и используется менеджер пакетов Maven и его обертка mvnw, находящаяся в папке с каждым сервисом. Сборка запускается командой: `./mvnw package -DskipTests` После этого полученный jar-файл в сгенерированной папке target и будет являться тем самым исполняемым файлом.  
После того как получил исполняемый файл, копирую его внутрь контейнера и запускаю его командой `java -jar target/*.jar`.  
Инструкция рекомендует использовать как базовый образ **openjdk:8-jdk-alpine**  

Обновив apt и установил необходимый пакет: **openjdk-8-jdk**:
- Java 8 - стабильная, широко используемая в enterprise  
- Java 11 - LTS версия, более современная  
- Java 17 - текущая LTS версия  

Но так как мне предлагается 8 версия, а так же она указана в файле `pom.xml` в разделе properties. Использую именно этот пакет.  
Сборка на хосте:  
![mvnw](./img/mvn_package.png)  
После сборки:  
![target](./img/mvn_build-succes.png)  

После этого написал Dockerfile:  
![target](./img/dockerfile_booking.png)  
![size](./img/dockerfile_booking-build.png)  

**2. Сборка внутри Docker**  
Для этого создаю рабочую директорию внутри образа и копирую туда все файлы, необходимые для сборки, а затем уже собраю внутри образа.  
Dockerfile выглядит так:  
![target](./img/dockerfile_booking-build-in-docker.png)  

![size](./img/dockerfile_booking-build-in-docker-build.png)  

**3. Multi-stage build**  
Использую несколько "стадий" (stages) в одном Dockerfile, где каждая стадия выполняет свою роль, но в финальный образ попадает только последняя (минимальная).  
Dockerfile:  
![target](./img/dockerfile_booking-multi-stage-docker.png)  
Здесь я представил две стадии build (сборка исполнительного файла) и start (запуск необходимого файла и скрипта).  
**Первая** стадия использует образ **openjdk:8-jdk-alpine** копирует необходимые файлы, и собирает проект аналогично сборке на хосте (1 метод).  
**Вторая** стадия использует более легковесный образ **openjdk:8-jre-alpine**, т.к необходим только запуск. Далее забирает полученный исполнительный файл (оставляя все не нужное), а так же копирует скрипт `wait-for-it.sh`  
![size](./img/dockerfile_booking-multi-stage-docker-build.png)  

Теперь сравню размеры образа трех случаев:  
![images](./img/images-sizes.png)  
**Вывод:** метод с multi-stage сборкой образа является самым приемлемым, такой образ имеет наименьший размер. Поэтому для всех необходимых остальных сервисов использую этот подход.  

### Создание докерфайлов:  
Создал аналогичные dockerfile для каждого сервиса.  
![Dockerfile](./img/dockerfile_gateway-service.png)  

![Dockerfile](./img/dockerfile_session-service.png)  
В ходе тестов докефайл изменил, исправив CMD и используя ограничение памяти для сервисов. 

Все файлы находятся в дириктории `src/services/*service-name*/Dockerfile` 

### Написание docker-compose.yaml 
Написал докеркомпос с необходимыми сервисами от db до gateway-service. Используя все необходимые зависимости и переменные окружения. 
Так же добавил helthcheck и ограничил ресурсы ram для java сервисов.
Ниже представлен фрагемент файла docker-compose.yaml:  
![Docker-compose](./img/docker-compose.png)  
Файл по пути `src/docker-compose.yaml` 


Запускаем написанный docker-compose:  
![docker-compose up](./img/docker-compose-up.png)  

![docker-compose up](./img/docker-compose-up_2.png)  

Все контейнеры запущены и работают:  
![docker-compose up](./img/docker-compose-up_3.png)  


### Тесты
Запустил заготовленные тесты в Postman. Все тесты прошли успешно.  
![Postman tests](./img/postman-test-1.png)

##  Part 2. Создание виртуальных машин ##
### Создание ВМ:
Установил virtualbox, и Vagrant:  
![vagrant + virtualbox](./img/vagrant_virtualbox.png)  
После установки командой `vagrant init` инициализирую проект. Таким образом создастся файл **Vagrantfile** в котором буду описывать парамметры для виртуальных машин. А так же монтирование директории с исходным кодом и исключением ненужных файлов.  
Минимальный файл:  
![vagrantfile](./img/vagrantfile-1.png)  
Запустил командой `vagrant up --provider=virtualbox` с явным указанием провайдера (т.к в моей системе поумолчанию пытается создавать и использованием libvirt)  
![vagrant up](./img/vagrant-up-1.png)  

### Действия внутри ВМ:
Машина создалась, чему свидетельствует вывод команды `vagrant status` и интерфейс VirtualBox. А так же машина доступна по ssh.  
![vagrant WS](./img/vagrant-status-1.png)  

Подключившись по SSH проверил присутствие нужной дириктории и файлов:  
Содержимое моего репозитория присутствует на ВМ по указанному пути:  
![vagrant WS](./img/files-on-ws.png)  

Далее остановил ВМ командой `vagrant halt`, а затем уничтожил `vagrant destroy`  
![vagrant WS](./img/vagrant-halt-and-destroy.png)  

## Part 2.1. Дополнительная автоматизация с Ansible ##
В дополнение к использованию Vagrant и Bash-скриптов,
реализовал автоматизацию конфигурации узлов
с помощью Ansible.  
Ansible используется для удалённой подготовки worker-узлов
и запуска микросервисного приложения без ручного подключения по SSH.  

### Подготовка manager для удаленного конфигурирования:  
С помощью ssh подключился к `manager` и проверил доступность `node01`:  
![manager ssh](./img/vagrant_manager-ssh_1.png)  

После чего сгенерировал ключ и скопировал его на машину `node01` в `~/.ssh/authorized_keys` и проверил **подключение к node01 из manager (без passphrase)**  
![manager ssh](./img/vagrant_manager-ssh_2.png)  

Исходный код микросервисов и docker-compose.yaml
скопировал на manager-узел для дальнейшего развертывания.  

Установил Ansible на менеджер и подготовил папку ansible, в которой будет inventory-файл.  
![ansible install](./img/manager-instal-ansible.png)  
![ansible install](./img/manager-instal-ansible_2.png)  

Написал миниальный `ansible/inventory.ini`   
![inventory-файл](./img/ansible_inventory-file.png)  
И провел проверки подключения через Ansible, используя модуль ping:  
![ansible ping](./img/ansible_ping-module.png)    

### Ansible-плейбук подготовки и запуска приложения: 
Написал минимальный `/home/vagrant/app` который обновляет список пакетов, устанавливает docker и docker-compose,добаавляет пользователя vagrant в необходимую группу а так же копирует необходимые файлы.  
![ansible playbook](./img/ansible_first-playbook.png)  
После выполнения плейбука подключился на node02 и проверил утсановлен ли docker, созданы дириктории и скопированы ли файлы.  
![ansible playbook](./img/ansible_first-playbook-2.png)  
После чего уже добавил запуск микросервисного приложения и проверку работоспособности контейнеров.  
Фрагмент а добавленными задачами:  
![ansible playbook](./img/ansible_first-playbook-plus.png)  
 - Скачивание образов в docekrhub.
 - Запуск приложения из docker-compose.yaml.
 - Таймер ожидания запуска всех контейнеров.
 - Проверки статуса контейнеров, отображает вывод `docker ps`. 
Запускаю плэйбук:  
![ansible playbook](./img/ansible_first-playbook-done.png)  

Прогнал заготовленные тесты через postman:  
![Postman tests](./img/postman_tests-1.png)  
В результате выполнение плейбука позволило полностью
автоматизировать развёртывание микросервисного приложения
на удалённых узлах без ручного вмешательства.  

##  Part 3. Создание Docker Swarm
### Подготовка инфраструктуры:
Подготовил необходимые скрипты:  
`scritps/docker.sh` для установки docker на ВМ:  
![script docker](./img/script_docker-install.png)  
Скрипт отключает предупреждения от apt, после выполнения так же выводит версии установленных компанентов, добавляет пользователя в группу docker, и включает автозапуск.  
`scripts/docker-swarm-init.sh` скрипт для инициализации и подключения к Docker Swarm:  
![script docker](./img/script_docker-swarm-init.png)  
Скрипт в зависимости от имени ВМ либо инициализирует менеджер, либо подключает воркер. (Исходя из vagrantfile сначала создает менеджер и инициализируется, а за тем уже воркеры)  

Далее изменил Vagrantfile для создания трех машин: manager01, worker01, worker02:  
![vagrantfile](./img/vagrantfile-2.png)  
Добавил статические адреса, имена, для машин, а так же запуск скриптов, и различные выделенные ресусы.  

Запустил описанные ВМ командой `vagrant up`  
![docker installing](./img/script-on-WS_docker-install.png)  
В выводе отображен процесс установки docker и включение автозапуска.  
![vagrant WS](./img/vagrant-status-2.png)  


Подключаюсь к ВМ **manager01** для вывода списка всех узлов командой `docker node ls`  
![swarm nodes](./img/manager_docker-nodes.png)  
Видно что все три ВМ подключены в один кластер.
## Part 4. Запуск в инфраструктуре ##  
### Редактирование docker-compose:
Уже имеющиеся образы я запушил в docker hub:  
![docker push](./img/docker-hub-push.png)  

Все образы появились на странице:  
![docker hub](./img/docker-hub.png)  

Когда выгрузил все образы, отредактировал файл `docker-compose.yaml`  
![Docker-compose](./img/docker-compose-2.png)  
После этих изменений, при запуске контейнер не собирает образ, а берет готовый образ из репозитория. Благодаря этому, для запуска приложения достаточно лишь файла docker-compose.yaml  

Копирую новый **docker-compose.yaml** на узел manager01 используя `upload`:  
![docker-compose](./img/vagrant-upload-docker.png)


### Запуск сервисов:
Подключившись к машине `vagrant ssh manager01` ввел команду: 
`sudo docker node update --availability drain manager01` Эта команда переводит узел manager01 в состояние Drain, теперь Docker Swarm перестает назначать новые задачи (контейнеры сервисов Swarm) на этот узел.  
![manager](./img/docker-swarm-manager-1.png)  
manager01 остается узлом-менеджером кластера и продолжает выполнять свои управленческие функции (обеспечение кворума, оркестрация, маршрутизация). Он просто больше не используется как рабочий (worker) узел для размещения сервисных контейнеров.

После этого запускаю микросервисное приложение командой `docker stack deploy -c docker-compose.yaml app`  
И проверяю запустились ли необходимые контейнеры:  
![docker stack](./img/docker-stack-deploy.png) 
 
![manager](./img/docker-node_ps.png)  


## Part 5. Прокси на базе nginx:  
Мои решением стало запуск отдельного контейнера с nginx на manager01.  
Сначала настроил проброс портов в vagrantfile, добавив:  
`manager.vm.network "forwarded_port", guest: 8081, host: 8081, auto_correct: true`  
`manager.vm.network "forwarded_port", guest: 8087, host: 8087, auto_correct: true`  
Из `docker-compose.yaml` удалил проброс портов у сервисов session и gateway, чтобы они не были доступны напрямую. 
и перезапустил командой `vagrant reload`

Подготовил конфиг для nginx:  
![nginx start](./img/nginx-up.png)  
Написал файл docker-compose-proxy.yaml для запуска ngixn  
![docker-compose proxy](./img/docker-compose-proxy.png)  
Указав уже существующую оверлей сеть `app_default` что бы мой стэк c proxy был в той же сети что и приложение.
![stack app + proxy](./img/restart-stack.png)  

## Part 6. Тестирование  ##
###  Postman тесты:  
Остановив стек с прокси проверил что тесты не проходят (что свидетельствует тому что сервисы не доступы на прямую)  
![Postman](./img/postman-test-filed.png)  
Запустил прокси и все тесты выполнились успешно:  
![Postman](./img/postman-test-ok.png)  

### Распределение контейнеров по узлам:  
Вывел информацию, о том что есть два стэка (приложение и прокси), все сервисы запущены и работают, а так же распределение сервисов по нодам (разным ВМ):  
![docker stack](./img/docker-stack-ls.png)  
## Part 7. Portainer ##
### Portainer в кластере:  
Написал `docker-compose-portainer.yaml` для стека Portainer в которрый входят агенты и интерфейс:  
![docekr-compose portainer](./img/docker-compose-portainer.png)  

А так же изменил инстуркции для приложения, добавил ограничение, сервисы должны работать на воркерах (worker01 и worker02) что бы сделать manager01 актинвым.  
Запускаю все три стэка:  
![services up](./img/docker-all-service-up.png)
На скриншоте видно что некоторые сервисы перезапускались (app_rabbitmq)  
![services up](./img/docker-all-service-ps.png)  

Веб интерфейс от portainer:  
![postainer](./img/portainer-UI.png)  
Данные совпадают с выводом распределенния в консоли. 
