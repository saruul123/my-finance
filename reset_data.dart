#!/usr/bin/env dart

import 'dart:io';

/// Simple script to manually clear Hive database files when the app won't start
void main() async {
  print('🔧 My Finance Database Reset Tool');
  print('==================================');
  print('');
  
  try {
    // Get the application documents directory path
    final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    
    // Common Hive storage locations for Flutter apps
    final possiblePaths = [
      '$homeDir/Documents/my_finance',
      '$homeDir/.local/share/my_finance', 
      '$homeDir/Library/Application Support/my_finance',
      '$homeDir/AppData/Roaming/my_finance',
      'data', // Current directory data folder
    ];
    
    bool foundData = false;
    
    for (final path in possiblePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        print('📁 Found data directory: $path');
        
        final files = await dir.list().toList();
        final hiveFiles = files.where((f) => f.path.endsWith('.hive') || f.path.endsWith('.lock')).toList();
        
        if (hiveFiles.isNotEmpty) {
          foundData = true;
          print('💾 Found ${hiveFiles.length} database files:');
          for (final file in hiveFiles) {
            print('   - ${file.path.split('/').last}');
          }
          
          print('');
          stdout.write('⚠️  Delete these files? (y/N): ');
          final input = stdin.readLineSync()?.toLowerCase();
          
          if (input == 'y' || input == 'yes') {
            for (final file in hiveFiles) {
              try {
                await file.delete();
                print('✅ Deleted: ${file.path.split('/').last}');
              } catch (e) {
                print('❌ Failed to delete ${file.path.split('/').last}: $e');
              }
            }
            print('');
            print('🎉 Database reset complete!');
            print('👉 You can now restart the My Finance app.');
          } else {
            print('❌ Reset cancelled.');
          }
        }
      }
    }
    
    if (!foundData) {
      print('📂 No Hive database files found in common locations.');
      print('   The app might be storing data in a different location.');
      print('   Try deleting and reinstalling the app if the issue persists.');
    }
    
  } catch (e) {
    print('❌ Error: $e');
    print('');
    print('🔧 Manual steps:');
    print('1. Close the My Finance app completely');
    print('2. Delete the app and reinstall it from the store');
    print('3. Or find and delete .hive files in your system');
  }
  
  print('');
  print('Press Enter to exit...');
  stdin.readLineSync();
}