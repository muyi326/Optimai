#!/bin/bash
# optimai-one-click-mac.sh - 完全一键安装运行脚本（无交互）

echo "========================================"
echo "   OptimAI Core Node 完全自动安装"
echo "========================================"
echo "⏳ 正在自动执行所有步骤..."
echo "   无需任何操作，请稍候..."
echo "========================================"

# 检测操作系统
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ 此脚本仅支持 macOS 系统"
    exit 1
fi

PROJECT_DIR="$HOME/OptimAI-Core-Node"
BIN_DIR="$PROJECT_DIR/bin"
CLI_URL="https://optimai.network/download/cli-node/mac"
CLI_FILE="$BIN_DIR/optimai-cli"

# ============================================
# 第1部分：准备工作
# ============================================
echo ""
echo "🔧 第1步：准备工作..."
echo "════════════════════════════════════════════"

# 清理可能存在的旧项目
if [ -d "$PROJECT_DIR" ]; then
    echo "🗑️  检测到旧版本，正在清理..."
    rm -rf "$PROJECT_DIR"
fi

# 创建项目目录
mkdir -p "$PROJECT_DIR" "$BIN_DIR"

# ============================================
# 第2部分：下载主程序
# ============================================
echo ""
echo "📥 第2步：下载主程序..."
echo "════════════════════════════════════════════"

echo "正在下载 optimai-cli..."
if curl -L -s -o "$CLI_FILE" "$CLI_URL"; then
    echo "✅ 下载完成"
    chmod +x "$CLI_FILE"
else
    echo "❌ 下载失败，请检查网络连接"
    exit 1
fi

# ============================================
# 第3部分：创建目录结构
# ============================================
echo ""
echo "📁 第3步：创建目录结构..."
echo "════════════════════════════════════════════"

mkdir -p "$PROJECT_DIR/config" "$PROJECT_DIR/data" "$PROJECT_DIR/logs" "$PROJECT_DIR/.sessions"
echo "✅ 目录创建完成"

# ============================================
# 第4部分：创建配置文件
# ============================================
echo ""
echo "⚙️  第4步：创建配置文件..."
echo "════════════════════════════════════════════"

# 环境配置文件
cat > "$PROJECT_DIR/.env" << 'EOF'
# OptimAI Core Node 环境配置
export OPTIMAI_HOME="$HOME/OptimAI-Core-Node"
export OPTIMAI_BIN="$HOME/OptimAI-Core-Node/bin"
export OPTIMAI_DATA="$HOME/OptimAI-Core-Node/data"
export OPTIMAI_LOGS="$HOME/OptimAI-Core-Node/logs"
export OPTIMAI_SESSIONS="$HOME/OptimAI-Core-Node/.sessions"
export DOCKER_SOCKET="/var/run/docker.sock"
export PATH="$HOME/OptimAI-Core-Node/bin:$PATH"
export OPTIMAI_OS="macOS"
EOF

# 节点配置文件
cat > "$PROJECT_DIR/config/node-config.yaml" << 'EOF'
# OptimAI Node 配置 (macOS)
node:
  name: "$(hostname)-mac-node"
  type: core
  version: "1.0"
network:
  mode: mainnet
  endpoint: "https://network.optimai.network"
  region: "auto"
resources:
  cpu_limit: 75
  memory_limit_mb: 4096
  storage_limit_gb: 50
  gpu_enabled: false
logging:
  level: info
  file: "$OPTIMAI_LOGS/node.log"
  max_size_mb: 100
  retention_days: 7
security:
  auto_update: true
  firewall_compatible: true
EOF

echo "✅ 配置文件创建完成"

# ============================================
# 第5部分：创建启动脚本（简化版）
# ============================================
echo ""
echo "🚀 第5步：创建启动脚本..."
echo "════════════════════════════════════════════"

# 简化的启动脚本
cat > "$PROJECT_DIR/start-optimai.sh" << 'EOF'
#!/bin/bash
cd "$HOME/OptimAI-Core-Node"

echo "🚀 启动 OptimAI Core Node..."
echo "════════════════════════════════════════════"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ 请先安装 Docker Desktop for macOS"
    echo "   下载地址: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

# 等待 Docker 启动
echo "检查 Docker 状态..."
for i in {1..30}; do
    if docker info &> /dev/null; then
        echo "✅ Docker 已就绪"
        break
    fi
    if [ $i -eq 1 ]; then
        echo "正在启动 Docker..."
        open -a Docker
    fi
    echo -n "."
    sleep 2
    if [ $i -eq 30 ]; then
        echo "❌ Docker 启动超时"
        exit 1
    fi
done

# 检查是否已登录
if [ ! -f ".sessions/token" ] && [ ! -f ".sessions/session.json" ]; then
    echo "🔐 需要登录..."
    echo "正在打开浏览器登录..."
    ./bin/optimai-cli auth login
    if [ $? -ne 0 ]; then
        echo "❌ 登录失败"
        exit 1
    fi
    echo "✅ 登录成功"
    sleep 2
fi

