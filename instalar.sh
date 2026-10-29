#!/usr/bin/env bash
# instalar.sh — instalador do Jarvis, meu assistente pessoal de IA.
#
# Instala o OpenJarvis (https://github.com/open-jarvis/OpenJarvis) com o
# instalador oficial e depois configura o Jarvis: memória persistente,
# pesquisa na web, comando de voz e voz grátis em português.
#
# Rode como seu usuário normal (sem sudo):
#   bash instalar.sh

set -euo pipefail

OPENJARVIS_INSTALL_URL="https://open-jarvis.github.io/OpenJarvis/install.sh"
OPENJARVIS_HOME="${OPENJARVIS_HOME:-$HOME/.openjarvis}"
VENV_PY="$OPENJARVIS_HOME/.venv/bin/python"
JARVIS_BIN="$OPENJARVIS_HOME/.venv/bin/jarvis"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH_ORIGINAL="$PATH"

COM_VOZ=1
CONTROLE_PC=0
VOZ="pm_alex"

uso() {
    cat <<'EOF'
Uso: bash instalar.sh [opções]

  --sem-voz        não instala microfone/voz (instalação bem menor)
  --controle-pc    deixa o Jarvis rodar comandos no seu PC
                   (ele sempre pede confirmação antes de cada comando)
  --voz <id>       voz do Jarvis: pm_alex (padrão), pm_santa ou pf_dora
  -h, --ajuda      mostra esta ajuda
EOF
}

passo() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()    { printf '\033[32m[ok]\033[0m %s\n' "$*"; }
aviso() { printf '\033[33m[aviso]\033[0m %s\n' "$*" >&2; }
erro()  { printf '\033[31m[erro]\033[0m %s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sem-voz) COM_VOZ=0 ;;
        --controle-pc) CONTROLE_PC=1 ;;
        --voz) shift; VOZ="${1:-}" ;;
        --voz=*) VOZ="${1#--voz=}" ;;
        -h|--ajuda|--help) uso; exit 0 ;;
        *) erro "opção desconhecida: $1"; uso >&2; exit 2 ;;
    esac
    shift
done

# IDs de voz do Kokoro: <idioma><f|m>_<nome>, ex. pm_alex, pf_dora.
if [[ ! "$VOZ" =~ ^[a-z][fm]_[a-z]+$ ]]; then
    erro "voz inválida: '$VOZ' (exemplos: pm_alex, pm_santa, pf_dora)"
    exit 2
fi

if [[ "$(uname -s)" != "Linux" ]]; then
    erro "este instalador é para Linux (ou Windows com WSL2)."
    exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
    erro "não rode como root nem com sudo. Rode como seu usuário normal:"
    echo "  bash instalar.sh" >&2
    exit 1
fi

if [[ ! -f "$REPO_DIR/config/SOUL.md" ]]; then
    erro "arquivo config/SOUL.md não encontrado. Rode o instalador de dentro da pasta do Jarvis-Project."
    exit 1
fi

