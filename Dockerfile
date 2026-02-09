# 基础镜像：Python 3.10-slim（轻量化，仅含核心Python环境）
FROM python:3.10-slim

# 维护者信息（可选）
LABEL maintainer="your-name <your-email@example.com>"
LABEL description="Lightweight Data-Juicer CPU version with core operators only (Ray excluded, auto-install disabled)"

# 设置工作目录
WORKDIR /app

# 设置关键环境变量
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    DJ_AUTO_INSTALL=0

# 安装系统依赖（仅保留 Data-Juicer 核心算子必需的系统库）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libgomp1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖（使用官方 data-juicer 包，不包含 Ray 执行逻辑）
RUN pip install --no-cache-dir \
    data-juicer>=1.4.0 \
    pandas>=2.0.0 \
    numpy>=1.24.0 \
    tqdm>=4.65.0 \
    PyYAML>=6.0 \
    regex>=2023.10.3 \
    ftfy>=6.1.1 \
    langdetect>=1.0.9 \
    && rm -rf ~/.cache/pip

# 验证安装：检查版本、dj 命令是否存在、帮助是否可用
RUN python -c "import data_juicer; print('Data-Juicer installed:', data_juicer.__version__)" \
    && which dj \
    && dj --help > /dev/null

# 默认启动 bash（便于调试）
CMD ["/bin/bash"]
