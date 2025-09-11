import 'package:flutter/services.dart';

class NumberFormatter {
  static String formatWithDots(double number) {
    String numStr = number.toStringAsFixed(2);
    
    List<String> parts = numStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];
    
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += '.';
      }
      formattedInteger += integerPart[i];
    }
    
    if (decimalPart == '00') {
      return formattedInteger;
    } else {
      return '$formattedInteger,$decimalPart';
    }
  }
  
  static String formatWithDotsFromString(String input) {
    double? number = double.tryParse(input.replaceAll('.', '').replaceAll(',', '.'));
    if (number == null) return input;
    return formatWithDots(number);
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all dots and replace comma with dot for parsing
    String cleanText = newValue.text.replaceAll('.', '');
    
    // Handle decimal input
    if (cleanText.contains(',')) {
      List<String> parts = cleanText.split(',');
      if (parts.length > 2) {
        // More than one comma, keep old value
        return oldValue;
      }
      
      String integerPart = parts[0];
      String decimalPart = parts.length > 1 ? parts[1] : '';
      
      // Limit decimal part to 2 digits
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      
      // Format integer part with dots
      String formattedInteger = _formatIntegerPart(integerPart);
      
      String formattedText = decimalPart.isEmpty 
        ? '$formattedInteger,'
        : '$formattedInteger,$decimalPart';
      
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    } else {
      // No decimal, just format integer
      String formattedText = _formatIntegerPart(cleanText);
      
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
  }
  
  String _formatIntegerPart(String text) {
    if (text.isEmpty) return '';
    
    // Remove leading zeros but keep at least one digit
    text = text.replaceFirst(RegExp(r'^0+'), '');
    if (text.isEmpty) text = '0';
    
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += text[i];
    }
    return formatted;
  }
}