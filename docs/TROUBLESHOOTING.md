# 故障排查案例

## 1. cron 不执行

检查服务：

```bash
systemctl status crond
```

检查任务：

```bash
crontab -l
```

检查脚本权限：

```bash
ls -l scripts/
```

cron 环境变量较少，尽量使用绝对路径：

```bash
/usr/bin/python3
/opt/lightops/scripts/system_check.sh
```

查看日志：

```bash
tail -100 logs/cron.log
```

## 2. mysqldump: command not found

检查：

```bash
which mysqldump
```

安装 MySQL/MariaDB 客户端后再次执行。

## 3. Access denied for user

检查：

```bash
chmod 600 config/mysql.cnf
cat config/mysql.cnf
```

使用同一配置测试：

```bash
mysql --defaults-extra-file=config/mysql.cnf -e "SELECT 1;"
```

检查 MySQL 用户的 Host、密码和授权。

## 4. 端口检测失败但服务存在

查看监听：

```bash
ss -lntp
```

检查服务是否只绑定到某个 IP。

如果检查远程服务器，还需要确认：

- firewalld
- 安全组
- SELinux
- 应用监听地址

## 5. Python 日志文件权限不足

检查：

```bash
ls -l /path/to/app.log
id
```

测试：

```bash
sudo -u your_user head /path/to/app.log
```

不要为了方便直接给所有文件 `chmod 777`，应调整用户、组或 ACL。
