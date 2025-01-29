#!/bin/bash

echo "This script is provided as if and without any warranty, it has only been tested on a Ubuntu LTS 24.04"
echo "(c) Script written by Henry Letellier"

function check_if_sudo_required_for_docker() {
    echo "Checking if sudo is required for docker..."
    if docker ps >/dev/null 2>&1; then
        echo "Sudo is not required."
        SUDO=""
    else
        echo "Sudo is required, setting."
        SUDO="sudo"
    fi
}

function check_if_help() {
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  -h, --help          Display this help message."
        echo "  -m, --model-name    The model name to use. Default: deepseek-r1"
        echo "  -w, --model-weight  The model weight to use. Default: 7b"
        echo "  -c, --container-name The container name to use. Default: deep-seek-container"
        echo "  -i, --image-name    The image name to use. Default: deep-seek-image"
        echo "  -d, --dockerfile-location-folder The location folder to store the Dockerfile. Default: /tmp/deep-seek"
        echo "  -o, --ollama-cache-location-folder The location folder to store the ollama cache. Default: ollama_cache"
        echo "  -p, --ollama-host-port The host port to use for ollama. Default: 11434"
        echo "  -v, --ollama-version The version of ollama to use. Default: 0.5.7"
        echo "  -g, --use-gpu       Use the GPU for the container. Default: true"
        echo "  -gp, --use-gpu-portion The portion of the GPU to use. Default: all"
        exit 0
    fi
}

check_if_help $1

MODEL_NAME="deepseek-r1"

MODEL_WEIGHT="7b" #"14b" #"7b"

CONTAINER_NAME="deep-seek-container"

IMAGE_NAME="deep-seek-image"

SUDO=""
check_if_sudo_required_for_docker

DOCKERFILE_LOCATION_FOLDER=/tmp/deep-seek

DOCKERFILE_LOCATION_FILE=$DOCKERFILE_LOCATION_FOLDER/Dockerfile

OLLAMA_CACHE_LOCATION_FOLDER=ollama_cache

OLLAMA_HOST_PORT=11434

OLLAMA_VERSION="0.5.7"

TRUE=0
FALSE=1

USE_GPU=$TRUE
USE_GPU_PORTION="all"

function process_arguments() {
    while [ "$1" != "" ]; do
        case $1 in
        -m | --model-name)
            shift
            MODEL_NAME=$1
            ;;
        -w | --model-weight)
            shift
            MODEL_WEIGHT=$1
            ;;
        -c | --container-name)
            shift
            CONTAINER_NAME=$1
            ;;
        -i | --image-name)
            shift
            IMAGE_NAME=$1
            ;;
        -d | --dockerfile-location-folder)
            shift
            DOCKERFILE_LOCATION_FOLDER=$1
            DOCKERFILE_LOCATION_FILE=$DOCKERFILE_LOCATION_FOLDER/Dockerfile
            ;;
        -o | --ollama-cache-location-folder)
            shift
            OLLAMA_CACHE_LOCATION_FOLDER=$1
            ;;
        -p | --ollama-host-port)
            shift
            OLLAMA_HOST_PORT=$1
            ;;
        -v | --ollama-version)
            shift
            OLLAMA_VERSION=$1
            ;;
        -g | --use-gpu)
            shift
            USE_GPU=$1
            ;;
        -gp | --use-gpu-portion)
            shift
            USE_GPU_PORTION=$1
            ;;
        *)
            echo "Invalid argument: $1"
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
    echo "Creating the Dockerfile location folder..."
    mkdir -p $DOCKERFILE_LOCATION_FOLDER
    echo "Checking for GPU type..."
    gpu_type="$(detect_gpu_type)"
    if [ $? -ne 0 ]; then
        echo "Failed to detect GPU type, defaulting to no gpu..."
        container_version=""
    fi
    if [ "$gpu_type" == "amd" ]; then
        echo "GPU detected, using AMD runtime..."
        if [ "$container_version" != "latest" ] || [ "$container_version" != "" ]; then
            container_version="${container_version}-rocm"
        else
            container_version="rocm"
        fi
    elif [ "$gpu_type" == "nvidia" ]; then
        echo "GPU detected, using NVIDIA runtime..."
    else
        echo "No GPU detected, skipping NVIDIA and AMD runtime configuration..."
    fi
    echo "Dumping the Dockerfile..."
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
echo "Starting model \${MODEL_NAME}, model size: \${MODEL_WEIGHT}"\n\\
echo "To cancel an ongoing query, press CTRL+C"\n\\
echo "To exit the model enter /exit"\n\\
/bin/ollama run \${MODEL_NAME}:\${MODEL_WEIGHT} \$@\n\\
' > /start_model \\
    && chmod +x /start_model

# Get the latest version of the llm model
RUN /my_busybox/sh -c "/entrypoint.sh"

# Set the ENTRYPOINT to an interactive shell to pull the latest version of the llm model
ENTRYPOINT ["/my_busybox/sh"]

