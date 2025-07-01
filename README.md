# Projeto: Coder Template com Docker e Terraform

Este projeto define uma infraestrutura de workspaces de desenvolvimento baseada em Docker, gerenciada pelo [Coder](https://coder.com/) e provisionada via Terraform. Ele permite criar ambientes isolados e customizáveis para desenvolvimento, incluindo suporte para JetBrains Gateway, Node.js, e integração com Code-Server.

## Estrutura do Projeto

## Componentes Principais

- **[main.tf](main.tf)**  
  Define provedores, variáveis e datasources necessários para o provisionamento.

- **[locals.tf](locals.tf)**  
  Variáveis locais e metadados usados em outros recursos.

- **[general.tf](general.tf)**  
  Cria o agente principal do Coder, a imagem Docker base e o container principal do workspace. Também integra o Code-Server.

- **[jetbrains_gateway.tf](jetbrains_gateway.tf)**  
  Integração com o módulo JetBrains Gateway para acesso remoto a IDEs JetBrains.

- **[nodejs.tf](nodejs.tf)**  
  Cria um agente adicional com Node.js, NVM, Yarn e instala AWS CLI. Disponibiliza um container separado para desenvolvimento Node.js e um app Coder para acesso a uma aplicação Next.js.

- **[volumes.tf](volumes.tf)**  
  Gerencia volumes Docker persistentes para o diretório home do usuário.

- **[build/Dockerfile](build/Dockerfile)**  
  Dockerfile base para os containers, baseado em uma imagem Arch Linux customizada.

## Funcionalidades

- **Ambientes isolados:** Cada workspace roda em seu próprio container Docker.
- **Persistência de dados:** O diretório `/home/coder` é persistido em um volume Docker.
- **Provisionamento automatizado:** Instalação automática de dependências e configuração do ambiente via scripts de inicialização.
- **Integração com JetBrains Gateway e Code-Server:** Acesso remoto a IDEs e VS Code via navegador.
- **Ambiente Node.js dedicado:** Container separado com Node.js, NVM, Yarn e AWS CLI.
- **Monitoramento:** Metadados customizados para monitorar uso de CPU, RAM, disco e swap.

## Como Usar

1. **Pré-requisitos**
   - Docker instalado e rodando.
   - [Coder](https://coder.com/docs/v2/latest/install/) instalado.
   - Terraform instalado.

2. **Configuração**
   - Clone este repositório.
   - Ajuste variáveis e scripts conforme necessário nos arquivos `.tf` e `Dockerfile`.

3. **Provisionamento**
   - Inicialize o Terraform:
     ```sh
     terraform init
     ```
   - Aplique a infraestrutura:
     ```sh
     terraform apply
     ```

4. **Acesso**
   - Acesse o workspace via painel do Coder.
   - Use Code-Server ou JetBrains Gateway conforme desejado.

## Personalização

- Para adicionar mais dependências, edite o [Dockerfile](http://_vscodecontentref_/6).
- Para instalar ferramentas adicionais no startup, edite os blocos `startup_script` nos arquivos `.tf`.
- Para adicionar novos agentes ou containers, siga o padrão de [nodejs.tf](http://_vscodecontentref_/7).

## Créditos

- Baseado em [ghcr.io/cleicastro/archlinux-devcontainer](https://github.com/cleicastro/archlinux-devcontainer)
- Utiliza módulos oficiais do [Coder Registry](https://registry.coder.com/)

---

> Para dúvidas ou sugestões, abra uma issue ou entre em contato com o mantenedor do projeto.