# 启动节点
echo "正在启动节点..."
mkdir -p logs
"./bin/optimai-cli" node start

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 OptimAI 节点正在运行！"
    echo ""
    echo "📊 节点信息:"
    echo "   名称: $(hostname)-mac-node"
    echo "   日志: $HOME/OptimAI-Core-Node/logs/node.log"
    echo ""
    echo "💡 保持此窗口打开，节点会持续运行"
    echo "   按 Ctrl+C 停止节点"
else
    echo "❌ 节点启动失败"
    echo "请查看日志文件: $HOME/OptimAI-Core-Node/logs/node.log"
fi
EOF

chmod +x "$PROJECT_DIR/start-optimai.sh"
echo "✅ 启动脚本创建完成"

# ============================================
# 第6部分：检查 Docker
# ============================================
echo ""
echo "🐳 第6步：检查 Docker..."
echo "════════════════════════════════════════════"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装"
    echo ""
    echo "📦 正在引导安装 Docker Desktop..."
    echo ""
    echo "请按以下步骤操作:"
    echo "1. 打开浏览器访问: https://www.docker.com/products/docker-desktop/"
    echo "2. 下载 Docker.dmg 文件"
    echo "3. 双击安装"
    echo "4. 启动 Docker Desktop"
    echo "5. 同意服务条款"
    echo ""
    echo "安装完成后，重新运行此脚本"
    exit 1
fi

# 启动 Docker（如果未运行）
if ! docker info &> /dev/null; then
    echo "正在启动 Docker..."
    open -a Docker
    
    echo "等待 Docker 启动..."
    for i in {1..30}; do
        if docker info &> /dev/null; then
            echo "✅ Docker 已启动"
            break
        fi
        echo -n "."
        sleep 2
        if [ $i -eq 30 ]; then
            echo "❌ Docker 启动超时"
            echo "请手动启动 Docker Desktop 后重新运行此脚本"
            exit 1
        fi
    done
else
    echo "✅ Docker 正在运行"
fi

# ============================================
# 第7部分：登录账户
# ============================================
echo ""
echo "🔐 第7步：登录账户..."
echo "════════════════════════════════════════════"

echo "正在打开浏览器进行登录..."
echo ""
echo "📋 登录说明:"
echo "   1. 浏览器会自动打开"
echo "   2. 输入您的 OptimAI 账户"
echo "   3. 如果没有账户，请先注册"
echo "   4. 登录后关闭浏览器窗口"
echo ""
echo "⏳ 等待登录..."

cd "$PROJECT_DIR"
"./bin/optimai-cli" auth login

if [ $? -eq 0 ]; then
    echo "✅ 登录成功"
else
    echo "❌ 登录失败或取消"
    echo "稍后可以手动登录:"
    echo "cd ~/OptimAI-Core-Node"
    echo "./bin/optimai-cli auth login"
fi

# ============================================
# 第8部分：启动节点
# ============================================
echo ""
echo "🚀 第8步：启动节点..."
echo "════════════════════════════════════════════"

echo "正在启动 OptimAI Core Node..."
echo "这可能需要几分钟时间..."
echo ""

# 启动节点
cd "$PROJECT_DIR"
"./bin/optimai-cli" node start

NODE_STATUS=$?

echo ""
echo "════════════════════════════════════════════"

if [ $NODE_STATUS -eq 0 ]; then
    echo "🎉 恭喜！OptimAI 节点已成功启动并运行！"
    echo ""
    echo "📊 节点运行信息:"
    echo "   名称: $(hostname)-mac-node"
    echo "   类型: Core Node"
    echo "   网络: Mainnet"
    echo "   位置: ~/OptimAI-Core-Node"
    echo ""
    echo "📈 节点正在工作:"
    echo "   • 连接到 OptimAI 网络"
    echo "   • 接收和处理任务"
    echo "   • 贡献算力"
    echo ""
    echo "🖥️  如何监控:"
    echo "   保持此终端窗口打开"
    echo "   节点会持续运行并显示状态"
    echo ""
    echo "⏸️  如何停止:"
    echo "   按 Ctrl+C 停止节点"
    echo ""
    echo "🔁 如何重新启动:"
    echo "   关闭此窗口后，下次运行:"
    echo "   cd ~/OptimAI-Core-Node"
    echo "   ./start-optimai.sh"
else
    echo "⚠️  节点启动遇到问题"
    echo ""
    echo "🔧 解决方案:"
    echo "   1. 查看日志: tail -f ~/OptimAI-Core-Node/logs/node.log"
    echo "   2. 检查 Docker: docker ps"
    echo "   3. 重新启动: cd ~/OptimAI-Core-Node && ./start-optimai.sh"
    echo "   4. 重新登录: cd ~/OptimAI-Core-Node && ./bin/optimai-cli auth login"
fi

echo ""
echo "════════════════════════════════════════════"
echo "🏁 安装和启动流程完成"
echo ""
echo "📁 项目位置: ~/OptimAI-Core-Node"
echo "🚀 重启命令: ./start-optimai.sh"
echo ""
echo "📞 获取帮助:"
echo "   查看日志: tail -f ~/OptimAI-Core-Node/logs/node.log"
echo "   官方文档: https://docs.optimai.network"
echo ""
echo "🌈 感谢使用 OptimAI Network！"
echo "════════════════════════════════════════════"
