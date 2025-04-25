#!/bin/bash

# boolean values
TRUE=0
FALSE=1

# Debug mode
DEBUG_ENABLED=$FALSE

# Colour definitions
## Foreground colours
FG_RED='\033[38;5;196m'
FG_GREEN='\033[38;5;10m'
FG_YELLOW='\033[38;5;11m'
FG_BLUE='\033[38;5;21m'
FG_MAGENTA='\033[38;5;163m'
FG_CYAN='\033[38;5;51m'
FG_BLACK='\033[38;5;16m'
FG_WHITE='\033[38;5;15m'
## Background colours
BG_RED='\033[48;5;196m'
BG_GREEN='\033[48;5;10m'
BG_YELLOW='\033[48;5;11m'
BG_BLUE='\033[48;5;21m'
BG_MAGENTA='\033[48;5;163m'
BG_CYAN='\033[48;5;51m'
BG_BLACK='\033[48;5;16m'
BG_WHITE='\033[48;5;15m'
## Text styles
BOLD='\033[1m'
UNDERLINE='\033[4m'
RESET='\033[0m'
NO_BOLD='\033[22m'
NO_UNDERLINE='\033[24m'
## Echo rebind for the help section
function hecho() {
    echo -e "${BG_BLACK}${BOLD}${FG_GREEN}$1${RESET}"
}
function h_opt_echo() {
    local shorthand="$1"
    local flag_padding="$2"
    local full_flag="$3"
    local description_padding="$4"
    local description="$5"
    echo -e "${BG_BLACK}  ${BOLD}${FG_CYAN}${shorthand}${FG_WHITE}${NO_BOLD},${flag_padding}${BOLD}${FG_YELLOW}${full_flag}${NO_BOLD}${FG_WHITE}${description_padding}${FG_CYAN}${description}${RESET}"
}
## LOGGING presets
STRING_CRITITAL="${BOLD}${BG_RED}${FG_WHITE}CRITICAL${RESET}"
STRING_ERROR="${BOLD}${FG_RED}ERROR${RESET}"
STRING_WARNING="${BOLD}${FG_YELLOW}WARNING${RESET}"
STRING_INFO="${BOLD}${FG_CYAN}INFO${RESET}"
STRING_SUCCESS="${BOLD}${FG_GREEN}SUCCESS${RESET}"
STRING_DEBUG="${BOLD}${FG_BLUE}DEBUG${RESET}"
## Get date and time
function date_and_time() {
    date +"%Y-%m-%d %T"
}
## LOGGING functions
function log_base() {
    local called_line_number="${3:-BASH_LINENO[1]}"
    local function_name="${4:-FUNCNAME[1]}"
    echo -e "[$(date_and_time)] <$1> (${function_name}:${called_line_number}): $2"
}
function log_critical() {
    local called_line_number="${BASH_LINENO[1]}"
    local function_name="${FUNCNAME[1]}"
    log_base "${STRING_CRITITAL}" "$1" "$called_line_number" "$function_name"
}
function log_error() {
    local called_line_number="${BASH_LINENO[1]}"
    local function_name="${FUNCNAME[1]}"
    log_base "${STRING_ERROR}" "$1" "$called_line_number" "$function_name"
}
function log_warning() {
    local called_line_number="${BASH_LINENO[1]}"
    local function_name="${FUNCNAME[1]}"
    log_base "${STRING_WARNING}" "$1" "$called_line_number" "$function_name"
}
function log_info() {
    local called_line_number="${BASH_LINENO[1]}"
    local function_name="${FUNCNAME[1]}"
    log_base "${STRING_INFO}" "$1" "$called_line_number" "$function_name"
}
function log_success() {
    local called_line_number="${BASH_LINENO[1]}"
    local function_name="${FUNCNAME[1]}"
    log_base "${STRING_SUCCESS}" "$1" "$called_line_number" "$function_name"
}
function log_debug() {
    local called_line_number="${BASH_LINENO[1]}"
    local function_name="${FUNCNAME[1]}"
    if [ "$DEBUG_ENABLED" == "$FALSE" ]; then
        return
    fi
    log_base "${STRING_DEBUG}" "$1" "$called_line_number" "$function_name"
}

log_warning "This script is provided as if and without any warranty, it has only been tested on a Ubuntu LTS 24.04"
log_info "(c) Script written by Henry Letellier"

