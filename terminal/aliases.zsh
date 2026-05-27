# --------------------
# Shortcuts
# --------------------
alias reshell="source $HOME/.zshrc"
alias shrug="echo '¯\_(ツ)_/¯' | tee >(pbcopy)"
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# --------------------
# Packages
# --------------------
alias aupdate='
echo "🍺 Updating Homebrew…" &&
brew update &&
brew upgrade &&
brew cleanup

echo "🍎 Updating Mac App Store apps…"
mas upgrade
'

# --------------------
# Directories
# --------------------
alias dotfiles="cd $DOTFILES && code ."

# --------------------
# Git
# --------------------

gitstatus() {
  emulate -L zsh
  setopt local_options extended_glob

  local RESET=$'\e[0m' BOLD=$'\e[1m' DIM=$'\e[2m'
  local RED=$'\e[31m' GREEN=$'\e[32m' YELLOW=$'\e[33m'
  local MAGENTA=$'\e[35m' CYAN=$'\e[36m'

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<-EOF
	${BOLD}gitstatus${RESET} [-f|--fetch] [path]   show all git repos under <path> (default: .)

	${BOLD}Options${RESET}
	  -f, --fetch   run \`git fetch --prune\` in each repo first (parallel, network)

	${BOLD}Row marker${RESET}
	  ${YELLOW}*${RESET}   current local branch
	      other local branch
	  ${CYAN}↗${RESET}   remote-only branch (no local tracking)

	${BOLD}Working tree${RESET} (current branch only)
	  ${GREEN}✓${RESET}    clean
	  ${GREEN}✚N${RESET}   N staged changes
	  ${YELLOW}✗N${RESET}   N unstaged modifications
	  ${RED}?N${RESET}   N untracked files

	${BOLD}Tracking${RESET}
	  ${GREEN}↑N${RESET}            N commits ahead of upstream
	  ${YELLOW}↓N${RESET}            N commits behind upstream
	  ${DIM}=${RESET}             in sync with upstream
	  ${RED}gone${RESET}          upstream branch was deleted
	  ${MAGENTA}no-upstream${RESET}   local-only, never pushed
	  ${CYAN}remote-only${RESET}   exists on remote, no local checkout

	${BOLD}Header${RESET}: ${CYAN}●${RESET} ${BOLD}repo-name${RESET}  ${DIM}~/path/to/repo · host/user/repo${RESET}
	${BOLD}Last column${RESET}: relative age of branch's HEAD commit.
	EOF
    return 0
  fi

  local do_fetch=0
  if [[ "$1" == "-f" || "$1" == "--fetch" ]]; then
    do_fetch=1
    shift
  fi

  local root="${1:-.}"

  if (( do_fetch )); then
    local repo_count
    repo_count=$(find "$root" -name .git -type d -prune 2>/dev/null | wc -l | tr -d ' ')
    print -u2 -- "${DIM}Fetching ${repo_count} repos in parallel…${RESET}"
    find "$root" -name .git -type d -prune -print0 2>/dev/null \
      | xargs -0 -P 16 -n 1 sh -c \
        'd="$1"; git -C "${d%/.git}" fetch --prune --quiet 2>/dev/null' _
  fi

  # Function-scoped vars (declared once to avoid zsh `local` re-declaration printing).
  local d repo repo_name current remote_url pretty_path
  local staged modified untracked wt
  local branch upstream track age symref
  local is_current marker bcolor trk ahead behind sa wt_cell
  local wtparts tparts
  local -A tracked

  # Pad a string (possibly containing ANSI escapes) to visible width
  _gs_pad() {
    local s="$1" w="$2"
    local plain="${s//$'\e'\[[0-9;]#m/}"
    print -rn -- "$s"
    local pad=$(( w - ${#plain} ))
    (( pad > 0 )) && printf "%${pad}s" ""
  }

  # Compact relative age: "3 days ago" -> "3d", "2 weeks, 1 day ago" -> "2w"
  _gs_age() {
    REPLY="${1% ago}"
    REPLY="${REPLY%%,*}"
    REPLY="${REPLY// years/y}";   REPLY="${REPLY// year/y}"
    REPLY="${REPLY// months/mo}"; REPLY="${REPLY// month/mo}"
    REPLY="${REPLY// weeks/w}";   REPLY="${REPLY// week/w}"
    REPLY="${REPLY// days/d}";    REPLY="${REPLY// day/d}"
    REPLY="${REPLY// hours/h}";   REPLY="${REPLY// hour/h}"
    REPLY="${REPLY// minutes/m}"; REPLY="${REPLY// minute/m}"
    REPLY="${REPLY// seconds/s}"; REPLY="${REPLY// second/s}"
    [[ "$REPLY" == "just now" ]] && REPLY="now"
  }

  find "$root" -name .git -type d -prune 2>/dev/null | sort | while read -r d; do
    repo=${d:h:A}
    repo_name=${repo:t}
    current=$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null || echo "")
    pretty_path="${repo/#$HOME/~}"

    # Remote URL — prefer origin, fall back to first remote; normalize to host/user/repo
    remote_url=$(git -C "$repo" remote get-url origin 2>/dev/null \
      || git -C "$repo" remote get-url "$(git -C "$repo" remote 2>/dev/null | head -n1)" 2>/dev/null)
    if [[ -n "$remote_url" ]]; then
      remote_url="${remote_url%.git}"
      remote_url="${remote_url#https://}"
      remote_url="${remote_url#http://}"
      remote_url="${remote_url#ssh://}"
      remote_url="${remote_url#git://}"
      remote_url="${remote_url#git@}"
      remote_url="${remote_url/://}"     # git@host:user/repo -> host/user/repo
    else
      remote_url="${RED}(no remote)${RESET}${DIM}"
    fi

    # Working-tree state (applies to current branch only)
    staged=$(git -C "$repo" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git -C "$repo" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$repo" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    wtparts=()
    (( staged    > 0 )) && wtparts+=("${GREEN}✚${staged}${RESET}")
    (( modified  > 0 )) && wtparts+=("${YELLOW}✗${modified}${RESET}")
    (( untracked > 0 )) && wtparts+=("${RED}?${untracked}${RESET}")
    if (( ${#wtparts} == 0 )); then
      wt="${GREEN}✓${RESET}"
    else
      wt="${(j: :)wtparts}"
    fi

    # Repo header
    printf "%s●%s %s%s%s  %s%s · %s%s\n" \
      "$CYAN" "$RESET" "$BOLD" "$repo_name" "$RESET" \
      "$DIM" "$pretty_path" "$remote_url" "$RESET"

    # Walk all local branches, most-recent commit first
    git -C "$repo" for-each-ref \
      --sort=-committerdate \
      --format='%(refname:short)|%(upstream:short)|%(upstream:track)|%(committerdate:relative)' \
      refs/heads/ 2>/dev/null | while IFS='|' read -r branch upstream track age; do

      is_current=0; marker=" "; bcolor=""
      if [[ "$branch" == "$current" ]]; then
        is_current=1; marker="*"; bcolor="$YELLOW$BOLD"
      fi

      # Tracking cell
      trk=""
      if [[ -z "$upstream" ]]; then
        trk="${MAGENTA}no-upstream${RESET}"
      elif [[ "$track" == *gone* ]]; then
        trk="${RED}gone${RESET}"
      else
        ahead=0; behind=0
        [[ "$track" =~ 'ahead ([0-9]+)' ]] && ahead=$match[1]
        [[ "$track" =~ 'behind ([0-9]+)' ]] && behind=$match[1]
        tparts=()
        (( ahead  > 0 )) && tparts+=("${GREEN}↑${ahead}${RESET}")
        (( behind > 0 )) && tparts+=("${YELLOW}↓${behind}${RESET}")
        if (( ${#tparts} > 0 )); then
          trk="${(j: :)tparts}"
        else
          trk="${DIM}=${RESET}"
        fi
      fi

      _gs_age "$age"; sa="$REPLY"

      wt_cell=""
      (( is_current )) && wt_cell="$wt"

      print -rn -- "  ${YELLOW}${marker}${RESET} "
      _gs_pad "${bcolor}${branch}${RESET}" 28
      print -rn -- " "
      _gs_pad "$wt_cell" 12
      print -rn -- " "
      _gs_pad "$trk" 12
      print -rn -- " "
      printf "%s%s%s\n" "$DIM" "$sa" "$RESET"
    done

    # Remote-only branches (no local branch tracks them)
    tracked=()
    git -C "$repo" for-each-ref --format='%(upstream:short)' refs/heads/ 2>/dev/null \
      | while read -r upstream; do
          [[ -n "$upstream" ]] && tracked[$upstream]=1
        done

    git -C "$repo" for-each-ref --sort=-committerdate \
      --format='%(refname:short)|%(symref)|%(committerdate:relative)' refs/remotes/ 2>/dev/null \
      | while IFS='|' read -r branch symref age; do
        [[ -n "$symref" ]] && continue   # skip symbolic refs (e.g. origin/HEAD)
        [[ -n "${tracked[$branch]}" ]] && continue
        _gs_age "$age"; sa="$REPLY"

        print -rn -- "  ${CYAN}↗${RESET} "
        _gs_pad "${CYAN}${branch}${RESET}" 28
        print -rn -- " "
        _gs_pad "" 12
        print -rn -- " "
        _gs_pad "${CYAN}remote-only${RESET}" 12
        print -rn -- " "
        printf "%s%s%s\n" "$DIM" "$sa" "$RESET"
      done
    echo
  done

  unfunction _gs_pad _gs_age 2>/dev/null
}

# --------------------
# JS
# --------------------
alias nfresh="rm -rf node_modules/ package-lock.json && npm install"
alias nupdate="ncu -u && npm update"

# --------------------
# Computer vision
# --------------------
play() {
    local framerate="${1:-64}"            # default: 64 if no arg
    local pattern="${2:-frame_%010d.jpg}" # default pattern if not provided
    ffplay -framerate "$framerate" -i "$pattern"
}

trim_png() {
    # Usage: trim_png input.png output.png
    if [ $# -ne 2 ]; then
        echo "Usage: trim_png <input.png> <output.png>"
        return 1
    fi
    magick "$1" -trim +repage "$2"
}

mp4_to_gif() {
    # Usage: mp4_to_gif <input.mp4> [fps] [width]
    local input="$1" fps="${2:-}" width="${3:-}"
    [[ -z "$input" ]] && { echo "Usage: mp4_to_gif <input.mp4> [fps] [width]"; return 1; }

    local output="${input:r}.gif"
    local palette="/tmp/mp4_to_gif_palette_$$.png"
    local scale=""

    [[ -z "$fps" ]] && fps=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=r_frame_rate \
        -of default=noprint_wrappers=1:nokey=1 "$input" | bc)
    (( fps > 30 )) && fps=30

    [[ -n "$width" ]] && scale=",scale=$width:-1:flags=lanczos"

    ffmpeg -i "$input" -vf "fps=$fps${scale},palettegen" -y "$palette" &&
    ffmpeg -i "$input" -i "$palette" \
        -filter_complex "[0:v]fps=$fps${scale}[v];[v][1:v]paletteuse" \
        -loop 0 -y "$output"
    rm -f "$palette"
}

# ---------------------
# Virtual environment
# ---------------------

alias mk_env='function _mk_env() {
  local env_name="$1"
  local env_type
  local py_version
  local file_path

  # Get environment name
  if [ -z "$env_name" ]; then
    read "env_name?Enter the name of the environment: "
    if [ -z "$env_name" ]; then
        echo "Error: Environment name cannot be empty."
        return 1
    fi
  fi

  # Ask which type of environment to create
  read "env_type?Enter the type of environment (mamba, conda, uv): "

  # Conda or mamba
  if [ "$env_type" = "conda" ] || [ "$env_type" = "mamba" ]; then
    local tool="$env_type"  # tool = conda or mamba

    # Choose Python version
    read "py_version?Enter Python version (e.g. 3.8, 3.10): "

    # Optional: path to environment.yml or requirements.txt
    read "file_path?Optional: Path to environment.yml or requirements.txt (leave blank if none): "

    if [[ "$file_path" == *environment.yml || "$file_path" == *environment.yaml ]]; then
      # If environment.yml provided, create environment from it
      $tool env create -n "$env_name" -f "$file_path"
    else
      # Else just create an empty environment
      $tool create -y -n "$env_name" python="$py_version"
    fi

    # Ensure Jupyterlab and ipykernel are installed
    $tool install -y -n "$env_name" jupyterlab ipykernel

    # Upgrade pip
    $tool run -n "$env_name" python -m pip install --upgrade pip

    if [[ "$file_path" == *requirements.txt ]]; then
      # If requirements.txt provided, install dependencies
      $tool run -n "$env_name" python -m pip install -r "$file_path"
    fi

    # Register Jupyterlab kernel
    $tool run -n "$env_name" python -m ipykernel install --user --name "$env_name" --display-name "Python ($env_name)"

  # uv
  elif [ "$env_type" = "uv" ]; then
    read "root_path?Enter the path to the project root (default: current directory): "
    if [ -z "$root_path" ]; then
      root_path="."
    fi

    read "file_path?Optional: Path to requirements.txt (leave blank if none): "

    local venv_path="$root_path/.venv"
    uv venv "$venv_path"

    uv pip install --python "$venv_path/bin/python" jupyterlab ipykernel

    if [[ "$file_path" == *requirements.txt ]]; then
      uv pip install --python "$venv_path/bin/python" -r "$file_path"
    fi

    "$venv_path/bin/python" -m ipykernel install --user --name "$env_name" --display-name "Python ($env_name)"

  else
    echo "Invalid environment type: use mamba, conda or uv"
    return 1
  fi
}; _mk_env'


alias rm_env='function _rm_env() {
  local env_name="$1"
  local env_type

  # Get environment name
  if [ -z "$env_name" ]; then
    read "env_name?Enter the name of the environment: "
    if [ -z "$env_name" ]; then
        echo "Error: Environment name cannot be empty."
        return 1
    fi
  fi

  # Ask which type of environment to remove
  read "env_type?Enter the type of environment (mamba, conda, uv): "

  # Conda or mamba
  if [ "$env_type" = "conda" ] || [ "$env_type" = "mamba" ]; then
    local tool="$env_type"
    echo "Removing $tool environment: $env_name"

    # Deactivate
    $tool deactivate 2>/dev/null

    # Uninstall Jupyterlab kernel
    $tool run -n "$env_name" jupyter kernelspec uninstall -y "$env_name"

    # Remove environment
    $tool env remove -n "$env_name" -y

  # uv
  elif [ "$env_type" = "uv" ]; then
    read "root_path?Enter the path to the project root (default: current directory): "
    if [ -z "$root_path" ]; then
      root_path="."
    fi

    echo "Removing virtual environment: $env_name"
    if [ -d "$root_path/.venv" ] && [ -f "$root_path/.venv/bin/activate" ]; then
      "$root_path/.venv/bin/jupyter" kernelspec uninstall -y "$env_name"
      rm -rf "$root_path/.venv"
    else
      echo "Virtual environment not found in: $root_path/.venv"
    fi

  else
    echo "Invalid environment type: use mamba, conda or uv"
    return 1
  fi
}; _rm_env'

alias export_env='function _export_env() {
  local env_name="$1"
  local env_type
  local output_file

  # Get environment name
  if [ -z "$env_name" ]; then
    read "env_name?Enter the name of the environment: "
    if [ -z "$env_name" ]; then
        echo "Error: Environment name cannot be empty."
        return 1
    fi
  fi

  # Ask which type of environment to export
  read "env_type?Enter the type of environment (mamba, conda, uv): "

  # Ask for output file path
  read "output_file?Enter the output file path (leave blank for default): "

  # Conda or mamba
  if [ "$env_type" = "conda" ] || [ "$env_type" = "mamba" ]; then
    local tool="$env_type"

    # Set default output file if not provided
    if [ -z "$output_file" ]; then
      output_file="environment.yml"
    fi

    echo "Exporting $tool environment: $env_name to $output_file"

    # Export environment and remove prefix line
    $tool env export -n "$env_name" | grep -v "^prefix:" > "$output_file"

    echo "Environment exported successfully to: $output_file"

  # uv
  elif [ "$env_type" = "uv" ]; then
    read "root_path?Enter the path to the project root (default: current directory): "
    if [ -z "$root_path" ]; then
      root_path="."
    fi

    if [ -z "$output_file" ]; then
      output_file="requirements.txt"
    fi

    echo "Exporting virtual environment: $env_name to $output_file"

    if [ -d "$root_path/.venv" ] && [ -f "$root_path/.venv/bin/activate" ]; then
      uv pip freeze --python "$root_path/.venv/bin/python" > "$output_file"
      echo "Environment exported successfully to: $output_file"
    else
      echo "Virtual environment not found in: $root_path/.venv"
      return 1
    fi

  else
    echo "Invalid environment type: use mamba, conda or uv"
    return 1
  fi
}; _export_env'