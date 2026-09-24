# App / 固件联调说明

日期：2026-09-25。App 0.2.0；固件 0.3.1；rad-ble v1.0.0。

## GATT

服务：`522b443a-4f53-534d-0001-420badbabe69`。

**特征 UUID 替换第四组**，例如 request 是 `522b443a-4f53-534d-1000-420badbabe69`，不是替换 UUID 最后四位。旧 APP_PROTOCOL.md 的后缀描述存在歧义。

| 第四组 | 用途 |
|---|---|
| 0002 | 协议信息，验证 protocol=rad-ble、version=1 |
| 0005 | 设备身份、固件版本 |
| 1000 | 写 JSON 请求 |
| 1100 | 订阅响应 indicate；只把 completed / failed 当终态 |
| 2000 | 完整状态 notify / read |
| 2010 | 精简状态 notify |
| 2100 | 租约事件 notify |

客户端申请 MTU 512，以实际协商结果为准；固件仍默认 247。完整 JSON 可能超过 MTU-3：不要拼接独立 notify。App 每秒执行完整 ATT read 作为补偿；请求响应未完成时，800 ms 后读取 response 特征补偿终态。读到 accepted 不算成功；请求 4 秒超时，不自动重放运动命令。

## 会话

- 连接、发现服务、订阅，`control.acquire {ttl:10}`，保存返回 lease。
- 连接后发送 `ossm.command {command:"go:estop"}`，不恢复上次运行。
- 每 3 秒 `control.renew`；失败 / 过期后断开。
- 读 `setting.read path=motor.travelMm`。
- 滑条合并 150 ms 后 `session.apply`，只含 speed / stroke / depth / sensation / pattern；不含 running。
- 只有启动操作显式附加 `running:true`，并等待运行遥测。
- 停止通过 `go:softEnd`，急停通过 `go:estop`；取消待发普通请求。
- 完整状态 5 秒未更新则请求停止并断开。所有错误可在“我的”查看最近记录。

`state.homed` 和 `state.travelMm` 由 0.3.1 固件上报。兼容旧固件时，仅在本连接观察到自己发起的 homing → ready 后解锁，不根据 ready 单独推断回零成功。仍强烈建议升级，因为旧固件回零循环不能及时处理 BLE 停止。

模式固定映射：0 匀速 / 1 挑逗 / 2 机械 / 3 交错 / 4 渐深 / 5 停顿 / 6 短促。手感 0–100，50 中性。百分比速度不等于实际测得的往复频率；界面不显示伪造 Hz 或电量。

## 固件本次改动

代码在 `H:\ossm_fireware\OSSM_Fireware`，版本 0.3.1。修改 AppState、BleService、CommandParser、MotionEngine、YzMotor、SafetyManager 和版本头文件。

修复 go:softEnd 先清除运行标记而跳过减速的问题。只对 BLE 启动入口新增回零/总线/故障门禁；CLI、Web 调试入口的行为没有全面重构。回零取消在 Modbus 寻端/回退轮询之间处理，仍受单次总线事务延迟约束。硬件故障和急停时真实制动效果必须实测。

## 硬件验收（尚未执行）

1. 先检查电机脱载、机械余量和实体急停，刷入 0.3.1；App 启动必须显示未连接。
2. Android 真机权限允许 / 拒绝各测试一次，确认扫描及重试。
3. 连接后检查固件版本、电压/位置与串口一致；确认没有自动运动。
4. 设置实际可用行程，执行回零；回零中分别测试 App 急停与断开。
5. 回零后低速度短行程启动，检查 7 种模式及手感参数，核对深度/行程含义。
6. 停机、急停、切后台、断开蓝牙、失去租约、状态停更、拔掉总线；确认电机进入预期安全状态。
7. 连续快速拖动后按急停，确认停止后没有残留参数/启动命令再次驱动电机。
8. 模拟故障、清除后重新回零；快速断连/重连不能取消停止或恢复运动。
9. 测试定时停止和手机锁屏；验证真实电机停止时间，而不只看请求 ACK。

## 构建记录

App：`flutter analyze`、`flutter test`、`flutter build apk --release`。
固件验证：`build/pio-env/Scripts/pio.exe run -d build/firmware-validation`，ESP32-S3 8MB 配置。
固件使用约 15.4% RAM、39.1% Flash。验证副本与原项目修改源码进行 SHA-256 对比。

未把“编译通过”或“测试传输层通过”当作真实 BLE/机械验收。当前安装包采用工程既有开发签名，供联调使用。
