FROM rust:1.75-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git ca-certificates pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Optional network install (disabled by default for restricted environments).
ARG INSTALL_KG_FROM_GITLAB=0
RUN if [ "$INSTALL_KG_FROM_GITLAB" = "1" ]; then \
      cargo install --locked --git https://gitlab.com/gitlab-org/rust/knowledge-graph.git knowledge-graph; \
    else \
      echo "Skipping knowledge-graph install during build (INSTALL_KG_FROM_GITLAB=0)"; \
    fi

COPY scripts/run-kag.sh /usr/local/bin/run-kag.sh
RUN chmod +x /usr/local/bin/run-kag.sh

ENTRYPOINT ["/usr/local/bin/run-kag.sh"]
