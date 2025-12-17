#!/bin/bash

# Document Format Validation Script
# **Feature: documentation-standardization, Property 1: 文档格式一致性**
# **Validates: Requirements 1.3, 2.4, 5.3, 5.5**

DOCS_DIR="$(dirname "$0")"
FAILED=0
PASSED=0
SKIPPED=0

echo "========================================"
echo "Running Document Format Validation Tests"
echo "========================================"
echo ""

# Function to check if a file has navigation link
check_navigation() {
    local file="$1"
    if grep -qE "返回.*\[文档中心\]|返回.*README" "$file"; then
        return 0
    fi
    return 1
}

# Function to check if a file has version
check_version() {
    local file="$1"
    if grep -qE "\*\*版本\*\*:.*v?[0-9]+\.[0-9]+\.[0-9]+|版本:.*v?[0-9]+\.[0-9]+\.[0-9]+" "$file"; then
        return 0
    fi
    return 1
}

# Function to check if a file has author
check_author() {
    local file="$1"
    if grep -qE "\*\*作者\*\*:|作者:|Author:" "$file"; then
        return 0
    fi
    return 1
}

# Function to check if a file has update date
check_update_date() {
    local file="$1"
    if grep -qE "\*\*更新日期\*\*:.*[0-9]{4}-[0-9]{2}-[0-9]{2}|\*\*最后更新\*\*:.*[0-9]{4}-[0-9]{2}-[0-9]{2}|更新日期:.*[0-9]{4}|最后更新:.*[0-9]{4}" "$file"; then
        return 0
    fi
    return 1
}

# Function to check if a file has status
check_status() {
    local file="$1"
    if grep -qE "\*\*状态\*\*:.*(草稿|审核中|已发布|已废弃)|状态:.*(草稿|审核中|已发布|已废弃)" "$file"; then
        return 0
    fi
    return 1
}

# Find all markdown files
find "$DOCS_DIR" -name "*.md" -type f | while read -r file; do
    filename=$(basename "$file")
    relpath="${file#$DOCS_DIR/}"
    
    # Skip README.md and CHANGELOG.md (they have different format requirements)
    if [ "$filename" = "README.md" ] || [ "$filename" = "CHANGELOG.md" ]; then
        echo "⏭️  SKIPPED: $relpath (special format)"
        continue
    fi
    
    # Skip .gitkeep files
    if [ "$filename" = ".gitkeep" ]; then
        continue
    fi
    
    # Check if file is empty
    if [ ! -s "$file" ]; then
        echo "⏭️  SKIPPED: $relpath (empty file)"
        continue
    fi
    
    missing=""
    
    # Check navigation link
    if ! check_navigation "$file"; then
        missing="$missing 导航链接"
    fi
    
    # Check version
    if ! check_version "$file"; then
        missing="$missing 版本号"
    fi
    
    # Check author
    if ! check_author "$file"; then
        missing="$missing 作者"
    fi
    
    # Check update date
    if ! check_update_date "$file"; then
        missing="$missing 更新日期"
    fi
    
    # Check status
    if ! check_status "$file"; then
        missing="$missing 状态"
    fi
    
    if [ -z "$missing" ]; then
        echo "✅ PASSED: $relpath"
    else
        echo "❌ FAILED: $relpath - 缺少:$missing"
    fi
done

echo ""
echo "========================================"
echo "Validation Complete"
echo "========================================"
