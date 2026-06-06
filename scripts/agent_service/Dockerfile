FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# 日志输出
ENV PYTHONUNBUFFERED=1

# 默认命令
CMD ["python", "main.py", "daily-all"]