function check_if_sudo_required_for_docker() {
    log_info "Checking if sudo is required for docker..."
    if docker ps >/dev/null 2>&1; then
        log_info "Sudo is not required."
        SUDO=""
    else
        log_warning "Sudo is required, setting."
        SUDO="sudo"
    fi
}

function check_if_help() {
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        hecho "Usage: $0 [OPTIONS]"
        hecho "Options:"
        h_opt_echo "-h" "   " "--help" "                         " "Display this help message."
        h_opt_echo "-m" "   " "--model-name" "                   " "The model name to use. Default: deepseek-r1"
        h_opt_echo "-w" "   " "--model-weight" "                 " "The model weight to use. Default: 7b"
        h_opt_echo "-c" "   " "--container-name" "               " "The container name to use. Default: deep-seek-container"
        h_opt_echo "-i" "   " "--image-name" "                   " "The image name to use. Default: deep-seek-image"
        h_opt_echo "-d" "   " "--dockerfile-location-folder" "   " "The location folder to store the Dockerfile. Default: /tmp/deep-seek"
        h_opt_echo "-o" "   " "--ollama-cache-location-folder" " " "The location folder to store the ollama cache. Default: ollama_cache"
        h_opt_echo "-p" "   " "--ollama-host-port" "             " "The host port to use for ollama. Default: 11434"
        h_opt_echo "-v" "   " "--ollama-version" "               " "The version of ollama to use. Default: 0.5.7"
        h_opt_echo "-u" "   " "--update" "                       " "Force the update of the dockerfile used to build the image (this is if you updated the script)."
        h_opt_echo "-g" "   " "--use-gpu" "                      " "Use the GPU for the container. Default: true"
        h_opt_echo "-gp" "  " "--use-gpu-portion" "              " "The portion of the GPU to use. Default: all"
        h_opt_echo "-cr" "  " "--custom-run" "                   " "Specify a command you wish to run instead of the default one. Default: /bin/bash"
        h_opt_echo "-cls" " " "--clean" "                        " "Clean the docker container, image and file."
        h_opt_echo "-dec" " " "--dockerfile-entry-command" "     " "The command to run when the container starts. Default: /bin/ollama serve"
        h_opt_echo "-deb" " " "--debug" "                        " "Enable debug mode. Default: false"
        exit 0
    fi
}

check_if_help $1

MODEL_NAME="deepseek-r1"

MODEL_WEIGHT="14b" #"7b"

CONTAINER_NAME="deep-seek-container"

IMAGE_NAME="deep-seek-image"

SUDO=""
check_if_sudo_required_for_docker

DOCKERFILE_LOCATION_FOLDER=/tmp/deep-seek

DOCKERFILE_LOCATION_FILE=$DOCKERFILE_LOCATION_FOLDER/Dockerfile

CONTAINER_DEFAULT_COMMAND="/bin/bash"

DOCKERFILE_DEFAULT_ENTRY_COMMAND="/bin/ollama serve"

OLLAMA_CACHE_LOCATION_FOLDER=ollama_cache

OLLAMA_HOST_PORT=11434

OLLAMA_VERSION="0.5.7"

USE_GPU=$TRUE
USE_GPU_PORTION="all"

UPDATE_THE_DOCKERFILE=$FALSE

CLEAN_RESSOURCES=$FALSE

