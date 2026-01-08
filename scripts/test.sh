#!/bin/bash

###############################################################################
# PrimiHub 集成测试脚本
# 功能: 自动测试 PSI、PIR、FL 三大核心功能
# 用法: ./test.sh [--quick] [--skip-fl]
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认参数
QUICK_MODE=false
SKIP_FL=false
PRIMIHUB_DIR=""
TEST_RESULTS_DIR="/tmp/primihub-test-results"

# 测试统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --skip-fl)
            SKIP_FL=true
            shift
            ;;
        --primihub-dir)
            PRIMIHUB_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --quick            快速测试模式 (只测试基本功能)"
            echo "  --skip-fl          跳过FL测试"
            echo "  --primihub-dir DIR primihub 目录路径"
            echo "  -h, --help         显示帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 打印函数
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}[测试] $1${NC}"
    ((TOTAL_TESTS++))
}

print_pass() {
    echo -e "${GREEN}✓ 通过: $1${NC}"
    ((PASSED_TESTS++))
}

print_fail() {
    echo -e "${RED}✗ 失败: $1${NC}"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "  $1"
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 自动检测primihub目录
detect_primihub_dir() {
    if [ -z "$PRIMIHUB_DIR" ]; then
        if [ -d "$HOME/github/primihub" ]; then
            PRIMIHUB_DIR="$HOME/github/primihub"
        elif [ -d "/opt/primihub" ]; then
            PRIMIHUB_DIR="/opt/primihub"
        fi
    fi

    if [ -n "$PRIMIHUB_DIR" ] && [ -d "$PRIMIHUB_DIR" ]; then
        print_info "primihub 目录: $PRIMIHUB_DIR"
    else
        print_fail "未找到 primihub 目录"
        exit 1
    fi
}

# 准备测试环境
prepare_test_env() {
    print_header "准备测试环境"

    # 创建结果目录
    mkdir -p "$TEST_RESULTS_DIR"
    print_info "测试结果目录: $TEST_RESULTS_DIR"

    # 清理旧结果
    rm -f "$PRIMIHUB_DIR/data/result/"*.{csv,pkl,json} 2>/dev/null || true
    print_info "已清理旧测试结果"
}

# 测试服务可用性
test_services() {
    print_header "1. 服务可用性测试"

    # 测试后端
    print_test "后端服务 (8090)"
    if curl -s -f http://localhost:8090/actuator/health > /dev/null 2>&1; then
        print_pass "后端服务正常"
    else
        print_fail "后端服务不可用"
    fi

    # 测试前端
    print_test "前端服务 (8080)"
    if curl -s -f http://localhost:8080 > /dev/null 2>&1; then
        print_pass "前端服务正常"
    else
        print_fail "前端服务不可用"
    fi

    # 测试Meta Service
    for i in 0 1 2; do
        local port=$((7977 + i))
        print_test "Meta Service $i ($port)"
        if curl -s -f "http://localhost:$port/health" > /dev/null 2>&1; then
            print_pass "Meta Service $i 正常"
        else
            print_fail "Meta Service $i 不可用"
        fi
    done

    # 测试计算节点
    print_test "计算节点数量"
    local node_count=$(ps aux | grep "bazel-bin/node" | grep -v grep | wc -l)
    if [ $node_count -ge 3 ]; then
        print_pass "计算节点数量充足 ($node_count 个)"
    else
        print_fail "计算节点数量不足 ($node_count/3)"
    fi
}

# 测试PSI功能
test_psi() {
    print_header "2. PSI (隐私集合求交) 测试"

    cd "$PRIMIHUB_DIR"

    print_test "执行 PSI ECDH 任务"

    local log_file="$TEST_RESULTS_DIR/psi_test.log"
    local start_time=$(date +%s)

    if ./primihub-cli --task_config_file=example/psi_ecdh_task_conf.json > "$log_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # 检查结果
        if [ -f "data/result/psi_result.csv" ]; then
            local result_count=$(wc -l < data/result/psi_result.csv)
            print_pass "PSI 任务执行成功"
            print_info "执行时间: ${duration}s"
            print_info "结果记录: $result_count 条"
            print_info "结果文件: data/result/psi_result.csv"

            # 检查日志中的关键信息
            if grep -q "task finished" "$log_file"; then
                print_info "所有参与方任务完成"
            fi
        else
            print_fail "PSI 任务执行成功但未找到结果文件"
        fi
    else
        print_fail "PSI 任务执行失败"
        print_info "查看日志: $log_file"
    fi
}

# 测试PIR功能
test_pir() {
    print_header "3. PIR (隐匿查询) 测试"

    cd "$PRIMIHUB_DIR"

    print_test "执行 Keyword PIR 任务"

    local log_file="$TEST_RESULTS_DIR/pir_test.log"
    local start_time=$(date +%s)

    if ./primihub-cli --task_config_file=example/keyword_pir_task_conf.json > "$log_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # 检查结果
        if [ -f "data/result/pir_result.csv" ]; then
            local result_count=$(wc -l < data/result/pir_result.csv)
            print_pass "PIR 任务执行成功"
            print_info "执行时间: ${duration}s"
            print_info "结果记录: $result_count 条"
            print_info "结果文件: data/result/pir_result.csv"

            # 检查日志中的关键信息
            if grep -q "task finished" "$log_file"; then
                print_info "所有参与方任务完成"
            fi
        else
            print_fail "PIR 任务执行成功但未找到结果文件"
        fi
    else
        print_fail "PIR 任务执行失败"
        print_info "查看日志: $log_file"
    fi
}

# 测试FL功能
test_fl() {
    if [ "$SKIP_FL" = true ]; then
        print_warn "跳过 FL 测试 (--skip-fl)"
        return 0
    fi

    print_header "4. FL (联邦学习) 测试"

    cd "$PRIMIHUB_DIR"

    # 激活虚拟环境
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    else
        print_warn "未找到虚拟环境，使用系统 Python"
    fi

    # 检查Python依赖
    print_test "检查 Python 依赖"
    if python -c "import torch, sklearn, loguru, phe, opacus" 2>/dev/null; then
        print_pass "Python 依赖齐全"
    else
        print_fail "Python 依赖不完整，跳过 FL 测试"
        return 1
    fi

    print_test "执行 HFL 神经网络任务"

    local log_file="$TEST_RESULTS_DIR/fl_test.log"
    local start_time=$(date +%s)

    # 清理旧模型
    rm -f data/result/*_model.pkl data/result/*_metrics.json 2>/dev/null || true

    if timeout 60 ./primihub-cli --task_config_file=example/FL/neural_network/hfl_binclass_plaintext.json > "$log_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # 检查结果
        if [ -f "data/result/Bob_model.pkl" ] && [ -f "data/result/Bob_metrics.json" ]; then
            print_pass "FL 任务执行成功"
            print_info "执行时间: ${duration}s"

            # 解析训练指标
            if command -v python &> /dev/null; then
                python << 'PYEOF' 2>/dev/null || true
import json
try:
    with open('data/result/Bob_metrics.json') as f:
        metrics = json.load(f)
    if 'train_acc' in metrics:
        print(f"  训练准确率: {metrics['train_acc']:.2%}")
        print(f"  F1分数: {metrics.get('train_f1', 0):.4f}")
        print(f"  AUC: {metrics.get('train_auc', 0):.4f}")
except:
    pass
PYEOF
            fi

            print_info "模型文件: data/result/*_model.pkl"
            print_info "指标文件: data/result/*_metrics.json"
        else
            print_fail "FL 任务执行成功但未找到模型文件"
        fi
    else
        print_fail "FL 任务执行失败或超时"
        print_info "查看日志: $log_file"
    fi

    # 退出虚拟环境
    deactivate 2>/dev/null || true
}

# 测试API接口
test_api() {
    if [ "$QUICK_MODE" = true ]; then
        return 0
    fi

    print_header "5. API 接口测试"

    local base_url="http://localhost:8090"

    # 测试健康检查
    print_test "健康检查接口"
    if curl -s -f "$base_url/actuator/health" | grep -q "UP"; then
        print_pass "健康检查接口正常"
    else
        print_fail "健康检查接口异常"
    fi

    # 测试登录接口（如果有）
    # print_test "登录接口"
    # ...

    # 测试其他API
    print_info "跳过详细 API 测试 (使用 Swagger 文档测试)"
}

# 生成测试报告
generate_report() {
    print_header "测试报告"

    local report_file="$TEST_RESULTS_DIR/test_report.txt"

    cat > "$report_file" << EOF
PrimiHub 测试报告
================

测试时间: $(date)
测试模式: $([ "$QUICK_MODE" = true ] && echo "快速模式" || echo "完整模式")

测试统计
--------
总测试数: $TOTAL_TESTS
通过数: $PASSED_TESTS
失败数: $FAILED_TESTS
成功率: $(awk "BEGIN {printf \"%.1f%%\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")

测试结果文件
------------
$(ls -lh "$TEST_RESULTS_DIR"/*.log 2>/dev/null || echo "无日志文件")

功能测试结果
------------
EOF

    # 添加各功能测试结果
    if [ -f "$PRIMIHUB_DIR/data/result/psi_result.csv" ]; then
        echo "✓ PSI: 通过 ($(wc -l < "$PRIMIHUB_DIR/data/result/psi_result.csv") 条结果)" >> "$report_file"
    else
        echo "✗ PSI: 失败" >> "$report_file"
    fi

    if [ -f "$PRIMIHUB_DIR/data/result/pir_result.csv" ]; then
        echo "✓ PIR: 通过 ($(wc -l < "$PRIMIHUB_DIR/data/result/pir_result.csv") 条结果)" >> "$report_file"
    else
        echo "✗ PIR: 失败" >> "$report_file"
    fi

    if [ -f "$PRIMIHUB_DIR/data/result/Bob_model.pkl" ] && [ "$SKIP_FL" != true ]; then
        echo "✓ FL: 通过 (模型已生成)" >> "$report_file"
    elif [ "$SKIP_FL" = true ]; then
        echo "- FL: 已跳过" >> "$report_file"
    else
        echo "✗ FL: 失败" >> "$report_file"
    fi

    # 显示报告
    cat "$report_file"
    echo ""
    print_info "完整报告: $report_file"
}

# 测试总结
test_summary() {
    print_header "测试总结"

    echo -e "总测试数: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "通过数: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失败数: ${RED}$FAILED_TESTS${NC}"

    local success_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
    echo -e "成功率: ${BLUE}$success_rate%${NC}"
    echo ""

    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}✓ 所有测试通过！${NC}"
        exit 0
    else
        echo -e "${RED}✗ 部分测试失败${NC}"
        echo ""
        echo "建议操作:"
        echo "  1. 查看测试日志: ls -l $TEST_RESULTS_DIR/"
        echo "  2. 检查服务状态: curl http://localhost:8090/actuator/health"
        echo "  3. 查看服务日志: tail -f /tmp/primihub-*.log"
        exit 1
    fi
}

# 主函数
main() {
    print_header "PrimiHub 集成测试"

    echo "开始时间: $(date)"
    echo "快速模式: $QUICK_MODE"
    echo "跳过FL: $SKIP_FL"
    echo ""

    # 检测目录
    detect_primihub_dir

    # 准备环境
    prepare_test_env

    # 运行测试
    test_services
    test_psi
    test_pir
    test_fl

    if [ "$QUICK_MODE" = false ]; then
        test_api
    fi

    # 生成报告
    generate_report

    # 显示总结
    test_summary
}

# 运行主函数
main "$@"
