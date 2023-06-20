# Desktop remoto na amazon

Sobre e configura um Debian na Amazon para uso como desktop (no gui) remoto para manutenção dos meus projetos quando eu precisar de uma internet rápida ou estiver viajando sem notebook.

## Tasks

É necessário ter as credênciais da AWS e Cloudflare como váriaveis de ambiente.

## `make apply`

Executa o terraform para configurar o desktop remoto. 

## `make destroy`

Executa o terraform para ***destruir*** o desktop remoto. 

## `make stop`

Desliga a instância do desktop remoto na amazon. Economizando assim no custo da AWS. Atenção, o custo do volume EBS será cobrado normalmente enquanto a instância existir.

## `make start`

Liga a instância do desktop remoto na amazon.
