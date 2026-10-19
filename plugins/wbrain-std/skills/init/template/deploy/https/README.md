# HTTPS público (opcional)

Componentes para servir domínios em HTTPS com certificados Let's Encrypt. Tudo fica nesta pasta e não depende do
projeto: a ligação é só o `https` do `config.yaml` (ver [docs/stack/deploy.md](../../docs/stack/deploy.md#https-público-opcional)).

| Arquivo | Papel |
|---|---|
| `docker-compose.https.yml` | Serviços `https-proxy` e `cert-renewer`. Anexado ao compose só com `https.enabled: true` |
| `proxy/entrypoint.sh` | Certificados temporários, subida do nginx e watcher que recarrega o nginx ao mudar certificado |
| `proxy/render-conf.sh` | Gera o `nginx.conf`: um server 443 por domínio, cada um com seu upstream |
| `renewer/Dockerfile`, `renewer/entrypoint.sh` | Imagem do certbot; renova na subida e uma vez por mês (a partir de `renew_day`) |
| `.https.env` (gerado, fora do git) | Envs dos dois containers, regravado pelo `remote-deploy.sh` a cada deploy |
| `lib/domains.sh` | Lista de domínios (`HTTPS_DOMAINS` = `dominio=servico:porta,...`), usada pelos dois containers |

## Contrato com o projeto

- O projeto precisa de um serviço de entrada HTTP na rede do compose (`app.proxy_service`), com a porta dada em
  `https.domains[].upstream`. O nginx do projeto não precisa de nenhuma mudança.
- Portas 80 e 443 livres no host da instância.

## Volumes na instância

- `/ext-vol/letsencrypt`: certificados e estado do certbot (`renew_all` grava a data do último ciclo).
- `/ext-vol/acme-webroot`: desafio HTTP-01 (escrito pelo certbot, servido pelo proxy na porta 80).

## Limites conhecidos

- Se a emissão falhar no deploy, o marcador mensal já foi gravado: a nova tentativa acontece no próximo deploy
  (recria o `cert-renewer`) ou no mês seguinte.