# Default CMD that can be overridden with another command
CMD ["-c", "/bin/ollama serve"]
EOF
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
    echo "Creating the ollama cache folder (if it is not a volume)..."
    if [[ "$OLLAMA_CACHE_LOCATION_FOLDER" != *"/"* ]]; then
        echo "The ollama cache folder is a volume, skipping creation..."
        return
    fi
    echo "The ollama cache folder is not a volume, creating..."
    mkdir -p $OLLAMA_CACHE_LOCATION_FOLDER
}

function check_if_ollama_is_installed() {
    echo "Checking if ollama is installed..."
    if ollama --version >/dev/null 2>&1; then
        echo "Ollama is installed."
        return $TRUE
    else
        echo "Ollama is not installed."
        return $FALSE
    fi
}

function install_ollama_if_required() {
    echo "Installing ollama (if required)"
    is_system_linux
    if [ "$?" == "$FALSE" ]; then
        echo "Unsupported OS (by this script), skipping step..."
        return
    fi
    check_if_ollama_is_installed
    if [ $? -ne 0 ]; then
        echo "Ollama is not installed, installing..."
        curl -fsSL https://ollama.com/install.sh | sh
        check_if_ollama_is_installed
        if [ $? -ne 0 ]; then
            echo "Failed to install ollama, exiting..."
            exit 1
        fi
    else
        echo "Ollama is installed."
    fi
}

function check_if_container_exists() {
    echo "Checking if the container exists..."
    if $SUDO docker ps -a | grep $CONTAINER_NAME >/dev/null; then
        echo "Container exists."
        return $TRUE
    else
        echo "Container does not exist."
        return $FALSE
    fi
}

function check_if_image_exists() {
    echo "Checking if the image exists..."
    if $SUDO docker images | grep $IMAGE_NAME >/dev/null; then
        echo "Image exists."
        return $TRUE
    else
        echo "Image does not exist."
        return $FALSE
    fi
}

function remove_the_container() {
    echo "Removing the container..."
    $SUDO docker rm -f $CONTAINER_NAME
}

function start_the_container() {
    local detached="-d"
    local interactive="-it"
    local gpu_portion=""
    local gpu_type=""

    echo "Checking for GPU type..."
    gpu_type="$(detect_gpu_type)"
    if [ $? -ne 0 ]; then
        echo "Failed to detect GPU type, defaulting to no gpu..."
        USE_GPU=$FALSE
    fi
    if [ "$USE_GPU" == "$TRUE" ]; then
        if [ "$gpu_type" == "nvidia" ]; then
            echo "GPU detected, using NVIDIA runtime..."
            gpu_portion="--gpus=$USE_GPU_PORTION"
        elif [ "$gpu_type" == "amd" ]; then
            echo "GPU detected, using AMD runtime..."
            gpu_portion="--device /dev/kfd --device /dev/dri"
        else
            echo "No GPU detected, skipping NVIDIA and AMD runtime configuration..."
        fi
    else
        echo "No gpu's detected or usage has been disabled, skipping gpu configuration..."
    fi
    echo "GPU types checked"
    check_if_container_exists
    if [ "$?" == "$TRUE" ]; then
        echo "Container exists, removing..."
        remove_the_container
        if [ $? -ne 0 ]; then
            echo "Failed to remove the container, exiting..."
            exit 1
        fi
    fi
    echo "Starting the container..."
    $SUDO docker run $detached $interactive $gpu_portion -v $OLLAMA_CACHE_LOCATION_FOLDER:/root/.ollama -p $OLLAMA_HOST_PORT:11434 --name $CONTAINER_NAME $IMAGE_NAME
}

function build_image() {
    echo "Building the image..."
    $SUDO docker build -t $IMAGE_NAME -f $DOCKERFILE_LOCATION_FILE .
}

function enter_the_container() {
    echo "Entering the container..."
    $SUDO docker exec -it $CONTAINER_NAME /bin/bash
}

function is_nvidia_toolkit_installed() {
    if ! command -v nvidia-ctk &>/dev/null; then
        echo "NVIDIA Container Toolkit is NOT installed."
        return $FALSE
    fi

    if $SUDO docker info | grep -q "nvidia"; then
        echo "NVIDIA Container Toolkit is installed and configured with Docker."
        return $TRUE
    else
        echo "NVIDIA Container Toolkit is installed but not configured with Docker."
        return $FALSE
    fi
}

function install_nvidia_container_toolkit() {
    local os=$(detect_os)

    if [[ "$os" == "linux" ]]; then
        # Detect Linux distribution's package manager
        if command -v apt-get &>/dev/null; then
            echo "Using apt for installation..."
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
            echo "Using yum for installation..."
            # Add the NVIDIA repository
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
                sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
            # Install the NVIDIA Container Toolkit
            sudo yum install -y nvidia-container-toolkit

        elif command -v dnf &>/dev/null; then
            echo "Using dnf for installation..."
            # Add the NVIDIA repository
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
                sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
            # Install the NVIDIA Container Toolkit
            sudo dnf install -y nvidia-container-toolkit

        else
            echo "Unsupported Linux package manager. Aborting."
            return 1
        fi

        # Configure Docker to use the NVIDIA driver
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        echo "NVIDIA Container Toolkit installation and configuration completed."

    elif [[ "$os" == "mac" ]]; then
        echo "NVIDIA Container Toolkit is not supported on macOS. Aborting."
        return 1
    else
        echo "Unsupported operating system. Aborting."
        return 1
    fi
}

