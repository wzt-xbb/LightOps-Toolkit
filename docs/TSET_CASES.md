# 测试案例

## Case 1：正常巡检

```bash
./scripts/system_check.sh
```

预期：

- 生成 `reports/system_check_*.txt`
- 输出 CPU、内存、磁盘
- 输出端口和进程状态

## Case 2：模拟端口异常

先启动测试 TCP 服务：

```bash
python3 tests/mock_tcp_server.py --port 18080
```

另开一个终端：

```bash
python3 scripts/port_monitor.py --config config/ports.conf
```

预期 `demo-app` 为 `OK`。

停止 TCP 服务后再次执行。

预期：

```text
[ALERT] demo-app 127.0.0.1:18080 connection refused
```

脚本退出码应为 1：

```bash
echo $?
```

## Case 3：模拟数据库连接异常

临时将 `config/mysql.cnf` 中：

```ini
port=3306
```

改为：

```ini
port=3307
```

执行：

```bash
./scripts/mysql_backup.sh
echo $?
```

预期：

- `mysqldump failed`
- 返回非 0 退出码
- 不保留损坏的 `.sql` 临时文件

测试结束后恢复配置。

## Case 4：测试数据库备份

```bash
./scripts/mysql_backup.sh
ls -lh backups/mysql/
```

预期生成：

```text
lightops_demo_YYYYMMDD_HHMMSS.sql.gz
```

验证压缩包：

```bash
gzip -t backups/mysql/*.sql.gz
echo $?
```

返回 `0` 表示 gzip 文件有效。

## Case 5：测试日志分析

生成模拟业务日志：

```bash
python3 tests/generate_sample_log.py
```

执行：

```bash
python3 scripts/log_analyzer.py \
  --log sample_logs/generated_app.log \
  --output reports/generated_log_report.txt
```

预期可以统计 ERROR/WARN/CRITICAL。

## Case 6：测试磁盘阈值

编辑 `config/lightops.env`：

```bash
DISK_WARN=1
```

运行：

```bash
./scripts/system_check.sh
```

大多数磁盘分区应显示 WARN。

测试完成后恢复到：

```bash
DISK_WARN=80
```
