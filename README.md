# Docker-шаблон для построения KAG по Apache Superset

Этот репозиторий поднимает контейнер для запуска `knowledge-graph` (GitLab Rust) и строит граф по исходникам `apache/superset`.

## Что внутри

- `Dockerfile` — сборка окружения Rust + опциональная установка `knowledge-graph`.
- `docker-compose.yml` — запуск пайплайна с volume для исходников и артефактов.
- `scripts/run-kag.sh` — клонирует/обновляет Superset и запускает `KG_COMMAND`.
- `.env.example` — переменные окружения.

## Быстрый старт

1. Скопируйте env-файл:

```bash
cp .env.example .env
```

2. В `.env` задайте команду `KG_COMMAND` под актуальный CLI:

- https://gitlab-org.gitlab.io/rust/knowledge-graph/

3. Соберите контейнер.

Если есть доступ к GitLab из вашей сети, можно сразу установить `knowledge-graph` при сборке:

```bash
docker compose build --build-arg INSTALL_KG_FROM_GITLAB=1 kag
```

Если доступа нет — соберите без установки и добавьте бинарник другим способом:

```bash
docker compose build kag
```

4. Запустите:

```bash
docker compose run --rm kag
```

5. Результаты каждого запуска лежат в отдельной папке:

- `./data/output/run-YYYYmmdd-HHMMSS/`

## Локальный тест пайплайна (без сети)

Чтобы проверить только механику скрипта в оффлайне, можно использовать локальный репозиторий и пропустить clone:

```bash
SKIP_CLONE=1 TARGET_REPO_DIR=/workspace/superset_doc OUTPUT_DIR=/workspace/superset_doc/data/output KG_COMMAND='echo demo > /workspace/superset_doc/data/output/demo.txt' bash scripts/run-kag.sh
```

## Примечания

- Если `knowledge-graph` отсутствует в `PATH`, скрипт завершится с кодом ошибки и создаст `kag_status.txt` с подсказкой в папке запуска.
- При необходимости можно добавить отдельный сервис `neo4j` в `docker-compose.yml` для импорта графа.
