# Sancho: A Private AI Agent

Sancho provides a Dockerized version of the OpenCode harness with an Ollama backend.

## Install

**Prerequisites:**
- Docker (20.10+)
- Ollama running on a host or remote server
- Bash shell

**Build Docker image:**

From this folder:

```bash
docker build -t sancho .
```

**Setup:**
1. Ensure `provider-url.txt` contains your Ollama endpoint URL
2. Make the run script executable: `chmod +x run.sh`
3. Run `./run.sh` to start OpenCode

**Optional: Link to PATH for global access:**

```bash
sudo ln -s $(pwd)/run.sh /usr/local/bin/sancho
```
After this, you can run `sancho` from anywhere.

To remove the link later:
```bash
sudo rm /usr/local/bin/sancho
```

**Note:** If you run the link command from a different directory later, you'll need to recreate it with the updated path.

## Usage

**Basic run** (uses current directory):
```bash
sancho
```

When run from within a project folder, `sancho` will use that directory as the workspace.

**Specify project directory:**
```bash
sancho /path/to/project
```

Provide an explicit path to work on a different project location than your current directory.

## Makefile

The project includes a `Makefile` with the following targets:

**Install:**
```bash
make install
```
Builds the `sancho` Docker image and creates a `/usr/local/bin/sancho` symlink to `run.sh`.

**Build:**
```bash
make build
```
Creates the `sancho` Docker image from the current `Dockerfile`.

**Clean:**
```bash
make clean
```
Removes the `sancho` Docker image.

**Update:**
```bash
make update
```
Removes existing `sancho` image, rebuilds it with the latest OpenCode version, and displays the installed version number.

## Structure

### Configuration Files

**`opencode.json`** - AI provider configuration
- Uses Ollama via `@ai-sdk/openai-compatible` npm package
- Reads OLLAMA_HOST from environment variable
- Configured model: `qwen3.5:35b-a3b-coding-nvfp4` with tool calling enabled

**`provider-url.txt`** - Ollama endpoint URL
- Contains the Ollama server address
- Current target: `http://agami.turtle-harmonic.ts.net:11434/v1`

**`tui.json`** - Terminal UI theme settings
- Configured to use system theme

**`.gitignore`** - Git ignore rules

### Infrastructure Files

**`run.sh`** - Docker container launcher script
- Reads OLLAMA_HOST from `provider-url.txt`
- Resolves hostname to IP dynamically via DNS lookup
- Uses `--add-host` flag for container-accessible hostname resolution
- Mounts project directory, config files, and persistent Docker volumes
- Passes OLLAMA_HOST environment variable to container

**`Dockerfile`** - OpenCode container image
- Ubuntu 24.04 base with essential tools (curl, git, openssh, jq)
- Creates `coder` user with configurable UID for host file permissions
- Installs OpenCode via official installer from opencode.ai
- Sets up directories for shared state and config persistence

### Architecture

```
┌─────────────────────────────────┐
│  Docker container (Linux)         │
│   ┌─────────────────────────┐    │
│    │   OpenCode + tools      │    │
│    │    (Go binary)          │    │
│    └───────────┬─────────────┘    │
│                │ HTTP              │
│   volume mounts                       │
└───────────────┼─────────────────┘
                 │
                 │ OLLAMA_HOST env var
                 │ resolves to
                 │
┌───────────────┴─────────────────┐
│  Ollama backend                   │
│   (host or network)              │
│  Model: qwen3.5:35b              │
└─────────────────────────────────┘
```

## Configuration

### Ollama Endpoint
Store your Ollama URL in `provider-url.txt`. Modify this file to point to your instance.

### Environment Variables
- `OLLAMA_HOST` - Set from `provider-url.txt`, passed to container
- `GLAMOUR_STYLE` - Set to `dark` in `run.sh`

### Persistent Volumes
- `opencode-share` - OpenCode shared state
- `opencode-state` - OpenCode persistent data

## Troubleshooting

**DNS Resolution Issues:**
```bash
# Check network connection (Tailscale, etc.)
scutil --dns   # macOS
ip addr show   # Linux
```

**File Permissions:**
Container user UID should match host user UID for mounted workspace access.
