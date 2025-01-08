# DB_project
Экзаминационный проект по базам данных.

## Запуск

- Создать в корне проекта файл с переменными среды `.env` и таким содержимым:

```
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=CoffeeDB
MYSQL_USER=webapp
MYSQL_PASSWORD=webapppwd
DB_PORT=3306
WEBAPP_PORT=8080
PHPMYADMIN_PORT=80
```

- `sudo docker compose build`
- `sudo docker compose up`

Теперь сервисы тусуются тут:

- http://127.0.0.1:6001/ -- mysql
- http://127.0.0.1:6002/ -- webapp
- http://127.0.0.1:6003/ -- phpmyadmin
