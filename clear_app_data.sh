#!/bin/bash

echo "🔧 My Finance - Clear App Data"
echo "==============================="
echo ""

# Function to find and clear Hive data files
clear_hive_files() {
    local found_files=false
    
    # Search in common Flutter app data locations
    local search_paths=(
        "$HOME/Library/Containers/*/Data/Documents"
        "$HOME/Documents"
        "$HOME/.local/share"
        "$HOME/Library/Application Support"
        "./data"
        "./build"
    )
    
    echo "🔍 Searching for My Finance database files..."
    
    for search_path in "${search_paths[@]}"; do
        if [ -d "$search_path" ]; then
            # Find .hive files in this directory and subdirectories
            find "$search_path" -name "*.hive" -o -name "*.lock" 2>/dev/null | while read file; do
                if [[ "$file" == *"my_finance"* ]] || [[ "$file" == *"finance"* ]] || [[ "$file" == *"settings"* ]] || [[ "$file" == *"transactions"* ]]; then
                    echo "📁 Found: $file"
                    found_files=true
                fi
            done
        fi
    done
    
    # Alternative: look for Flutter app support directories
    local app_support_dirs=(
        "$HOME/Library/Containers/com.example.myFinance"
        "$HOME/Library/Containers/dev.flutter.myFinance"
        "$HOME/Documents/my_finance"
    )
    
    for dir in "${app_support_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "📂 Found app directory: $dir"
            echo "   Contents:"
            ls -la "$dir" 2>/dev/null | head -10
            echo ""
            found_files=true
        fi
    done
    
    return $found_files
}

echo "This script will help you clear My Finance app data if the app won't start."
echo "⚠️  WARNING: This will delete all your transactions, loans, and settings!"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔍 Searching for app data files..."
    
    clear_hive_files
    
    echo ""
    echo "🧹 Manual cleanup options:"
    echo "1. If you're on iOS Simulator:"
    echo "   xcrun simctl erase all"
    echo ""
    echo "2. If you're on Android Emulator:"
    echo "   flutter clean"
    echo "   cd android && ./gradlew clean"
    echo ""
    echo "3. For physical devices:"
    echo "   Uninstall and reinstall the My Finance app"
    echo ""
    echo "4. Try running the app again - it should create fresh database files"
    
else
    echo "❌ Operation cancelled."
fi

echo ""
echo "Press Enter to exit..."
read