function process_arguments() {
    while [ "$1" != "" ]; do
        log_debug "Processing argument: $1"
        case $1 in
        -m | --model-name)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No model name provided, using default name '$MODEL_NAME'..."
            else
                if [ "$1" != "$MODEL_NAME" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    MODEL_NAME=$1
                else
                    log_warning "The Model name is already set to '$MODEL_NAME', skipping..."
                fi
            fi
            ;;
        -w | --model-weight)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No model weight provided, using default weight '$MODEL_WEIGHT'..."
            else
                if [ "$1" != "$MODEL_WEIGHT" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    MODEL_WEIGHT=$1
                else
                    log_warning "The Model weight is already set to '$MODEL_WEIGHT', skipping..."
                fi
            fi
            ;;
        -c | --container-name)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No container name provided, using default name '$CONTAINER_NAME'..."
            else
                CONTAINER_NAME=$1
            fi
            ;;
        -i | --image-name)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No image name provided, using default name '$IMAGE_NAME'..."
            else
                IMAGE_NAME=$1
            fi
            ;;
        -d | --dockerfile-location-folder)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No dockerfile location folder provided, using default folder '$DOCKERFILE_LOCATION_FOLDER'..."
            else
                if [ "$1" != "$DOCKERFILE_LOCATION_FOLDER" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    DOCKERFILE_LOCATION_FOLDER=$1
                    DOCKERFILE_LOCATION_FILE=$DOCKERFILE_LOCATION_FOLDER/Dockerfile
                else
                    log_warning "The Dockerfile location folder is already set to '$DOCKERFILE_LOCATION_FOLDER', skipping..."
                fi
            fi
            ;;
        -o | --ollama-cache-location-folder)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No ollama cache location folder provided, using default folder '$OLLAMA_CACHE_LOCATION_FOLDER'..."
            else
                if [ "$1" != "$OLLAMA_CACHE_LOCATION_FOLDER" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    OLLAMA_CACHE_LOCATION_FOLDER=$1
                else
                    log_warning "The Ollama cache location folder is already set to '$OLLAMA_CACHE_LOCATION_FOLDER', skipping..."
                fi
            fi
            ;;
        -p | --ollama-host-port)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No ollama host port provided, using default port '$OLLAMA_HOST_PORT'..."
            else
                if [ "$1" != "$OLLAMA_HOST_PORT" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    OLLAMA_HOST_PORT=$1
                else
                    log_warning "The Ollama host port is already set to '$OLLAMA_HOST_PORT', skipping..."
                fi
            fi
            ;;
        -v | --ollama-version)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No ollama version provided, using default version '$OLLAMA_VERSION'..."
            else
                if [ "$1" != "$OLLAMA_VERSION" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    OLLAMA_VERSION=$1
                else
                    log_warning "The Ollama version is already set to '$OLLAMA_VERSION', skipping..."
                fi
            fi
            ;;
        -u | --update)
            log_info "Update dockerfile flag set to true"
            UPDATE_THE_DOCKERFILE=$TRUE
            ;;
        -cls | --clean)
            log_info "Clean resources flag set to true"
            CLEAN_RESSOURCES=$TRUE
            ;;
        -g | --use-gpu)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No gpu usage provided, using default value '$USE_GPU'..."
            else
                if [ "$1" != "$USE_GPU" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    USE_GPU=$1
                else
                    log_warning "The GPU options is already set to '$USE_GPU', skipping..."
                fi
            fi
            ;;
        -gp | --use-gpu-portion)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No gpu portion provided, using default value '$USE_GPU_PORTION'..."
            else
                if [ "$1" != "$USE_GPU_PORTION" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    USE_GPU_PORTION=$1
                else
                    log_warning "The use gpu portion is already set to '$USE_GPU_PORTION', skipping..."
                fi
            fi
            ;;
        -cr | --custom-run)
            shift.
            if [ ${#1} -eq 0 ]; then
                log_warning "No custom run command provided, using default command '$CONTAINER_DEFAULT_COMMAND'..."
            else
                if [ "$1" != "$CONTAINER_DEFAULT_COMMAND" ]; then
                    if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                        log_info "The update dockerfile flag has not been set, setting it to true..."
                        UPDATE_THE_DOCKERFILE=$TRUE
                    fi
                    CONTAINER_DEFAULT_COMMAND=$1
                else
                    log_warning "The container default command is already set to '$CONTAINER_DEFAULT_COMMAND', skipping..."
                fi
            fi
            ;;
        -dec | --dockerfile-entry-command)
            shift
            if [ ${#1} -eq 0 ]; then
                log_warning "No command provided, using default command '$DOCKERFILE_DEFAULT_ENTRY_COMMAND'..."
            else
                DOCKERFILE_DEFAULT_ENTRY_COMMAND="$1"
            fi
            if [ "$UPDATE_THE_DOCKERFILE" != "$TRUE" ]; then
                log_info "The update dockerfile flag has not been set, setting it to true..."
                UPDATE_THE_DOCKERFILE=$TRUE
            fi
            ;;
        -deb | --debug)
            log_info "Debug mode enabled"
            DEBUG_ENABLED=$TRUE
            ;;
        *)
            log_critical "Invalid argument: $1"
            exit 1
            ;;
        esac
        shift
    done
}

function detect_gpu_type() {
    # Use lspci to look for GPU information
    local gpu_info=""
    gpu_info=$(lspci | grep -i "vga\|3d\|display")

    if echo "$gpu_info" | grep -iq "nvidia"; then
        echo "nvidia"
        return 0
    elif echo "$gpu_info" | grep -iq "amd"; then
        echo "amd"
        return 0
    else
        echo "unknown"
        return 1
    fi
}

