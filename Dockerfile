# 使用轻量 Python 镜像（纯 CPU）
FROM python:3.11-slim

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    UV_HTTP_TIMEOUT=600

# 安装基础编译依赖（用于可能的 C 扩展）
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv（可选，也可用 pip）
RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple uv

# 复制整个项目（包含 pyproject.toml）
COPY . .

# 安装 data-juicer[core]（从源码，自动解析 pyproject.toml）
RUN uv pip install --no-cache-dir \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    --system \
    -e .[core]

# 下载 NLTK 数据（按需）
RUN python -c "import nltk; nltk.download('punkt', quiet=True); nltk.download('averaged_perceptron_tagger', quiet=True)"

CMD ["python", "-m", "data_juicer.run", "--help"]