function is_nvidia_gpu_present() {
    # Check for NVIDIA GPU using lspci
    echo "Checking for NVIDIA GPU..."
    if lspci | grep -i "nvidia" &>/dev/null; then
        echo "NVIDIA GPU detected."
        return $TRUE
    else
        echo "No NVIDIA GPU detected."
        return $FALSE
    fi
}

function install_nvidia_container_toolkit_if_required() {
    is_nvidia_gpu_present
    if [ $? -ne 0 ]; then
        echo "No NVIDIA GPU detected, skipping NVIDIA Container Toolkit installation."
        return
    fi
    echo "Checking if NVIDIA Container Toolkit is installed..."
    is_nvidia_toolkit_installed
    if [ $? -ne 0 ]; then
        echo "NVIDIA Container Toolkit is not installed, installing..."
        install_nvidia_container_toolkit
        is_nvidia_toolkit_installed
        if [ $? -ne 0 ]; then
            echo "Failed to install NVIDIA Container Toolkit, exiting..."
            exit 1
        fi
    else
        echo "NVIDIA Container Toolkit is installed."
    fi
}

function remove_ollama() {
    local os="$(detect_os)"

    if [[ "$os" != "linux" ]]; then
        echo "Unsupported operating system for removing the ollama local binary. skipping."
        return 1
    fi

    echo "Starting Ollama removal process..."

    echo "Stopping and disabeling any running Ollama services..."
    sudo systemctl stop ollama &>/dev/null
    sudo systemctl disable ollama &>/dev/null

    echo "Checking for common installation paths for the Ollama binary and removing..."

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
            echo "Found Ollama binary at: $path"
            sudo rm -f "$path"
            echo "Removed: $path"
            removed=true
        fi
    done

    echo "Removing any related directories or service files..."
    # Remove any related directories
    local ollama_dirs=(
        "/opt/ollama"
        "$HOME/.ollama"
        "/etc/ollama"
    )

    for dir in "${ollama_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "Found Ollama directory at: $dir"
            sudo rm -rf "$dir"
            echo "Removed: $dir"
            removed=true
        fi
    done

    echo "Removing any related configurations or service files..."
    # Remove related configurations or service files
    local ollama_service_files=(
        "/etc/systemd/system/ollama.service"
        "/usr/lib/systemd/system/ollama.service"
    )

    for service_file in "${ollama_service_files[@]}"; do
        if [ -f "$service_file" ]; then
            echo "Found Ollama service file at: $service_file"
            sudo rm -f "$service_file"
            echo "Removed: $service_file"
            removed=true
        fi
    done

    echo "Removing any related cache files..."
    sudo rm -rf /usr/share/ollama &>/dev/null

    echo "Removing ollama user..."
    sudo userdel ollama

    echo "Removing ollama group..."
    sudo groupdel ollama

    echo "Removing ollama user if previous attempt failed..."
    sudo userdel ollama

    # If nothing was removed
    if [ "$removed" = false ]; then
        echo "No Ollama binary or related files were found on this system."
    else
        echo "Ollama has been successfully removed."
    fi

    # Reload systemd (in case a service was removed)
    if command -v systemctl &>/dev/null; then
        echo "Reloading systemd daemon..."
        sudo systemctl daemon-reload
    fi
}

process_arguments $@
echo "(c) Script written by Henry Letellier"
check_if_sudo_required_for_docker
# remove_ollama
# install_ollama_if_required
create_ollama_cache_folder
install_nvidia_container_toolkit_if_required

echo "(c) Script written by Henry Letellier"
echo "Checking if the container is running..."
check_if_container_exists
if [ "$?" == "$TRUE" ]; then
    echo "The container is running, entering..."
    enter_the_container
else
    echo "The container is not running, starting if present..."
    check_if_image_exists
    if [ "$?" == "$TRUE" ]; then
        start_the_container
        if [ $? -ne 0 ]; then
            echo "Failed to start the container, exiting..."
            exit 1
        fi
        check_if_container_exists
        if [ "$?" == "$TRUE" ]; then
            echo "The container is running, entering..."
            enter_the_container
        else
            echo "The container is not running, exiting..."
            exit 1
        fi
    else
        echo "The image is not present, building..."
        dump_the_docker_file
        build_image
        if [ $? -ne 0 ]; then
            echo "Failed to build the image, exiting..."
            exit 1
        fi
        start_the_container
        if [ $? -ne 0 ]; then
            echo "Failed to start the container, exiting..."
            exit 1
        fi
        check_if_container_exists
        if [ "$?" == "$TRUE" ]; then
            echo "The container is running, entering..."
            enter_the_container
        else
            echo "The container is not running, exiting..."
            exit 1
        fi
    fi
fi

echo "(c) Script written by Henry Letellier"
