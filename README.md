# inner_projects_qwen_g1_voice_assistant

这是一个面向 Unitree G1 的语音交互工作空间。它把 ROS2 ASR 文本接入本地 Qwen 模型，生成回复后用 Edge TTS 合成语音，再通过 Unitree 音频接口播放。

## 现在能做什么

```text
Unitree 官方 DDS ASR 文本 rt/audio_msg
        ↓
安全桥接到 ROS2 /audio_msg
        ↓
唤醒词过滤
        ↓
HTTP 请求本地 Qwen 服务
        ↓
Edge TTS 生成 runtime/tts.mp3
        ↓
ROS 节点转换成 runtime/tts.wav
        ↓
Unitree G1 扬声器播放
```

核心能力：

- 支持中文、英文、日文简单语言检测。
- 支持默认唤醒词：`西浦小g`、`小g`、`小G`、`hey gee`、`hey g`、`XJTLU Gee`、`せいほくジーくん`、`ジーくん`。
- 支持只说唤醒词后，下一句话作为命令。
- 支持键盘切换唤醒词模式和持续监听模式。
- 支持把 Unitree 官方 DDS `rt/audio_msg` 安全转发到 ROS2 `/audio_msg`。
- 支持集中配置模型路径、ROS topic、网口、音量、生成参数。
- 运行产物统一写入 `runtime/`，不污染项目根目录。

## 目录结构

```text
inner_projects_qwen_g1_voice_assistant/
├── config/
│   └── default.env
├── scripts/
│   ├── check_project.sh
│   ├── check_full_pipeline.sh
│   ├── run_asr_bridge.sh
│   ├── run_full_pipeline.sh
│   ├── run_audio_player.sh
│   ├── run_ros_node.sh
│   ├── stop_full_pipeline.sh
│   └── run_server.sh
├── third_party/
│   └── unitree_sdk2_python/
├── runtime/
├── project_config.py
├── qwen_server.py
├── qwen_ros_node_edg_tts.py
├── unitree_audio_player.py
├── wav.py
├── requirements.txt
└── README.md
```

## 关键文件

- `qwen_server.py`
  - FastAPI 服务。
  - 加载本地 Qwen 模型。
  - 提供 `/infer?text=...` 接口。
  - 调用 Edge TTS 生成 `runtime/tts.mp3`。

- `qwen_ros_node_edg_tts.py`
  - ROS2 节点。
  - 订阅 ASR 文本 topic。
  - 做唤醒词过滤。
  - 请求 Qwen 服务。
  - 把 `runtime/tts.mp3` 转成 `runtime/tts.wav`。

- `asr_dds_to_ros_bridge.py`
  - 安全桥接节点。
  - 只订阅 Unitree DDS `rt/audio_msg`。
  - 只发布 ROS2 `/audio_msg`。
  - 不调用机器人动作、TTS、灯光或状态切换 API。

- `unitree_audio_player.py`
  - 监听 `runtime/tts.wav` 文件变化。
  - 通过 Unitree SDK2 AudioClient 播放到 G1。

- `project_config.py`
  - 项目统一配置入口。
  - 优先读取环境变量，没有环境变量时使用默认值。

- `config/default.env`
  - 默认配置文件。
  - 启动脚本会自动 source 它。

- `third_party/unitree_sdk2_python`
  - 随项目携带的 Unitree SDK2 Python 源码包。
  - `unitree_audio_player.py` 默认从这里导入 `unitree_sdk2py`，不再依赖外部 `/home/louisxx/unitree_g1/unitree_sdk2_python`。

## 配置

常用配置在：

```bash
/home/louisxx/qwen_ros_node_edg_tts/config/default.env
```

重要配置：

```bash
QWEN_AUDIO_TOPIC=/audio_msg
QWEN_PYTHON=/home/louisxx/miniconda3/envs/qwen/bin/python
QWEN_SERVER_URL=http://127.0.0.1:8000/infer
QWEN_WAKE_WORDS="西浦小g,小g,小G,hey gee,hey g,XJTLU Gee,せいほくジーくん,ジーくん"

QWEN_MODEL_PATH=/home/louisxx/Qwen3.5-0.8B/model
QWEN_RUNTIME_DIR=/home/louisxx/qwen_ros_node_edg_tts/runtime
QWEN_MAX_NEW_TOKENS=50
QWEN_TEMPERATURE=0.7

UNITREE_DOMAIN_ID=0
UNITREE_NETWORK_INTERFACE=enp8s0
UNITREE_AUDIO_VOLUME=85
```

## 环境准备

Python 依赖：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
conda activate qwen
pip install -r requirements.txt
```

系统依赖：

```bash
sudo apt update
sudo apt install -y ffmpeg
```

ROS2：

```bash
source /opt/ros/jazzy/setup.bash
```

Unitree SDK2：

```bash
export PYTHONPATH=/home/louisxx/qwen_ros_node_edg_tts/third_party/unitree_sdk2_python:$PYTHONPATH
```

启动脚本里已经处理了 ROS2 source 和 Unitree SDK2 `PYTHONPATH`。

## 启动方式

### 一键启动全链路

持续监听模式：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/run_full_pipeline.sh --mode listen
```

