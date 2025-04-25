# DeepSeek Docker Deployment Script

> Script written by Henry Letellier  
>
> Dependencies: docker, curl, and sudo  

This script is used to deploy DeepSeek (currently, the default version is 14B, but you can change the variable to 7B, which is commented out).  

The script is "intelligent"—meaning it checks whether the Docker container exists and is running:  

- If it exists and is running, it puts you inside the container.  
- Otherwise, it checks if the image is available:  
  - If it is, it deploys the container and puts you inside.  
  - If not, it generates a Dockerfile in `/tmp/deep-seek`, builds the image, deploys the container, and puts you inside.  

Once inside the container, you can run the `start_model` script to launch the AI. Otherwise, a BusyBox shell is available in the container for exploration. The script relies on the following environment variables:  

- `MODEL_WEIGHT` (default: 14B)  
- `MODEL_NAME` (default: deepseek-r1)  

## Script Configuration Options  

v1.0.0's options

- `-h, --help` : Display this help message.  
- `-m, --model-name` : The model name to use. Default: `deepseek-r1`  
- `-w, --model-weight` : The model weight to use. Default: `7b`  
- `-c, --container-name` : The container name to use. Default: `deep-seek-container`  
- `-i, --image-name` : The image name to use. Default: `deep-seek-image`  
- `-d, --dockerfile-location-folder` : The folder where the Dockerfile is stored. Default: `/tmp/deep-seek`  
- `-o, --ollama-cache-location-folder` : The folder where the Ollama cache is stored. Default: `ollama_cache`  
- `-p, --ollama-host-port` : The host port for Ollama. Default: `11434`  
- `-v, --ollama-version` : The version of Ollama to use. Default: `0.5.7`  
- `-g, --use-gpu` : Use the GPU for the container. Default: `true`  
- `-gp, --use-gpu-portion` : The portion of the GPU to use. Default: `all`  

v2.0.0's options

- -h,   --help                         Display this help message.
- -m,   --model-name                   The model name to use. Default: deepseek-r1
- -w,   --model-weight                 The model weight to use. Default: 7b
- -c,   --container-name               The container name to use. Default: deep-seek-container
- -i,   --image-name                   The image name to use. Default: deep-seek-image
- -d,   --dockerfile-location-folder   The location folder to store the Dockerfile. Default: /tmp/deep-seek
- -o,   --ollama-cache-location-folder The location folder to store the ollama cache. Default: ollama_cache
- -p,   --ollama-host-port             The host port to use for ollama. Default: 11434
- -v,   --ollama-version               The version of ollama to use. Default: 0.5.7
- -u,   --update                       Force the update of the dockerfile used to build the image (this is if you updated the script).
- -g,   --use-gpu                      Use the GPU for the container. Default: true
- -gp,  --use-gpu-portion              The portion of the GPU to use. Default: all
- -cr,  --custom-run                   Specify a command you wish to run instead of the default one. Default: /bin/bash
- -cls, --clean                        Clean the docker container, image and file.
- -dec, --dockerfile-entry-command     The command to run when the container starts. Default: /bin/ollama serve
- -deb, --debug                        Enable debug mode. Default: false

In short, no installation is required for a fully local AI (aside from the initial model download).  

## License & Sharing  

You are free to use, modify, and share this script as you wish. Attribution is **not required** but would be **strongly appreciated**. Contributions and improvements are welcome!  

## Versioning
>
> When I bring big iterations to a script, I change the number, script versions are generally retro-compatible because I build upon the previous one.
>
> Here the version number does not mean much appart from helping you track the different versions of the script.
>
> If there is a breaking change, this will be told in the changelog of the version

V1.0.0:
> This is the initial script that deploys a docker container with the AI of your choice

v2.0.0:
> This is a script that now has coloured logging, more options and a dockerfile that is a bit more customisable.
> The help section has these new options:
>> -u,   --update                       Force the update of the dockerfile used to build the image (this is if you updated the script).
>> -cr,  --custom-run                   Specify a command you wish to run instead of the default one. Default: /bin/bash
>> -cls, --clean                        Clean the docker container, image and file.
>> -dec, --dockerfile-entry-command     The command to run when the container starts. Default: /bin/ollama serve
>> -deb, --debug                        Enable debug mode. Default: false

## Disclaimer  

This script is provided **as is**, without any warranty of any kind. Use it at your own risk.  
It has been tested only on **Ubuntu 24.04 LTS**, and compatibility with other systems is **not guaranteed**.  
