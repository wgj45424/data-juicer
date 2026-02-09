FROM python:3.10-slim

LABEL maintainer="your-name <your-email@example.com>"
LABEL description="Lightweight Data-Juicer CPU version (installed from GitHub source)"

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    DJ_AUTO_INSTALL=0

# 安装系统依赖（关键：包含 libsamplerate-dev 和 git）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    git \
    libgomp1 \
    python3-dev \
    pkg-config \
    libsamplerate0-dev \          # ← 关键：解决 samplerate 编译问题
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 升级构建工具（推荐）
RUN pip install --upgrade pip setuptools wheel

# 从 GitHub 安装 Data-Juicer（使用已知稳定 tag）
# 查看 tags: https://github.com/alibaba/data-juicer/tags
RUN pip install --no-cache-dir \
    "git+https://github.com/alibaba/data-juicer.git@v1.3.2" \
    && rm -rf ~/.cache/pip

# 验证安装
RUN python -c "import data_juicer; print('Data-Juicer installed:', data_juicer.__version__)" \
    && which dj \
    && dj --help > /dev/null

CMD ["/bin/bash"]
