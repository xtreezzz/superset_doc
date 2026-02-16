# Docker-шаблон для построения KAG по Apache Superset

Этот репозиторий поднимает контейнер для запуска `knowledge-graph` (GitLab Rust) и строит граф по исходникам `apache/superset`.

## Что внутри

- `Dockerfile` — сборка окружения Rust + опциональная установка `knowledge-graph`.
- `docker-compose.yml` — запуск пайплайна с volume.
- `scripts/run-kag.sh` — клонирует/обновляет Superset и запускает `KG_COMMAND`.
- `scripts/generate_fallback_kag.py` — fallback-генератор непустого JSON-графа из дерева файлов, если `knowledge-graph` недоступен.
- `.env.example` — переменные окружения.

## Почему раньше было пусто

Ранее в репозитории лежал `mock-kag.json` из тестовой команды, где граф был зашит как:

```json
{"nodes":[],"edges":[]}
```

Это не реальный результат `knowledge-graph`, а заглушка для проверки пайплайна.

## Быстрый старт

```bash
cp .env.example .env
```

### Онлайн режим (предпочтительно)

```bash
# при наличии доступа к gitlab.com/github.com
docker compose build --build-arg INSTALL_KG_FROM_GITLAB=1 kag
docker compose run --rm kag
```

### Оффлайн/ограниченная сеть

Если `knowledge-graph` не установлен, скрипт автоматически создаст fallback-граф в:

- `data/output/run-YYYYmmdd-HHMMSS/fallback-kag.json`

Запуск:

```bash
docker compose run --rm kag
```

## Где смотреть результаты

- `data/output/run-*/run.log`
- `data/output/run-*/target_repo_head.txt`
- `data/output/run-*/fallback-kag.json` (если сработал fallback)
- либо ваш файл из `KG_COMMAND`, если `knowledge-graph` доступен
