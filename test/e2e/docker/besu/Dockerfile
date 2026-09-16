# Nó Besu QBFT da rede local de testes.
# A imagem base traz o Besu; o entrypoint resolve o bootnode e monta a linha de
# comando a partir das variáveis de ambiente definidas no docker-compose.yml.
FROM hyperledger/besu:26.7.1

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# O volume nomeado de /data é inicializado a partir da imagem quando está vazio,
# herdando esta propriedade. Sem isso o volume nasce root e o Besu não escreve.
RUN mkdir -p /data && chown besu:besu /data

USER besu
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