# ---- 1. pacotes do sistema ----
pacotes_sistema() {
    local faltando=()
    command -v git >/dev/null 2>&1 || faltando+=(git)
    command -v curl >/dev/null 2>&1 || faltando+=(curl)
    if [[ "$COM_VOZ" -eq 1 ]]; then
        # espeak-ng: pronúncia da voz em português (Kokoro).
        # portaudio: acesso ao microfone e à caixa de som.
        command -v espeak-ng >/dev/null 2>&1 || faltando+=(espeak-ng)
        local libs
        libs="$( { ldconfig -p || /sbin/ldconfig -p; } 2>/dev/null || true)"
        [[ "$libs" == *libportaudio.so* ]] || faltando+=(portaudio)
    fi

    if [[ ${#faltando[@]} -eq 0 ]]; then
        ok "dependências do sistema já instaladas"
        return 0
    fi

    local instalar=() nomes=() p
    if command -v apt-get >/dev/null 2>&1; then
        instalar=(apt-get install -y)
        for p in "${faltando[@]}"; do
            case "$p" in
                portaudio) nomes+=(libportaudio2) ;;
                *) nomes+=("$p") ;;
            esac
        done
    elif command -v dnf >/dev/null 2>&1; then
        instalar=(dnf install -y); nomes=("${faltando[@]}")
    elif command -v pacman >/dev/null 2>&1; then
        instalar=(pacman -S --needed --noconfirm); nomes=("${faltando[@]}")
    elif command -v zypper >/dev/null 2>&1; then
        instalar=(zypper install -y); nomes=("${faltando[@]}")
    else
        aviso "não reconheci o gerenciador de pacotes. Instale manualmente: ${faltando[*]}"
        return 0
    fi

    echo "Vou instalar: ${nomes[*]} (o sudo pode pedir sua senha)"
    if [[ "${instalar[0]}" == "apt-get" ]]; then
        sudo apt-get update -q || true
    fi
    if ! sudo "${instalar[@]}" "${nomes[@]}"; then
        aviso "não consegui instalar: ${nomes[*]}"
        aviso "instale manualmente e rode o instalador de novo."
        return 1
    fi
    ok "dependências do sistema instaladas"
}

# ---- 2. OpenJarvis (instalador oficial) ----
TMP_INSTALADOR=""
limpar() { if [[ -n "$TMP_INSTALADOR" ]]; then rm -f "$TMP_INSTALADOR"; fi; }
trap limpar EXIT

instalar_openjarvis() {
    TMP_INSTALADOR="$(mktemp)"
    curl -fsSL "$OPENJARVIS_INSTALL_URL" -o "$TMP_INSTALADOR"
    # Rodar a partir de um arquivo (e não com curl | bash) deixa o sudo do
    # Ollama pedir a senha normalmente no terminal.
    bash "$TMP_INSTALADOR"
    if [[ ! -x "$JARVIS_BIN" ]]; then
        erro "o OpenJarvis não foi instalado em $OPENJARVIS_HOME"
        exit 1
    fi
}

# ---- 3. extras: pesquisa web e voz ----
instalar_extras() {
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if ! command -v uv >/dev/null 2>&1; then
        erro "o 'uv' não foi encontrado; o instalador do OpenJarvis deveria tê-lo instalado."
        exit 1
    fi
    local extras="tools-search"
    if [[ "$COM_VOZ" -eq 1 ]]; then
        # voice: Kokoro (voz grátis e local); desktop: Whisper (ouvir o microfone).
        extras="voice,desktop,tools-search"
    fi
    (cd "$OPENJARVIS_HOME/src" && uv pip install --python "$VENV_PY" -e ".[$extras]")
}

# ---- 4. configuração do Jarvis ----
configurar() {
    local tools="web_search,memory_manage,think,calculator"
    if [[ "$CONTROLE_PC" -eq 1 ]]; then
        tools="$tools,shell_exec"
    fi
    # O agente "simple" não usa ferramentas; o "orchestrator" usa.
    "$JARVIS_BIN" config set agent.default_agent orchestrator
    "$JARVIS_BIN" config set tools.enabled "$tools"
    if [[ "$COM_VOZ" -eq 1 ]]; then
        "$JARVIS_BIN" config set speech.language pt
        "$JARVIS_BIN" config set speech.tts_backend kokoro
        "$JARVIS_BIN" config set speech.voice_id "$VOZ"
    fi
}

# ---- 5. personalidade e atalho de voz ----
personalizar() {
    local config_dir soul
    config_dir="$("$VENV_PY" -c 'from openjarvis.core.paths import get_config_dir; print(get_config_dir())')"
    soul="$config_dir/SOUL.md"
    mkdir -p "$config_dir"
    if [[ -f "$soul" ]] && ! cmp -s "$REPO_DIR/config/SOUL.md" "$soul"; then
        local backup
        backup="$soul.bak.$(date +%Y%m%d%H%M%S)"
        cp "$soul" "$backup"
        ok "SOUL.md antigo guardado em $backup"
    fi
    cp "$REPO_DIR/config/SOUL.md" "$soul"
    ok "personalidade do Jarvis instalada em $soul"

    if [[ "$COM_VOZ" -eq 1 ]]; then
        mkdir -p "$HOME/.local/bin"
        cat > "$HOME/.local/bin/jarvis-voz" <<'EOF'
#!/usr/bin/env bash
# jarvis-voz — conversa com o Jarvis por voz (instalado pelo Jarvis-Project).
exec "$HOME/.local/bin/jarvis" chat --voice "$@"
EOF
        chmod +x "$HOME/.local/bin/jarvis-voz"
        ok "atalho 'jarvis-voz' criado"
    fi
}

resumo_voz="desligada"
[[ "$COM_VOZ" -eq 1 ]] && resumo_voz="$VOZ"
resumo_pc="desligado"
[[ "$CONTROLE_PC" -eq 1 ]] && resumo_pc="ligado (com confirmação)"

echo "Instalador do Jarvis"
echo "  pasta do OpenJarvis: $OPENJARVIS_HOME"
echo "  voz:                 $resumo_voz"
echo "  controle do PC:      $resumo_pc"

passo "1/5 Dependências do sistema"
pacotes_sistema

passo "2/5 OpenJarvis (instalador oficial, ~3 minutos)"
instalar_openjarvis

passo "3/5 Pesquisa web e voz"
instalar_extras

passo "4/5 Configurando o Jarvis"
configurar

passo "5/5 Personalidade do Jarvis"
personalizar

printf '\n\033[1;32mPronto! O Jarvis está instalado.\033[0m\n\n'

case ":$PATH_ORIGINAL:" in
    *":$HOME/.local/bin:"*) ;;
    *)
        rc="$HOME/.bashrc"
        [[ "${SHELL:-}" == */zsh ]] && rc="$HOME/.zshrc"
        echo "Antes de tudo, abra um terminal novo ou rode:"
        echo "  source $rc"
        echo
        ;;
esac

echo "Para conversar por texto:  jarvis"
if [[ "$COM_VOZ" -eq 1 ]]; then
    echo "Para conversar por voz:    jarvis-voz   (aperte Enter e fale)"
fi
echo "Para ver se está tudo ok:  jarvis doctor"
echo
echo "O modelo de IA ainda pode estar baixando em segundo plano;"
echo "o 'jarvis doctor' mostra o andamento."
if [[ "$COM_VOZ" -eq 1 ]]; then
    echo "Na primeira conversa por voz, o Jarvis baixa os modelos de voz (uns minutos)."
fi
