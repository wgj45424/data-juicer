# ========== 阶段1：构建依赖（仅编译需要，不进入最终镜像） ==========
FROM python:3.10-slim AS builder

# 替换为国内debian源，加速安装
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# 仅安装CPU编译依赖（完全剔除GPU相关系统库）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libgomp1 \  # 仅CPU并行计算需要，无GPU相关
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 设置pip国内源，禁用GPU相关依赖下载
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# 关键：禁用CUDA/GPU相关环境变量
ENV CUDA_VISIBLE_DEVICES=""
ENV FORCE_CPU=1

# 安装纯CPU版依赖（剔除所有GPU相关包）
RUN pip install --no-cache-dir \
    --prefix=/tmp/python \
    # Data-Juicer核心包（强制CPU版，排除GPU依赖）
    py-data-juicer>=1.4.0 \
    # Ray纯CPU版（排除ray[gpu]）
    ray[default]>=2.0.0 \
    # 纯CPU基础依赖（无CUDA/torch等GPU包）
    pandas>=2.0.0 \
    numpy>=1.24.0 \
    tqdm>=4.65.0 \
    PyYAML>=6.0 \
    regex>=2023.10.3 \
    ftfy>=6.1.1 \
    langdetect>=1.0.9 \
    # 明确排除GPU相关依赖
    --no-deps torch cpuonly \
    --no-deps tensorflow-cpu

# ========== 阶段2：最终镜像（仅保留CPU运行时） ==========
FROM python:3.10-slim

LABEL maintainer="your-name <your-email@example.com>"
LABEL description="Pure CPU Data-Juicer (no GPU modules at all)"

WORKDIR /app

# 仅保留CPU运行必需的系统库（无GPU驱动/库）
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \  # CPU并行计算必需，无GPU相关
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# 从构建阶段拷贝纯CPU依赖（无GPU模块）
COPY --from=builder /tmp/python /usr/local

# 强制CPU运行环境变量（彻底禁用GPU检测）
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=""
ENV FORCE_CPU=1
ENV PATH="/usr/local/bin:${PATH}"

# 验证：仅导入CPU算子，排除GPU相关模块
RUN python -c "import data_juicer; \
    from data_juicer.operators import clean_unicode, filter_length; \
    # 验证无GPU模块导入
    assert 'cuda' not in dir(data_juicer), 'GPU module detected!'; \
    print('Pure CPU Data-Juicer installed successfully')" && \
    # 清理所有冗余文件
    rm -rf ~/.cache/pip /tmp/* /var/tmp/*

# 容器启动默认进入bash
CMD ["/bin/bash"]
