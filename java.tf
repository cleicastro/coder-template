locals {
  workspace_java = "workspace-java"
}
resource "coder_agent" "java" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  dir            = local.workspace_java
  startup_script = <<-EOT
    set -e

    # Prepare user home with default files on first start.
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      touch ~/.init_done
    fi
    
    # Add any commands that should be executed at workspace startup (e.g install requirements, start a program, etc) here

    sudo chown -R ${local.username} .
    
    # Atualiza pacotes e instala Docker + dependências
    sudo pacman -Syu --noconfirm docker iptables shadow sudo
    sudo pacman -Scc --noconfirm || true

    # Adiciona usuário ao grupo docker (criado pelo pacote docker)
    if ! groups $USER | grep -q docker; then
      sudo usermod -aG docker $USER || true
    fi

    # Ajusta diretórios do Docker
    sudo mkdir -p /var/lib/docker /etc/docker
    sudo chown -R $USER:docker /var/lib/docker /etc/docker

    # Inicia o daemon Docker em background
    sudo dockerd > /tmp/dockerd.log 2>&1 &
    sleep 3

    # Ajusta permissões no socket para acesso imediato
    if [ -S /var/run/docker.sock ]; then
      sudo chmod 666 /var/run/docker.sock
    fi
  EOT

  # These environment variables allow you to make Git commits right away after creating a
  # workspace. Note that they take precedence over configuration defined in ~/.gitconfig!
  # You can remove this block if you'd prefer to configure Git manually or using
  # dotfiles. (see docs/dotfiles.md)
  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.email}"
  }

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  dynamic "metadata" {
    for_each = local.coder_agent_metadata
    content {
      display_name = metadata.value.display_name
      key          = metadata.value.key
      script       = metadata.value.script
      interval     = metadata.value.interval
      timeout      = metadata.value.timeout
    }
  }
}

# See https://registry.coder.com/modules/coder/code-server
module "code-server" {
  count  = data.coder_workspace.me.start_count
  source = "registry.coder.com/coder/code-server/coder"

  # This ensures that the latest non-breaking version of the module gets downloaded, you can also pin the module version to prevent breaking changes in production.
  version = "~> 1.0"

  slug     = "code-server-java"
  agent_id = coder_agent.java.id
  order    = 1
}

resource "docker_container" "java" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.main.name
  name       = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname   = data.coder_workspace.me.name
  entrypoint = ["sh", "-c", replace(coder_agent.java.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.java.token}"]
  runtime    = "sysbox-runc"
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/${local.username}/${local.workspace_java}"
    volume_name    = docker_volume.java_home_volume.name
    read_only      = false
  }

  dynamic "labels" {
    for_each = local.common_labels
    content {
      label = labels.key
      value = labels.value
    }
  }
}

resource "docker_volume" "java_home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "coder_script" "java_sdk" {
  agent_id     = coder_agent.java.id
  display_name = "Install Java with SDK"
  icon         = "icon/shell.svg"
  run_on_start = true
  script       = <<EOF
    #!/bin/sh
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java
  EOF
}

resource "coder_script" "install_plugins_java" {
  count        = data.coder_workspace.me.start_count
  agent_id     = coder_agent.java.id
  display_name = "Install plugins"
  run_on_start = true
  icon         = "/icon/shell.svg"
  script       = file("${path.module}/scripts/install_plugins.sh")
}

resource "coder_script" "java_dotfiles" {
  agent_id     = coder_agent.java.id
  display_name = "Configuration environment for dev"
  icon         = "icon/terminal.svg"
  run_on_start = true
  script       = <<EOF
    #!/bin/sh
    
    coder dotfiles -y ${var.dotfiles_uri}

    # fix file conflicts in .zshrch
    cd ~/.config/coderv2/dotfiles/
    git reset --hard HEAD~1 && ./install.sh && source ~/.zshrc
  EOF
}