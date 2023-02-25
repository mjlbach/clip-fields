FROM docker.io/nvidia/cuda:11.8.0-devel-ubuntu22.04

# Prevent stop building ubuntu at time zone selection.  
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Install micromamba
ENV MAMBA_ROOT_PREFIX /micromamba
RUN  curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C / bin/micromamba
RUN micromamba shell init --shell=bash --prefix=/micromamba

# Copy requirements.txt
COPY ./requirements.txt /requirements.txt

# Environemntal variables for compiling cuda based dependencies
ENV CUDA_ARCHITECTURES="89;86;75"
ENV TCNN_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES}
ENV CMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES}
ENV TORCH_CUDA_ARCH_LIST="8.9;8.6;7.5"
ENV FORCE_CUDA="1"

# Install packages
RUN micromamba create --yes -n clip-field -c conda-forge python=3.8 && micromamba clean -afy

# Set virtual environment first in path
ENV PATH /micromamba/envs/clip-field/bin:$PATH

# Install dependencies, prefer pip
RUN pip install --no-cache-dir --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu118
RUN pip install --no-cache-dir -r requirements.txt

# Compile grid encoder
COPY ./gridencoder /gridencoder
RUN cd gridencoder && python setup.py install

# Multistage build
FROM docker.io/nvidia/cuda:11.8.0-runtime-ubuntu22.04
COPY --from=0 /micromamba /micromamba
COPY --from=0 /gridencoder /gridencoder

# Prevent stop building ubuntu at time zone selection.  
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libgl1 \
    libgomp1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set virtual environment first in path
ENV PATH /micromamba/envs/clip-field/bin:$PATH

# Copy in clip-fields
COPY . /clip-fields
WORKDIR /clip-fields
