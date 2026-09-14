# LightOps Toolkit

一套面向单机服务器的轻量自动化运维工具集，使用 Shell、Python、MySQL、Linux 和 cron 实现。

## 功能特性

- 服务器巡检：CPU、内存、磁盘、端口、关键进程
- MySQL 定时备份：自动 dump、gzip 压缩、过期备份清理
- 日志分析：统计 ERROR/WARN/CRITICAL 关键字并输出 Top 错误
- 端口监控：检测 TCP 端口存活并输出告警
- cron 周期执行
- 完善的运行日志、错误处理机制
- 故障模拟与测试案例
- Git 版本管理友好的目录结构

## 项目结构

```
lightops-toolkit/
├── config/                # 配置文件目录
│   ├── lightops.env.example    # 环境变量配置模板
│   ├── mysql.cnf.example       # MySQL 配置模板
│   ├── ports.conf             # 端口监控配置
│   └── processes.conf         # 进程监控配置
├── cron/                  # 定时任务配置
│   └── lightops.cron         # 示例定时任务配置
├── docs/                  # 文档目录
│   ├── INSTALL.md             # 安装说明
│   ├── TEST_CASES.md         # 测试用例
│   └── TROUBLESHOOTING.md    # 故障排除指南
├── logs/                  # 运行日志目录
├── reports/               # 报告输出目录
├── backups/              # 备份文件目录
├── sql/                  # SQL 脚本目录
│   └── inti_demo.sql         # 示例 SQL 脚本
├── sample_logs/          # 示例日志文件
│   └── app.log               # 示例应用日志
├── scripts/              # 脚本目录
│   ├── common.sh             # 通用函数库
│   ├── system_check.sh       # 系统巡检脚本
│   ├── mysql_backup.sh       # MySQL 备份脚本
│   ├── log_analyzer.py       # 日志分析工具
│   └── port_monitor.py       # 端口监控工具
├── tests/                # 测试目录
│   ├── generate_sample_log.py # 生成测试日志
│   └── mock_tcp_server.py    # 模拟 TCP 服务器
├── .gitignore            # Git 忽略规则
└── README.md             # 项目说明
```

## 快速开始

### 安装部署

1. 创建项目目录：
```bash
sudo mkdir -p /opt/lightops
sudo chown -R "$USER":"$USER" /opt/lightops
```

2. 部署项目：
```bash
# 方式一：复制项目文件
cp -r <项目路径> /opt/lightops/

# 方式二：使用 Git 克隆
git clone <仓库地址> /opt/lightops
```

3. 初始化配置：
```bash
cd /opt/lightops
cp config/lightops.env.example config/lightops.env
cp config/mysql.cnf.example config/mysql.cnf
chmod +x scripts/*.sh scripts/*.py
chmod 600 config/mysql.cnf
```

### 使用说明

1. 服务器巡检：
```bash
./scripts/system_check.sh
```

2. 日志分析：
```bash
python3 scripts/log_analyzer.py \
    --log sample_logs/app.log \
    --output reports/log_report.txt
```

3. 端口检测：
```bash
python3 scripts/port_monitor.py \
    --config config/ports.conf
```

4. 数据库备份：
```bash
./scripts/mysql_backup.sh
```

### 定时任务配置

参考 `cron/lightops.cron` 文件，通过以下命令添加定时任务：
```bash
crontab -e
```


## 测试与维护

1. 运行测试用例：
```bash
# 生成测试日志
python3 tests/generate_sample_log.py

# 启动模拟服务器
python3 tests/mock_tcp_server.py
```

2. 查看测试案例：
```bash
cat docs/TEST_CASES.md
```

3. 故障排除：
```bash
cat docs/TROUBLESHOOTING.md
```

## 开发与贡献

1. 使用 Git 管理代码
2. 遵循项目目录结构
3. 更新相关文档
4. 添加适当的测试用例

## 版本历史

- v1.0.0
  - 初始版本发布
  - 实现基础运维功能
  - 完善文档和测试用例