# 基础镜像：Python 3.10-slim（轻量化，仅含核心Python环境）
FROM python:3.10-slim

# 维护者信息（可选）
LABEL maintainer="your-name <your-email@example.com>"
LABEL description="Lightweight Data-Juicer CPU version with core operators only (Ray excluded)"

# 设置工作目录
WORKDIR /app

# 设置环境变量：避免Python生成pyc文件、强制stdout/stderr无缓冲
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# 设置pip国内源（加速安装）
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

# 安装系统依赖（仅保留Data-Juicer核心算子必需的系统库）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装Data-Juicer核心依赖（移除Ray，仅保留CPU核心算子依赖）
RUN pip install --no-cache-dir \
    # Data-Juicer核心包（CPU版）
    py-data-juicer>=1.4.0 \
    # 基础依赖（核心算子必需，移除ray[default]）
    pandas>=2.0.0 \
    numpy>=1.24.0 \
    tqdm>=4.65.0 \
    PyYAML>=6.0 \
    # 基础文本处理依赖（核心算子用）
    regex>=2023.10.3 \
    ftfy>=6.1.1 \
    langdetect>=1.0.9 \
    # 清理pip缓存
    && rm -rf ~/.cache/pip

# 验证安装：仅检查Data-Juicer（移除Ray的验证）
RUN python -c "import data_juicer; print('Data-Juicer installed:', data_juicer.__version__)"

# 配置环境变量：确保dj命令生效
# ENV PATH="/app:${PATH}"

# 容器启动默认进入bash
CMD ["/bin/bash"]
