# 安装说明

## 1. 基础环境

检查系统：

```bash
cat /etc/centos-release
uname -r
```

安装常用工具。

CentOS 7:

```bash
sudo yum install -y git python3 gzip cronie
```

CentOS Stream / RHEL-like 8/9:

```bash
sudo dnf install -y git python3 gzip cronie
```

启用 cron:

```bash
sudo systemctl enable --now crond
systemctl status crond
```

## 2. 项目目录

```bash
sudo mkdir -p /opt/lightops
sudo chown -R "$USER":"$USER" /opt/lightops
```

将仓库内容复制到 `/opt/lightops` 后：

```bash
cd /opt/lightops
cp config/lightops.env.example config/lightops.env
cp config/mysql.cnf.example config/mysql.cnf
chmod +x scripts/*.sh scripts/*.py
chmod 600 config/mysql.cnf
```

## 3. 配置 MySQL

编辑：

```bash
vi config/mysql.cnf
```

示例：

```ini
[client]
user=backup_user
password=your_password
host=127.0.0.1
port=3306
```

编辑：

```bash
vi config/lightops.env
```

将：

```bash
MYSQL_DATABASE=lightops_demo
```

替换为你的数据库名。

## 4. 创建数据库备份用户

登录数据库：

```bash
mysql -uroot -p
```

执行：

```sql
CREATE DATABASE IF NOT EXISTS lightops_demo;

CREATE USER IF NOT EXISTS 'backup_user'@'localhost'
IDENTIFIED BY 'ChangeThisPassword!';

GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES
ON lightops_demo.*
TO 'backup_user'@'localhost';

FLUSH PRIVILEGES;
```

如果 `mysql.cnf` 使用的是 `127.0.0.1`，MySQL 账号 Host 规则可能需要对应创建：

```sql
CREATE USER IF NOT EXISTS 'backup_user'@'127.0.0.1'
IDENTIFIED BY 'ChangeThisPassword!';

GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES
ON lightops_demo.*
TO 'backup_user'@'127.0.0.1';

FLUSH PRIVILEGES;
```

## 5. 手工测试

```bash
cd /opt/lightops

./scripts/system_check.sh

python3 scripts/log_analyzer.py \
  --log sample_logs/app.log \
  --output reports/log_report.txt

python3 scripts/port_monitor.py \
  --config config/ports.conf \
  --log logs/port_monitor.log

./scripts/mysql_backup.sh
```

## 6. cron

```bash
crontab -e
```

复制 `cron/lightops.cron` 中需要的任务。

查看：

```bash
crontab -l
```

查看 cron 服务：

```bash
systemctl status crond
```

查看运行日志：

```bash
tail -f /opt/lightops/logs/cron.log
```