唤醒词模式：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/run_full_pipeline.sh --mode wake --wake-word "小g"
```

这条脚本会同时拉起：

- Qwen server
- ROS 文本节点
- Unitree 音频播放器

### 手动分开启动

如果你要排查某一段，也可以分开跑：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/run_server.sh
./scripts/run_ros_node.sh
./scripts/run_audio_player.sh
```

现在推荐按 3 个终端来盯：

```text
终端 1: run_server.sh
终端 2: run_ros_node.sh
终端 3: run_audio_player.sh
```

健康检查：

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
  NO_PROXY=127.0.0.1,localhost curl http://127.0.0.1:8000/health
```

测试推理：

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
  NO_PROXY=127.0.0.1,localhost curl "http://127.0.0.1:8000/infer?text=你好"
```

如果要看桥接有没有收到机器人语音：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/monitor_audio_msg.sh
```

桥接脚本仍然保留，单独排查时可以直接运行：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/run_asr_bridge.sh
```

停止全流程：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/stop_full_pipeline.sh
```

## 唤醒词用法

默认唤醒词：

```text
西浦小g
小g
小G
hey gee
hey g
XJTLU Gee
せいほくジーくん
ジーくん
```

示例：

```text
小g 你叫什么名字
西浦小g 现在几点了
hey g what is your name
ジーくん 名前は何ですか
```

如果只说：

```text
小g
```

节点会等待下一条 ASR 文本，并把下一句话作为命令。

键盘控制：

```text
wake   切回唤醒词模式
start  切到持续监听模式
quit   退出节点
```

注意：这是文本层唤醒词过滤。ASR 仍然会持续识别声音，只是没有唤醒词的文本不会交给 Qwen。

## 项目检查

不启动模型、不连接机器人，只做基础检查：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/check_project.sh
```

全面检查：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/check_full_pipeline.sh
```

全面检查不会启动 Qwen 大模型，也不会让 G1 播放音频。它会检查：

```text
1. 必要项目文件是否存在
2. 是否残留 __pycache__ / *.pyc
3. Python 语法
4. qwen conda 环境里的核心包导入
5. 唤醒词解析
6. ffmpeg mp3/wav 转码
7. ROS2 std_msgs/String 发布/订阅
8. Unitree SDK2 Python 是否来自项目 third_party
9. 如果 Qwen server 已启动，则检查 /health
```

看到：

```text
QWEN ROS DDS FULL CHECK PASSED
```

说明 ROS2 文本传输、唤醒词、TTS 文件转换和 DDS Python 依赖检查都通过。

它会检查：

```text
Python 语法
配置是否可读取
模型路径是否存在
唤醒词配置
runtime 路径
```

## ROS2 输入格式

当前节点订阅：

```text
/audio_msg
```

消息类型：

```text
std_msgs/msg/String
```

推荐 JSON 格式：

```json
{"text": "小g 你好"}
```

也兼容纯文本：

```text
小g 你好
```

手动测试：

```bash
source /opt/ros/jazzy/setup.bash
ros2 topic pub --once /audio_msg std_msgs/msg/String "{data: '{\"text\":\"小g 你叫什么名字\"}'}"
```

## 排错

看不到回复：

```text
1. 确认 qwen_server.py 已启动
2. 确认 /health 能返回 ok
3. 确认 ASR 文本里包含唤醒词
4. 确认 runtime/tts.mp3 是否生成
5. 确认 ffmpeg 是否安装
```

G1 不播放：

```text
1. 确认 runtime/tts.wav 是否生成
2. 确认 Unitree SDK2 PYTHONPATH
3. 确认 UNITREE_NETWORK_INTERFACE=enp8s0
4. 确认机器人和电脑 DDS 网络连通
5. 确认音量 UNITREE_AUDIO_VOLUME
```

## 回复动作桥接

ROS 节点现在会在拿到 Qwen 回复并生成 `runtime/tts.wav` 后，把回复文本送入：

```text
/home/louisxx/unitree_g1_action_classifier_package/arm_action_classifier/arm_action_classifier.py
```

默认配置会使用通义千问分类动作，并通过官方 runner 执行动作：

```bash
QWEN_ACTION_ENABLE=1
QWEN_ACTION_EXECUTE=1
QWEN_ACTION_BACKEND=qwen
UNITREE_NETWORK_INTERFACE=enp8s0
```

运行前需要在同一个终端环境里设置真实百炼 API key：

```bash
export DASHSCOPE_API_KEY='sk-你的真实key'
```

三进程启动顺序：

```bash
cd /home/louisxx/qwen_ros_node_edg_tts
./scripts/run_server.sh
./scripts/run_ros_node.sh
./scripts/run_audio_player.sh
```

手动测试输入：

```bash
source /opt/ros/jazzy/setup.bash
ros2 topic pub --once /audio_msg std_msgs/msg/String "{data: '{\"text\":\"小g 西交利物浦大学非常棒\"}'}"
```

如果只想先 dry-run，不控制真机：

```bash
QWEN_ACTION_EXECUTE=0 ./scripts/run_ros_node.sh
```

如果机器人返回 `arm_holding_release_required`，先手动释放手臂：

```bash
/home/louisxx/unitree_g1_action_classifier_package/unitree_sdk2/build/bin/g1_arm_action_example \
  --network enp8s0 \
  --id 99
```

嘈杂环境误触发：

```text
1. 保持唤醒词模式，不要用 start 持续监听模式
2. 增加更长的唤醒词
3. 后续可以接入音频级唤醒词模型或 ASR 置信度过滤
```
