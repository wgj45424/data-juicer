# 使用轻量级 Python 镜像（Ubuntu 基础，但无 GPU）
FROM python:3.11-slim

WORKDIR /app

# 设置非交互模式 & 中文镜像加速（可选）
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    UV_HTTP_TIMEOUT=600

# 安装极简系统依赖（仅 git + 编译基础，用于可能的 pip 编译）
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 升级 pip 并安装 uv（可选，也可直接用 pip）
RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple uv

# 复制依赖文件
COPY requirements.txt .

# 仅安装核心依赖（不含 vision / recognize-anything）
# 注意：Data-Juicer 的 core extra 已包含 ray
RUN uv pip install --no-cache-dir \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    --system \
    "data-juicer[core]"

# 或者：如果你是从源码构建（推荐用于离线一致性）
# COPY . .
# RUN uv pip install --no-cache-dir -e .[core] -i https://pypi.tuna.tsinghua.edu.cn/simple --system

# 下载 NLTK 数据（按需，可移除）
RUN python -c "import nltk; nltk.download('punkt', quiet=True); nltk.download('averaged_perceptron_tagger', quiet=True)"

# 默认命令
CMD ["python", "-m", "data_juicer.run", "--help"]