function dump_the_docker_file() {
    local gpu_type=""
    local container_version="${OLLAMA_VERSION:-latest}"
    log_info "Creating the Dockerfile location folder..."
    mkdir -p $DOCKERFILE_LOCATION_FOLDER
    log_info "Checking for GPU type..."
    gpu_type="$(detect_gpu_type)"
    if [ $? -ne 0 ]; then
        log_error "Failed to detect GPU type, defaulting to no gpu..."
        container_version=""
    fi
    if [ "$gpu_type" == "amd" ]; then
        log_info "GPU detected, using AMD runtime..."
        if [ "$container_version" != "latest" ] || [ "$container_version" != "" ]; then
            container_version="${container_version}-rocm"
        else
            container_version="rocm"
        fi
    elif [ "$gpu_type" == "nvidia" ]; then
        log_success "GPU detected, using NVIDIA runtime..."
    else
        log_warning "No GPU detected, skipping NVIDIA and AMD runtime configuration..."
    fi
    log_info "Dumping the Dockerfile..."
    cat <<EOF >$DOCKERFILE_LOCATION_FILE
# Stage 1: Use BusyBox as a builder (only for a specific task like copying utilities or files)
FROM busybox:uclibc AS busybox_stage

# Using the official ollama docker image as the base
FROM ollama/ollama:${container_version}


# Setting the environment variables
ENV MODEL_WEIGHT=${MODEL_WEIGHT} \\
    MODEL_NAME=${MODEL_NAME} \\
    DEBIAN_FRONTEND=noninteractive

# Create a safe location to store the busybox files
RUN mkdir -p /my_busybox

# Copy the busybox files to the safe location
COPY --from=busybox_stage /bin /my_busybox

# Grant execution permissions to the busybox files
RUN chmod +x /my_busybox/*

# Add the safe location to the PATH
ENV PATH="/my_busybox:\$PATH"

# Create a custom entrypoint script to run commands in sequence
RUN echo '#!/bin/bash\n\\
/bin/ollama serve &\n\\
sleep 5s\n\\
/bin/ollama pull \${MODEL_NAME}:\${MODEL_WEIGHT}\n\\
' > /entrypoint.sh \\
    && chmod +x /entrypoint.sh

# Create the script to run the llm model
RUN echo '#!/bin/bash\n\\
echo "Checking if the server is running..."\n\\
ps aux | grep "[o]llama serve"\n\\
if [ \$? -ne 0 ]; then\n\\
    echo "Server is not running, starting..."\n\\
    /bin/ollama serve >/dev/null &\n\\
    sleep 5s\n\\
fi\n\\
echo "Server is running"\n\\
echo "Checking for the best ollama mirror..."\n\\
/bin/ollama pull\n\\
echo "Fastest mirror checked"\n\\
echo "Starting model \${MODEL_NAME}, model size: \${MODEL_WEIGHT}"\n\\
echo "To cancel an ongoing query, press CTRL+C"\n\\
echo "To exit the model enter /exit"\n\\
/bin/ollama run \${MODEL_NAME}:\${MODEL_WEIGHT} \$@\n\\
' > /start_model \\
    && chmod +x /start_model

# Get the latest version of the llm model
RUN /my_busybox/sh -c "/entrypoint.sh"

# Set the ENTRYPOINT to an interactive shell to pull the latest version of the llm model
ENTRYPOINT ["/my_busybox/sh", "-c"]

# Default CMD that can be overridden with another command
CMD ["$DOCKERFILE_DEFAULT_ENTRY_COMMAND"]
EOF
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to dump the Dockerfile, status: $STATUS"
    else
        log_success "Dockerfile dumped at: '$DOCKERFILE_LOCATION_FILE'"
        local dockerfile_size=$(du -h $DOCKERFILE_LOCATION_FILE | cut -f1)
        local dockerfile_lines=$(wc -l <$DOCKERFILE_LOCATION_FILE)
        local dockerfile_words=$(wc -w <$DOCKERFILE_LOCATION_FILE)
        local dockerfile_chars=$(wc -c <$DOCKERFILE_LOCATION_FILE)
        local dockerfile_last_modified=$(stat -c %y $DOCKERFILE_LOCATION_FILE)
        local dockerfile_content=$(cat $DOCKERFILE_LOCATION_FILE)
        log_debug "Dockerfile size: $dockerfile_size"
        log_debug "Dockerfile lines: $dockerfile_lines"
        log_debug "Dockerfile words: $dockerfile_words"
        log_debug "Dockerfile chars: $dockerfile_chars"
        log_debug "Dockerfile last modified: $dockerfile_last_modified"
        log_debug "Dockerfile content:\n$dockerfile_content"
    fi
    return $STATUS
}

function detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    else
        echo "unsupported"
    fi
}

function is_system_linux() {
    if [ "$(detect_os)" == "linux" ]; then
        return $TRUE
    else
        return $FALSE
    fi
}

function create_ollama_cache_folder() {
    log_info "Creating the ollama cache folder (if it is not a volume)..."
    if [[ "$OLLAMA_CACHE_LOCATION_FOLDER" != *"/"* ]]; then
        log_success "The ollama cache folder is a volume, skipping creation..."
        return
    fi
    log_info "The ollama cache folder is not a volume, creating if not already present..."
    mkdir -p $OLLAMA_CACHE_LOCATION_FOLDER
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to create the ollama cache folder, status: $STATUS"
    else
        log_success "The ollama cache folder is created"
    fi
    return $STATUS
}

function check_if_ollama_is_installed() {
    log_info "Checking if ollama is installed..."
    if ollama --version >/dev/null 2>&1; then
        log_success "Ollama is installed."
        return $TRUE
    else
        log_error "Ollama is not installed."
        return $FALSE
    fi
}

function install_ollama_if_required() {
    log_info "Installing ollama (if required)"
    is_system_linux
    if [ "$?" == "$FALSE" ]; then
        log_error "Unsupported OS (by this script), skipping step..."
        return
    fi
    check_if_ollama_is_installed
    if [ $? -ne 0 ]; then
        log_warning "Ollama is not installed, installing..."
        curl -fsSL https://ollama.com/install.sh | sh
        check_if_ollama_is_installed
        if [ $? -ne 0 ]; then
            log_critical "Failed to install ollama, exiting..."
            exit 1
        fi
    else
        log_success "Ollama is installed."
    fi
}

function check_if_container_exists() {
    log_info "Checking if the container exists..."
    if $SUDO docker ps -a | grep $CONTAINER_NAME >/dev/null; then
        log_success "Container exists."
        return $TRUE
    else
        log_error "Container does not exist."
        return $FALSE
    fi
}

function check_if_container_is_running() {
    log_info "Checking if the container is running..."
    if $SUDO docker ps | grep $CONTAINER_NAME >/dev/null; then
        log_success "Container is running."
        return $TRUE
    else
        log_error "Container is not running."
        return $FALSE
    fi
}

function check_if_image_exists() {
    log_info "Checking if the image exists..."
    if $SUDO docker images | grep $IMAGE_NAME >/dev/null; then
        log_success "Image exists."
        return $TRUE
    else
        log_error "Image does not exist."
        return $FALSE
    fi
}

function remove_the_container() {
    log_info "Removing the container: '$CONTAINER_NAME'..."
    $SUDO docker rm -f $CONTAINER_NAME
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to remove the container: '$CONTAINER_NAME', status: $STATUS"
    else
        log_success "Container removed: '$CONTAINER_NAME'"
    fi
    return $STATUS
}

function remove_the_image() {
    log_info "Removing the image..."
    $SUDO docker image rm -f $IMAGE_NAME
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to remove the image: '$IMAGE_NAME', status: $STATUS"
    else
        log_success "Image removed: '$IMAGE_NAME'"
    fi
    return $STATUS
}

function remove_the_docker_build_cache() {
    log_info "Removing the docker build cache..."
    $SUDO docker builder prune -a -f
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to remove the docker build cache, status: $STATUS"
    else
        log_success "Docker build cache removed"
    fi
    return $STATUS
}

function remove_the_volumes() {
    log_info "Removing the volumes..."
    $SUDO docker volume prune -f
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to remove the volumes, status: $STATUS"
    else
        log_success "Volumes removed"
    fi
    return $STATUS
}

function remove_the_networks() {
    log_info "Removing the networks..."
    $SUDO docker network prune -f
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to remove the networks, status: $STATUS"
    else
        log_success "Networks removed"
    fi
    return $STATUS
}

function start_the_container() {
    local detached="-d"
    local interactive="-it"
    local gpu_portion=""
    local gpu_type=""

    log_debug "Docker flags: detached: '$detached', interactive: '$interactive'"
    log_info "Checking for GPU type..."
    gpu_type="$(detect_gpu_type)"
    if [ $? -ne 0 ]; then
        log_warning "Failed to detect GPU type, defaulting to no gpu..."
        USE_GPU=$FALSE
    fi
    if [ "$USE_GPU" == "$TRUE" ]; then
        if [ "$gpu_type" == "nvidia" ]; then
            log_success "GPU detected, using NVIDIA runtime..."
            gpu_portion="--gpus=$USE_GPU_PORTION"
        elif [ "$gpu_type" == "amd" ]; then
            log_success "GPU detected, using AMD runtime..."
            gpu_portion="--device /dev/kfd --device /dev/dri"
        else
            log_warning "No GPU detected, skipping NVIDIA and AMD runtime configuration..."
        fi
    else
        log_info "No gpu's detected or usage has been disabled, skipping gpu configuration..."
    fi
    log_success "GPU types checked"
    log_debug "Docker gpu flags: gpu_portion: '$gpu_portion', gpu_type: '$gpu_type'"
    check_if_container_exists
    if [ "$?" == "$TRUE" ]; then
        log_info "Container exists, removing..."
        remove_the_container
        if [ $? -ne 0 ]; then
            log_critical "Failed to remove the container, exiting..."
            exit 1
        fi
    fi
    log_info "Starting the container..."
    log_debug "Running command: $SUDO docker run $detached $interactive $gpu_portion -v $OLLAMA_CACHE_LOCATION_FOLDER:/root/.ollama -p $OLLAMA_HOST_PORT:11434 --name $CONTAINER_NAME $IMAGE_NAME"
    $SUDO docker run $detached $interactive $gpu_portion -v $OLLAMA_CACHE_LOCATION_FOLDER:/root/.ollama -p $OLLAMA_HOST_PORT:11434 --name $CONTAINER_NAME $IMAGE_NAME
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to start the container, status: $STATUS"
    else
        log_success "Container started: '$CONTAINER_NAME'"
    fi
    return $STATUS
}

function stop_the_container() {
    log_info "Stopping the container: '$CONTAINER_NAME'..."
    $SUDO docker stop $CONTAINER_NAME
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to stop the container, status: $STATUS"
    else
        log_success "Container stopped: '$CONTAINER_NAME'"
    fi
    return $STATUS
}

function build_image() {
    log_info "Building the image..."
    $SUDO docker build -t $IMAGE_NAME -f $DOCKERFILE_LOCATION_FILE .
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        log_error "Failed to build the image, status: $STATUS"
    else
        log_success "Image built: '$IMAGE_NAME'"
    fi
    return $STATUS
}

function enter_the_container() {
    log_info "Entering the container: '$CONTAINER_NAME'..."
    if [ ${#CONTAINER_DEFAULT_COMMAND} -eq 0 ]; then
        log_info "Default command is empty, using '/bin/bash'..."
        $SUDO docker exec -it $CONTAINER_NAME /bin/bash
    else
        log_info "Using custom command: '$CONTAINER_DEFAULT_COMMAND'..."
        $SUDO docker exec -it $CONTAINER_NAME $CONTAINER_DEFAULT_COMMAND
    fi
}

function is_nvidia_toolkit_installed() {
    if ! command -v nvidia-ctk &>/dev/null; then
        log_warning "NVIDIA Container Toolkit is NOT installed."
        return $FALSE
    fi

    if $SUDO docker info | grep -q "nvidia"; then
        log_success "NVIDIA Container Toolkit is installed and configured with Docker."
        return $TRUE
    else
        log_warning "NVIDIA Container Toolkit is installed but not configured with Docker."
        return $FALSE
    fi
}

function install_nvidia_container_toolkit() {
    local os=$(detect_os)

    if [[ "$os" == "linux" ]]; then
        # Detect Linux distribution's package manager
        if command -v apt-get &>/dev/null; then
            log_info "Using apt for installation..."
            # Add the NVIDIA repository
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey |
                sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
                sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
                sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
            sudo apt-get update
            # Install the NVIDIA Container Toolkit
            sudo apt-get install -y nvidia-container-toolkit

        elif command -v yum &>/dev/null; then
            log_info "Using yum for installation..."
            # Add the NVIDIA repository
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
                sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
            # Install the NVIDIA Container Toolkit
            sudo yum install -y nvidia-container-toolkit

        elif command -v dnf &>/dev/null; then
            log_info "Using dnf for installation..."
            # Add the NVIDIA repository
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
                sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
            # Install the NVIDIA Container Toolkit
            sudo dnf install -y nvidia-container-toolkit

        else
            log_error "Unsupported Linux package manager. Aborting."
            return 1
        fi

        # Configure Docker to use the NVIDIA driver
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        log_error "NVIDIA Container Toolkit installation and configuration completed."

    elif [[ "$os" == "mac" ]]; then
        log_error "NVIDIA Container Toolkit is not supported on macOS. Aborting."
        return 1
    else
        log_error "Unsupported operating system. Aborting."
        return 1
    fi
}

function is_nvidia_gpu_present() {
    # Check for NVIDIA GPU using lspci
    log_info "Checking for NVIDIA GPU..."
    if lspci | grep -i "nvidia" &>/dev/null; then
        log_success "NVIDIA GPU detected."
        return $TRUE
    else
        log_error "No NVIDIA GPU detected."
        return $FALSE
    fi
}

function install_nvidia_container_toolkit_if_required() {
    is_nvidia_gpu_present
    if [ $? -ne 0 ]; then
        log_warning "No NVIDIA GPU detected, skipping NVIDIA Container Toolkit installation."
        return
    fi
    log_info "Checking if NVIDIA Container Toolkit is installed..."
    is_nvidia_toolkit_installed
    if [ $? -ne 0 ]; then
        log_warning "NVIDIA Container Toolkit is not installed, installing..."
        install_nvidia_container_toolkit
        is_nvidia_toolkit_installed
        if [ $? -ne 0 ]; then
            log_critical "Failed to install NVIDIA Container Toolkit, exiting..."
            exit 1
        fi
    else
        log_success "NVIDIA Container Toolkit is installed."
    fi
}

function remove_ollama() {
    local os="$(detect_os)"

    if [[ "$os" != "linux" ]]; then
        log_error "Unsupported operating system for removing the ollama local binary. skipping."
        return 1
    fi

    log_info "Starting Ollama removal process..."

    log_info "Stopping and disabeling any running Ollama services..."
    sudo systemctl stop ollama &>/dev/null
    sudo systemctl disable ollama &>/dev/null

    log_info "Checking for common installation paths for the Ollama binary and removing..."

    # Check for common installation paths for the Ollama binary
    local ollama_binary_paths=(
        "/usr/local/bin/ollama"
        "/usr/bin/ollama"
        "/opt/ollama/ollama"
    )

    local removed=false
    # Iterate over potential paths and remove if found
    for path in "${ollama_binary_paths[@]}"; do
        if [ -f "$path" ]; then
            log_info "Found Ollama binary at: $path"
            sudo rm -f "$path"
            log_success "Removed: $path"
            removed=true
        fi
    done

    log_info "Removing any related directories or service files..."
    # Remove any related directories
    local ollama_dirs=(
        "/opt/ollama"
        "$HOME/.ollama"
        "/etc/ollama"
    )

    for dir in "${ollama_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_info "Found Ollama directory at: $dir"
            sudo rm -rf "$dir"
            log_success "Removed: $dir"
            removed=true
        fi
    done

    log_info "Removing any related configurations or service files..."
    # Remove related configurations or service files
    local ollama_service_files=(
        "/etc/systemd/system/ollama.service"
        "/usr/lib/systemd/system/ollama.service"
    )

    for service_file in "${ollama_service_files[@]}"; do
        if [ -f "$service_file" ]; then
            log_info "Found Ollama service file at: $service_file"
            sudo rm -f "$service_file"
            log_success "Removed: $service_file"
            removed=true
        fi
    done

    log_info "Removing any related cache files..."
    sudo rm -rf /usr/share/ollama &>/dev/null

    log_info "Removing ollama user..."
    sudo userdel ollama

    log_info "Removing ollama group..."
    sudo groupdel ollama

    log_info "Removing ollama user if previous attempt failed..."
    sudo userdel ollama

    # If nothing was removed
    if [ "$removed" = false ]; then
        log_warning "No Ollama binary or related files were found on this system."
    else
        log_success "Ollama has been successfully removed."
    fi

    # Reload systemd (in case a service was removed)
    if command -v systemctl &>/dev/null; then
        log_info "Reloading systemd daemon..."
        sudo systemctl daemon-reload
    fi
}

function clean_ressources() {
    log_info "The clean resources flag has been set, cleaning the resources..."
    check_if_container_is_running
    if [ "$?" == "$TRUE" ]; then
        log_info "The container is running, stopping..."
        stop_the_container
        if [ $? -ne 0 ]; then
            log_critical "Failed to stop the container, exiting..."
            exit 1
        fi
    fi
    check_if_container_exists
    if [ "$?" == "$TRUE" ]; then
        log_info "Removing the container..."
        remove_the_container
        if [ $? -ne 0 ]; then
            log_critical "Failed to remove the container, exiting..."
            exit 1
        fi
    fi
    check_if_image_exists
    if [ "$?" == "$TRUE" ]; then
        remove_the_image
        if [ $? -ne 0 ]; then
            log_critical "Failed to remove the image, exiting..."
            exit 1
        fi
    fi
    log_info "Cleaning the dockerfile located at: '$DOCKERFILE_LOCATION_FILE'..."
    rm -rf $DOCKERFILE_LOCATION_FILE
    log_success "Dockerfile removed."
    remove_the_docker_build_cache
    if [ $? -ne 0 ]; then
        log_critical "Failed to remove the docker build cache, exiting..."
        exit 1
    fi
    remove_the_volumes
    if [ $? -ne 0 ]; then
        log_critical "Failed to remove the volumes, exiting..."
        exit 1
    fi
    remove_the_networks
    if [ $? -ne 0 ]; then
        log_critical "Failed to remove the networks, exiting..."
        exit 1
    fi
    log_success "Ressources cleaned."
    exit 0
}

function force_update_the_source_dockerfile() {
    log_info "The update dockerfile flag has been set, updating the dockerfile..."
    dump_the_docker_file
    check_if_container_exists
    if [ "$?" == "$TRUE" ]; then
        log_info "Removing the container..."
        remove_the_container
        if [ $? -ne 0 ]; then
            log_critical "Failed to remove the container, exiting..."
            exit 1
        fi
    fi
    check_if_image_exists
    if [ "$?" == "$TRUE" ]; then
        remove_the_image
        if [ $? -ne 0 ]; then
            log_critical "Failed to remove the image, exiting..."
            exit 1
        fi
    fi
    log_success "Dockerfile updated."
}

process_arguments $@
log_info "(c) Script written by Henry Letellier"
check_if_sudo_required_for_docker
# remove_ollama
# install_ollama_if_required
create_ollama_cache_folder
install_nvidia_container_toolkit_if_required

log_info "(c) Script written by Henry Letellier"

if [ "$CLEAN_RESSOURCES" == "$TRUE" ]; then
    clean_ressources
fi
if [ "$UPDATE_THE_DOCKERFILE" == "$TRUE" ]; then
    force_update_the_source_dockerfile
fi
log_info "Checking if the container is running..."
check_if_container_is_running
if [ "$?" == "$TRUE" ]; then
    log_info "The container is running, entering..."
    enter_the_container
else
    log_info "The container is not running, starting if present..."
    check_if_image_exists
    if [ "$?" == "$TRUE" ]; then
        start_the_container
        if [ $? -ne 0 ]; then
            log_critical "Failed to start the container, exiting..."
            exit 1
        fi
        check_if_container_is_running
        if [ "$?" == "$TRUE" ]; then
            log_info "The container is running, entering..."
            enter_the_container
        else
            log_critical "The container is not running, exiting..."
            exit 1
        fi
    else
        log_info "The image is not present, building..."
        if [ ! -f $DOCKERFILE_LOCATION_FILE ]; then
            log_info "Dockerfile not found in location '$DOCKERFILE_LOCATION_FILE', creating it from stored version..."
            dump_the_docker_file
        fi
        build_image
        if [ $? -ne 0 ]; then
            log_critical "Failed to build the image, exiting..."
            exit 1
        fi
        start_the_container
        if [ $? -ne 0 ]; then
            log_critical "Failed to start the container, exiting..."
            exit 1
        fi
        check_if_container_is_running
        if [ "$?" == "$TRUE" ]; then
            log_success "The container is running, entering..."
            enter_the_container
        else
            log_critical "The container is not running, exiting..."
            exit 1
        fi
    fi
fi

echo "(c) Script written by Henry Letellier"
