# Jarvis-Project

Instalador do Jarvis, meu assistente pessoal feito com IA, com um passo a passo simples.

O Jarvis é baseado no [OpenJarvis](https://github.com/open-jarvis/OpenJarvis) (Stanford, licença Apache-2.0): a IA roda **no seu próprio computador**, sem mensalidade.

Versão 1.2

* memória persistente
* pesquisa web
* comando de voz (fala com o microfone, o Jarvis responde falando)
* tela estilo filme: um núcleo brilhante que reage quando ele ouve e fala
* voz grátis em português (Kokoro, roda local)
* opcional: o Jarvis roda comandos no seu PC (sempre pede confirmação)

## O que você precisa

* Linux (Ubuntu, Debian, Fedora, Arch, openSUSE) ou Windows com [WSL2](https://open-jarvis.github.io/OpenJarvis/getting-started/wsl2/)
* Um usuário normal com permissão de `sudo` (não rode como root)
* Internet e uns 15 GB livres no disco (a voz e os modelos de IA ocupam bastante espaço)
* Para a voz: microfone e caixa de som ou fone

O Python, o `uv`, o Ollama e o modelo de IA são instalados automaticamente.

## Passo a passo

**1. Abra o terminal** (no Ubuntu: `Ctrl` + `Alt` + `T`).

**2. Instale o git**, se ainda não tiver:

```bash
sudo apt install -y git
```

**3. Baixe este projeto:**

```bash
git clone https://github.com/BenezDev/Jarvis-Project.git
cd Jarvis-Project
```

**4. Rode o instalador:**

```bash
bash instalar.sh
```

Ele vai:

1. instalar o que falta no sistema (git, curl, espeak-ng, portaudio). O `sudo` pode pedir sua senha.
2. rodar o instalador oficial do OpenJarvis (uv, Python, Ollama e o modelo `qwen3.5:2b`). Ele pergunta se você quer enviar estatísticas de uso: aperte `N` para não enviar.
3. instalar a pesquisa web e a voz.
4. configurar o Jarvis para usar as ferramentas, falar português e usar a voz `pm_alex`.
5. instalar a personalidade do Jarvis (`config/SOUL.md`) e criar os atalhos `jarvis-voz` e `jarvis-tela`.

**5. Abra um terminal novo** (ou rode `source ~/.bashrc`).

**6. Converse com o Jarvis:**

```bash
jarvis        # conversa por texto
jarvis-voz    # conversa por voz: aperte Enter e fale
jarvis-tela   # abre a tela do Jarvis no navegador e conversa por voz
```

Na primeira vez, o Jarvis ainda pode estar baixando modelos. Rode `jarvis doctor` para ver o andamento.

### Opções do instalador

| Opção | O que faz |
|---|---|
| `bash instalar.sh --sem-voz` | instala sem microfone e voz (bem menor) |
| `bash instalar.sh --controle-pc` | deixa o Jarvis rodar comandos no PC, sempre com confirmação |
| `bash instalar.sh --voz pf_dora` | escolhe a voz (`pm_alex`, `pm_santa` ou `pf_dora`) |

Pode rodar o instalador de novo quando quiser: ele pula o que já está instalado.

## Como usar

| Comando | Para quê |
|---|---|
| `jarvis` | conversar por texto |
| `jarvis-voz` | conversar por voz no terminal |
| `jarvis-tela` | abrir a tela do Jarvis e conversar por voz |
| `jarvis ask "pergunta"` | fazer uma pergunta rápida |
| `jarvis gui` | abrir a interface oficial do OpenJarvis (precisa do Node.js 22 ou mais novo) |
| `jarvis doctor` | verificar se está tudo funcionando |
| `jarvis memory index ~/Documentos` | ensinar ao Jarvis o conteúdo dos seus documentos |
| `jarvis memory search "assunto"` | procurar algo nos documentos indexados |

### Tela do Jarvis

```bash
jarvis-tela
```

Liga o servidor do Jarvis e abre a tela no navegador (`http://localhost:3000`). Na primeira vez demora alguns minutos e o navegador pede para usar o microfone: clique em **Permitir**.

* **Falar:** toque no núcleo (ou aperte `Espaço`) e fale. Quando você fica em silêncio, ele entende, pensa e responde falando.
* **Conversa:** com o botão `CONVERSA` ligado, depois de responder ele volta a ouvir sozinho. Aperte `Esc` para parar.
* **Escrever:** também dá para digitar na caixa de texto.
* **Mudo:** o botão `MUDO` desliga a voz dele; as respostas continuam aparecendo na tela.
* O painel da direita mostra se o servidor, a IA, o ouvido (Whisper) e a voz (Kokoro) estão prontos.

Deixe o terminal aberto enquanto usa. Para desligar, aperte `Ctrl` + `C` nele.

### Memória persistente

O Jarvis guarda o que aprende sobre você no arquivo `~/.openjarvis/MEMORY.md`. Ele mesmo anota quando você conta algo importante ("lembra que meu aniversário é 10 de maio"), e você pode editar o arquivo à vontade.

Também dá para escrever quem você é em `~/.openjarvis/USER.md` e mudar a personalidade dele em `~/.openjarvis/SOUL.md`. As mudanças valem na próxima conversa.

### Pesquisa web

Funciona sem cadastro e sem chave (You.com grátis, com DuckDuckGo de reserva). Peça coisas como "pesquisa a previsão do tempo em São Paulo". Se aparecer aviso de limite, crie uma chave grátis no [You.com](https://you.com/platform) e coloque no `~/.bashrc`:

```bash
export YOUDOTCOM_API_KEY="sua-chave"
```

### Trocar a voz

As vozes em português do Kokoro são grátis e rodam no seu PC:

| Voz | Tipo |
|---|---|
| `pm_alex` | masculina (padrão) |
| `pm_santa` | masculina |
| `pf_dora` | feminina |

```bash
jarvis config set speech.voice_id pf_dora
jarvis config set speech.voice_speed 1.1   # mais rápida
```

Se rodar o instalador de novo, passe a voz escolhida (`bash instalar.sh --voz pf_dora`); sem isso ele volta para a `pm_alex`.

### Modelo de IA mais inteligente

O modelo padrão (`qwen3.5:2b`) é leve. Se o seu PC tiver 16 GB de RAM ou uma placa de vídeo, troque por um maior:

```bash
jarvis model pull qwen3.5:9b
jarvis config set intelligence.default_model qwen3.5:9b
```

## Problemas comuns

* **`jarvis: command not found`**: abra um terminal novo ou rode `source ~/.bashrc`.
* **O Jarvis não responde ou dá erro de modelo**: o modelo ainda está baixando. Rode `jarvis doctor`.
* **O microfone não funciona**: confira se o microfone aparece em `arecord -l` (pacote `alsa-utils`). No WSL2, use o Windows 11 atualizado e libere o microfone em Configurações > Privacidade > Microfone.
* **A voz não fala**: rode `bash instalar.sh` de novo para reinstalar o `espeak-ng` e as bibliotecas de voz.
* **A tela mostra "SERVIDOR DESLIGADO"**: rode `jarvis-tela` no terminal e deixe ele aberto. Se o servidor parar com erro, o motivo fica em `~/.openjarvis/jarvis-tela.log`.

## Atualizar

Para pegar as novidades deste projeto (como a tela do Jarvis), entre na pasta dele e rode:

```bash
cd Jarvis-Project
git pull
bash instalar.sh
```

## Desinstalar

```bash
jarvis-uninstall
rm -f ~/.local/bin/jarvis-voz ~/.local/bin/jarvis-tela
rm -rf ~/.local/share/jarvis-project
```

O `jarvis-uninstall` apaga o OpenJarvis e os dados dele (`~/.openjarvis`), mas não remove o Ollama nem o `uv`.

## Créditos

Este projeto é um instalador. A IA é do [OpenJarvis](https://github.com/open-jarvis/OpenJarvis), da Stanford (Hazy Research e Scaling Intelligence Lab), licença Apache-2.0. Documentação oficial: <https://open-jarvis.github.io/OpenJarvis/>.
