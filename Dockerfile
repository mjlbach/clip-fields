FROM docker.io/nvidia/cuda:11.8.0-devel-ubuntu22.04

# Prevent stop building ubuntu at time zone selection.  
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    ninja-build \
    curl \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*


# Install micromamba
ENV MAMBA_ROOT_PREFIX /micromamba
RUN  curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C / bin/micromamba

COPY . /clip-fields
WORKDIR /clip-fields

# Environemntal variables for compiling cuda based dependencies
ENV CUDA_ARCHITECTURES="89;86;75"
ENV TCNN_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES}
ENV CMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES}
ENV TORCH_CUDA_ARCH_LIST="8.9;8.6;7.5"
ENV FORCE_CUDA="1"

# Install packages
RUN micromamba env create -f environment.yml
RUN micromamba shell init --shell=bash --prefix=/micromamba
ENV PATH /micromamba/envs/clip-field/bin:$PATH

# Compile grid encoder
RUN cd gridencoder && python setup.py install && cd /clip-field
