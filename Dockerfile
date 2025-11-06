# Dockerfile
# ========= 多阶段构建：安装依赖 =========
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# 只复制 requirements.txt 先安装依赖（利用缓存）
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# ========= 最终运行镜像 =========
FROM python:3.12-slim

WORKDIR /app

# 从 builder 阶段拷贝已安装的依赖
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# 只复制部署真正需要的文件
COPY app.py .
COPY requirements.txt .
COPY zeabur-data zeabur-data/

# FastAPI + Uvicorn 默认端口
EXPOSE 8000

# 健康检查（已修复：移除 --start5s，兼容所有 Docker 版本）
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import requests; exit(0 if requests.get('http://localhost:8000').status_code == 200 else 1)" || exit 1

# 精确匹配你本地的启动命令
CMD ["python", "app.py", "--encrypted", "zeabur-data/silasvivid-outlook.data.enc", "--run-http"]
