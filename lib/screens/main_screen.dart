import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. DATA MODEL FOR SAVED COLORS ---
class ColorRecord {
  final Color color;
  final String hex;
  final String rgba;
  final String name;
  final DateTime timestamp;

  ColorRecord({
    required this.color,
    required this.hex,
    required this.rgba,
    required this.name,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'color': color.value,
      'hex': hex,
      'rgba': rgba,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ColorRecord.fromJson(Map<String, dynamic> json) {
    return ColorRecord(
      color: Color(json['color'] as int),
      hex: json['hex'] as String,
      rgba: json['rgba'] as String,
      name: json['name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

// --- 2. COMPREHENSIVE ASIAN PAINTS DATABASE ---
final List<Map<String, dynamic>> asianPaintsDatabase = [
  {'name': 'AP 9101 Purple Verve', 'r': 104, 'g': 58, 'b': 85},
  {'name': 'AP 9102 Deep Passion', 'r': 163, 'g': 105, 'b': 147},
  {'name': 'AP 9103 Fruit Ink', 'r': 193, 'g': 141, 'b': 180},
  {'name': 'AP 9104 Brush Stroke Bold', 'r': 210, 'g': 162, 'b': 198},
  {'name': 'AP 9105 Pink Blossom', 'r': 231, 'g': 186, 'b': 214},
  {'name': 'AP 9106 Pink Hush', 'r': 237, 'g': 202, 'b': 222},
  {'name': 'AP 9107 Mystical Wave', 'r': 243, 'g': 223, 'b': 232},
  {'name': 'AP 9108 Iris Ice', 'r': 243, 'g': 231, 'b': 233},
  {'name': 'AP 0766 Purity-N', 'r': 241, 'g': 235, 'b': 234},
  {'name': 'AP 7109 Iris Impact', 'r': 104, 'g': 60, 'b': 103},
  {'name': 'AP 7110 Happy Hyacinth', 'r': 178, 'g': 116, 'b': 177},
  {'name': 'AP 7111 Japanese Lilac', 'r': 195, 'g': 144, 'b': 197},
  {'name': 'AP 7112 Wisteria', 'r': 208, 'g': 165, 'b': 209},
  {'name': 'AP 7113 Tickled Pink', 'r': 230, 'g': 190, 'b': 224},
  {'name': 'AP 7114 Study In Scarlet', 'r': 237, 'g': 206, 'b': 230},
  {'name': 'AP 7115 Purple Dye', 'r': 241, 'g': 223, 'b': 233},
  {'name': 'AP 9109 Purple Expresso', 'r': 90, 'g': 64, 'b': 87},
  {'name': 'AP 9110 Velvet Plum', 'r': 134, 'g': 103, 'b': 134},
  {'name': 'AP 9111 Fresh Orchid', 'r': 145, 'g': 113, 'b': 144},
  {'name': 'AP 9112 Violet Light', 'r': 173, 'g': 145, 'b': 174},
  {'name': 'AP 9113 Mild Mist', 'r': 196, 'g': 173, 'b': 196},
  {'name': 'AP 9114 Pink Mirage', 'r': 215, 'g': 186, 'b': 208},
  {'name': 'AP 9115 Baby Pink', 'r': 226, 'g': 204, 'b': 219},
  {'name': 'AP 9116 Airy Merry', 'r': 237, 'g': 226, 'b': 231},
  {'name': 'AP 9117 Pure Impact', 'r': 94, 'g': 54, 'b': 94},
  {'name': 'AP 9118 Voila', 'r': 153, 'g': 108, 'b': 160},
  {'name': 'AP 9119 Shady Purple', 'r': 163, 'g': 121, 'b': 169},
  {'name': 'AP 9120 Pink Reserve', 'r': 181, 'g': 142, 'b': 188},
  {'name': 'AP 9121 Dancing Pink', 'r': 203, 'g': 167, 'b': 206},
  {'name': 'AP 9122 Pink Dress', 'r': 222, 'g': 188, 'b': 219},
  {'name': 'AP 9123 Lavender Breeze', 'r': 232, 'g': 206, 'b': 228},
  {'name': 'AP 9124 Purple Blush', 'r': 238, 'g': 218, 'b': 230},
  {'name': 'AP 9125 Poppy Seed', 'r': 104, 'g': 60, 'b': 117},
  {'name': 'AP 9126 Splendour', 'r': 150, 'g': 108, 'b': 172},
  {'name': 'AP 9127 Rich Float', 'r': 179, 'g': 143, 'b': 197},
  {'name': 'AP 9128 Myriad Mist', 'r': 203, 'g': 171, 'b': 213},
  {'name': 'AP 9129 Fairy Lights', 'r': 221, 'g': 191, 'b': 225},
  {'name': 'AP 9130 Pristine Pink', 'r': 229, 'g': 206, 'b': 229},
  {'name': 'AP 9131 Puff Pond', 'r': 236, 'g': 219, 'b': 232},
  {'name': 'AP 9132 Faint Glow', 'r': 242, 'g': 232, 'b': 233},
  {'name': 'AP 7141 Escapade', 'r': 72, 'g': 61, 'b': 76},
  {'name': 'AP 7142 Vibrant Mauve', 'r': 116, 'g': 102, 'b': 125},
  {'name': 'AP 7143 Purple Illusion', 'r': 136, 'g': 122, 'b': 144},
  {'name': 'AP 7144 Italian Iris', 'r': 174, 'g': 162, 'b': 183},
  {'name': 'AP 7145 Wisteria Wish', 'r': 198, 'g': 181, 'b': 199},
  {'name': 'AP 7146 Mauve Hint', 'r': 210, 'g': 196, 'b': 211},
  {'name': 'AP 7147 Lavender Laugh', 'r': 224, 'g': 214, 'b': 222},
  {'name': 'AP 7148 Lilac Frost', 'r': 237, 'g': 232, 'b': 232},
  {'name': 'AP 7008 Caprice', 'r': 209, 'g': 190, 'b': 218},
  {'name': 'AP 7149 Royal Mauve', 'r': 87, 'g': 63, 'b': 99},
  {'name': 'AP 7150 Regal Jewel', 'r': 138, 'g': 115, 'b': 160},
  {'name': 'AP 7151 Heirloom', 'r': 164, 'g': 144, 'b': 185},
  {'name': 'AP 7152 Mount Olympus', 'r': 191, 'g': 173, 'b': 206},
  {'name': 'AP 7154 Spring Bouquet', 'r': 226, 'g': 213, 'b': 228},
  {'name': 'AP 7155 Pale Chiffon', 'r': 233, 'g': 224, 'b': 231},
  {'name': 'AP 7156 Lavender Lace', 'r': 237, 'g': 230, 'b': 232},
  {'name': 'AP 7157 Egg Plant Delite', 'r': 86, 'g': 61, 'b': 122},
  {'name': 'AP 7158 Royal Robes', 'r': 133, 'g': 110, 'b': 174},
  {'name': 'AP 7159 Velvet Night', 'r': 165, 'g': 148, 'b': 201},
  {'name': 'AP 7160 Dash Of Purple', 'r': 183, 'g': 166, 'b': 212},
  {'name': 'AP 7161 Potpourri', 'r': 205, 'g': 188, 'b': 225},
  {'name': 'AP 7162 Quartz Illusion', 'r': 219, 'g': 205, 'b': 231},
  {'name': 'AP 7163 Lavender Secret', 'r': 227, 'g': 218, 'b': 233},
  {'name': 'AP 7164 Delicate Violet', 'r': 234, 'g': 228, 'b': 235},
  {'name': 'AP 7051 Reverie', 'r': 184, 'g': 175, 'b': 206},
  {'name': 'AP 7165 Dark Triumph', 'r': 74, 'g': 61, 'b': 104},
  {'name': 'AP 7166 Intense Purple', 'r': 126, 'g': 111, 'b': 167},
  {'name': 'AP 7167 Tiffany', 'r': 157, 'g': 148, 'b': 195},
  {'name': 'AP X101 Gold Rush', 'r': 218, 'g': 187, 'b': 40},
  {'name': 'AP X102 Mustard Field', 'r': 211, 'g': 177, 'b': 30},
  {'name': 'AP X103 Victorian Gold', 'r': 238, 'g': 196, 'b': 5},
  {'name': 'AP X104 Sporty Yellow', 'r': 254, 'g': 210, 'b': 34},
  {'name': 'AP 3176 Mid Buff', 'r': 190, 'g': 141, 'b': 60},
  {'name': 'AP X105 Lemon Ole', 'r': 255, 'g': 209, 'b': 0},
  {'name': 'AP X106 Ochre Shadow', 'r': 189, 'g': 146, 'b': 57},
  {'name': 'AP X107 Passion Flower', 'r': 217, 'g': 158, 'b': 34},
  {'name': 'AP X109 Mango Mood', 'r': 255, 'g': 183, 'b': 0},
  {'name': 'AP X110 Orange Vision', 'r': 255, 'g': 165, 'b': 35},
  {'name': 'AP X111 Glorious Sunset', 'r': 247, 'g': 143, 'b': 39},
  {'name': 'AP X112 Glowing Rust', 'r': 231, 'g': 118, 'b': 46},
  {'name': 'AP X113 Orange Tango', 'r': 228, 'g': 97, 'b': 47},
  {'name': 'AP X114 Camp Fire', 'r': 248, 'g': 112, 'b': 44},
  {'name': 'AP X115 Sahara Sunset', 'r': 232, 'g': 79, 'b': 45},
  {'name': 'AP X116 Cider Red', 'r': 171, 'g': 70, 'b': 46},
  {'name': 'AP 0506 Deep Orange', 'r': 221, 'g': 63, 'b': 43},
  {'name': 'AP X117 Rodeo', 'r': 199, 'g': 72, 'b': 60},
  {'name': 'AP X118 Red Red', 'r': 160, 'g': 57, 'b': 48},
  {'name': 'AP X120 Code Red', 'r': 199, 'g': 58, 'b': 52},
  {'name': 'AP 0520 Signal Red', 'r': 189, 'g': 43, 'b': 47},
  {'name': 'AP X122 Rich Rouge', 'r': 192, 'g': 59, 'b': 66},
  {'name': 'AP X123 Crimson Depth', 'r': 149, 'g': 44, 'b': 58},
  {'name': 'AP X124 Red Alert', 'r': 171, 'g': 41, 'b': 67},
  {'name': 'AP X125 Moulin Rouge', 'r': 167, 'g': 55, 'b': 79},
  {'name': 'AP X126 Cherry Brandy', 'r': 173, 'g': 59, 'b': 82},
  {'name': 'AP X127 Raisin Delight', 'r': 98, 'g': 62, 'b': 61},
  {'name': 'AP X128 Dark Cherry', 'r': 107, 'g': 54, 'b': 60},
  {'name': 'AP X129 Burgundy Plus', 'r': 125, 'g': 55, 'b': 64},
  {'name': 'AP X130 Raspberry Crush', 'r': 125, 'g': 67, 'b': 75},
  {'name': 'AP X131 Violet Delight', 'r': 144, 'g': 54, 'b': 78},
  {'name': 'AP X132 Deep Pink', 'r': 172, 'g': 48, 'b': 95},
  {'name': 'AP X133 Regal Purple', 'r': 141, 'g': 48, 'b': 83},
  {'name': 'AP X134 Burnt Violet', 'r': 89, 'g': 58, 'b': 69},
  {'name': 'AP X135 Cherry Bon Bon', 'r': 104, 'g': 50, 'b': 72},
  {'name': 'AP X136 Purple Prose', 'r': 116, 'g': 53, 'b': 83},
  {'name': 'AP X137 Very Fuschia', 'r': 140, 'g': 51, 'b': 98},
  {'name': 'AP X138 Grape Riot', 'r': 147, 'g': 66, 'b': 122},
  {'name': 'AP X139 Violet Saga', 'r': 112, 'g': 57, 'b': 92},
  {'name': 'AP X140 Violet Paradise', 'r': 103, 'g': 58, 'b': 100},
  {'name': 'AP X141 Midnight Interlude', 'r': 88, 'g': 59, 'b': 99},
  {'name': 'AP X142 Nautical Mile', 'r': 55, 'g': 70, 'b': 119},
  {'name': 'AP X143 Royal Wave', 'r': 56, 'g': 64, 'b': 93},
  {'name': 'AP X144 Colonial Blue', 'r': 46, 'g': 68, 'b': 104},
  {'name': 'AP X145 Inky Sea', 'r': 39, 'g': 73, 'b': 111},
  {'name': 'AP X146 Ocean Force', 'r': 0, 'g': 83, 'b': 135},
  {'name': 'AP X147 Mineral Blue', 'r': 0, 'g': 107, 'b': 145},
  {'name': 'AP X148 Pigeon Crest', 'r': 30, 'g': 80, 'b': 106},
  {'name': 'AP X149 Polished Blue', 'r': 0, 'g': 106, 'b': 126},
  {'name': 'AP X150 Teal Dream', 'r': 36, 'g': 73, 'b': 83},
  {'name': 'AP X151 Turquoise Ocean', 'r': 36, 'g': 88, 'b': 96},
  {'name': 'AP X152 Night At Sea', 'r': 35, 'g': 81, 'b': 87},
  {'name': 'AP 0757 Pine-N', 'r': 54, 'g': 100, 'b': 79},
  {'name': 'AP X153 Amazon Moss', 'r': 44, 'g': 91, 'b': 77},
  {'name': 'AP X155 Emerald Lights', 'r': 15, 'g': 104, 'b': 70},
  {'name': 'AP X156 Hill And Vale', 'r': 18, 'g': 110, 'b': 70},
  {'name': 'AP X157 Green Ebony', 'r': 70, 'g': 102, 'b': 72},
  {'name': 'AP X158 Forest Glade', 'r': 83, 'g': 134, 'b': 67},
  {'name': 'AP X159 Loud Lime', 'r': 99, 'g': 176, 'b': 36},
  {'name': 'AP X160 Chrome Green', 'r': 107, 'g': 139, 'b': 69},
  {'name': 'AP L101 Swan Wing', 'r': 245, 'g': 241, 'b': 229},
  {'name': 'AP L102 Milky Way', 'r': 243, 'g': 239, 'b': 228},
  {'name': 'AP L103 Pearl Star', 'r': 243, 'g': 239, 'b': 228},
  {'name': 'AP L104 Cotton Wool', 'r': 242, 'g': 240, 'b': 231},
  {'name': 'AP 0765 Morning Glory', 'r': 240, 'g': 238, 'b': 230},
  {'name': 'AP L105 Crystal Peak', 'r': 243, 'g': 240, 'b': 231},
  {'name': 'AP L107 Virgin Lace', 'r': 238, 'g': 233, 'b': 229},
  {'name': 'AP L108 Cream Pudding', 'r': 234, 'g': 236, 'b': 230},
  {'name': 'AP 0763 Iceland', 'r': 235, 'g': 238, 'b': 232},
  {'name': 'AP L109 Icy Peak', 'r': 231, 'g': 231, 'b': 223},
  {'name': 'AP L111 Sheer Ice', 'r': 228, 'g': 235, 'b': 230},
  {'name': 'AP L112 White Echo', 'r': 235, 'g': 241, 'b': 233},
  {'name': 'AP L113 Seagull Point', 'r': 231, 'g': 241, 'b': 232},
  {'name': 'AP L114 Aqua Hint', 'r': 222, 'g': 238, 'b': 235},
  {'name': 'AP L115 White Bisque', 'r': 224, 'g': 237, 'b': 229},
  {'name': 'AP L116 Menthol', 'r': 231, 'g': 241, 'b': 230},
  {'name': 'AP L117 Mint Essence', 'r': 231, 'g': 240, 'b': 230},
  {'name': 'AP L118 Water Spray', 'r': 237, 'g': 242, 'b': 232},
  {'name': 'AP L119 White Satin', 'r': 237, 'g': 241, 'b': 231},
  {'name': 'AP L120 Mint Lustre', 'r': 239, 'g': 241, 'b': 228},
  {'name': 'AP L121 Moonlight', 'r': 245, 'g': 242, 'b': 226},
  {'name': 'AP L122 Skimmed Cream', 'r': 245, 'g': 242, 'b': 231},
  {'name': 'AP L123 Angel Cloud', 'r': 245, 'g': 241, 'b': 229},
  {'name': 'AP L124 Pure Ivory', 'r': 245, 'g': 241, 'b': 225},
  {'name': 'AP 0307 Cream', 'r': 240, 'g': 230, 'b': 203},
  {'name': 'AP L125 Silver Comet', 'r': 248, 'g': 243, 'b': 227},
  {'name': 'AP L126 Sugared Nut', 'r': 248, 'g': 242, 'b': 225},
  {'name': 'AP L127 Sesame Seed', 'r': 239, 'g': 231, 'b': 210},
  {'name': 'AP 3203 Puppy Love', 'r': 238, 'g': 226, 'b': 202},
  {'name': 'AP L129 Cold Coffee', 'r': 231, 'g': 217, 'b': 192},
  {'name': 'AP L131 Lovely Lace', 'r': 238, 'g': 228, 'b': 205},
  {'name': 'AP L132 Natural Linen', 'r': 240, 'g': 233, 'b': 215},
  {'name': 'AP L133 Arabian Sand', 'r': 243, 'g': 236, 'b': 216},
  {'name': 'AP L134 Double Cream', 'r': 242, 'g': 238, 'b': 223},
  {'name': 'AP L135 Sahara Dream', 'r': 233, 'g': 224, 'b': 206},
  {'name': 'AP L136 Pebble White', 'r': 241, 'g': 234, 'b': 219},
  {'name': 'AP 0952 Soft Glow', 'r': 234, 'g': 226, 'b': 213},
  {'name': 'AP L138 Snow Blush', 'r': 245, 'g': 236, 'b': 222},
  {'name': 'AP L139 Blush', 'r': 250, 'g': 238, 'b': 228},
  {'name': 'AP L140 Crushed Ice', 'r': 244, 'g': 237, 'b': 225},
  {'name': 'AP L141 South Pole', 'r': 247, 'g': 240, 'b': 229},
  {'name': 'AP L142 Mica Matte', 'r': 243, 'g': 236, 'b': 229},
  {'name': 'AP L143 Rain Drop', 'r': 247, 'g': 242, 'b': 233},
  {'name': 'AP L144 Love Song', 'r': 245, 'g': 241, 'b': 232},
  {'name': 'AP L145 White Cameo', 'r': 247, 'g': 241, 'b': 234},
  {'name': 'AP L146 Sonnet', 'r': 247, 'g': 243, 'b': 236},
  {'name': 'AP L147 Harmony', 'r': 241, 'g': 235, 'b': 224},
  {'name': 'AP L148 Blossom Tint', 'r': 245, 'g': 240, 'b': 229},
  {'name': 'AP L149 Eggshell', 'r': 240, 'g': 237, 'b': 224},
  {'name': 'AP L150 Pressed Linen', 'r': 247, 'g': 243, 'b': 232},
  {'name': 'AP L151 Raw Jute', 'r': 244, 'g': 239, 'b': 226},
  {'name': 'AP L152 Cream Pie', 'r': 247, 'g': 246, 'b': 237},
  {'name': 'AP L153 Pristine Linen', 'r': 241, 'g': 240, 'b': 227},
  {'name': 'AP L154 Pipe Dream', 'r': 246, 'g': 244, 'b': 234},
  {'name': 'AP L155 Pale Sisal', 'r': 246, 'g': 245, 'b': 235},
  {'name': 'AP L156 Almost Ivory', 'r': 243, 'g': 239, 'b': 227},
  {'name': 'AP L157 White Canvas', 'r': 240, 'g': 235, 'b': 224},
  {'name': 'AP L158 Silence', 'r': 240, 'g': 235, 'b': 225},
  {'name': 'AP L159 Dreamy Night', 'r': 233, 'g': 229, 'b': 216},
  {'name': 'AP L160 Soft Silk', 'r': 239, 'g': 233, 'b': 221},
];

// --- 3. SECURE CLOUD AI SERVICE (OPENROUTER) ---
class AiService {
  Future<String> getDesignSuggestions(String colorName, String hex) async {
    final String apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      return "API Key missing! Please check your .env file.";
    }

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/Dhvani30/color_picker', 
          'X-Title': 'ChromaPick',
        },
        body: jsonEncode({
          'model': 'qwen/qwen-2.5-7b-instruct', 
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert interior designer and color theorist. Provide 2 informative and practical interior design tips for using the paint color "$colorName" (HEX: $hex). Include suggestions for complementary accent colors, ideal room types, or lighting conditions. Do not use any emojis in your response. Keep the total response concise, under 250 characters.'
            }
          ],
          'temperature': 0.7
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "AI is busy. Please try again!";
      }
    } catch (e) {
      return "Connection error. Check your internet.";
    }
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  CameraController? _cameraController;
  bool _isCameraPermissionGranted = false;
  bool _permissionDenied = false;
  bool _isFrameFrozen = false;
  Uint8List? _frozenFrameBytes;

  Uint8List? _galleryImageBytes;
  final ImagePicker _picker = ImagePicker();

  final GlobalKey _viewportKey = GlobalKey();
  Offset _cursorPosition = Offset.zero;
  Color _pickedColor = Colors.white;
  String _hexCode = '#FFFFFF';
  String _rgbCode = 'RGB(255, 255, 255)';
  String _colorName = 'Unknown';
  
  List<ColorRecord> _colorHistory = [];
  String _lastHapticColorName = '';
  Timer? _samplingTimer;
  Timer? _hapticTimer;
  bool _isDraggingCursor = false;

  static const String _historyKey = 'color_history';
  SharedPreferences? _prefs;
  int _currentMode = 0; 

  final AiService _aiService = AiService();
  String _aiSuggestion = '';
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistoryFromStorage();
    _requestCameraPermission();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startContinuousSampling();
    });
  }

  @override
  void dispose() {
    _samplingTimer?.cancel();
    _hapticTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryFromStorage() async {
    _prefs = await SharedPreferences.getInstance();
    final historyJson = _prefs?.getString(_historyKey);
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _colorHistory = decoded.map((json) => ColorRecord.fromJson(json)).toList();
        });
      } catch (e) {
        print('Error loading history: $e');
      }
    }
  }

  Future<void> _saveHistoryToStorage() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    final historyJson = jsonEncode(_colorHistory.map((record) => record.toJson()).toList());
    await _prefs?.setString(_historyKey, historyJson);
  }

  void _startContinuousSampling() {
    _samplingTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_currentMode == 0 || _currentMode == 1) {
        _readPixelAt(_cursorPosition);
      }
    });
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isCameraPermissionGranted = true);
      _initializeCamera();
    } else {
      setState(() => _permissionDenied = true);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras[0], ResolutionPreset.high);
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _freezeFrame() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      setState(() {
        _isFrameFrozen = true;
        _frozenFrameBytes = bytes;
        _currentMode = 1;
      });
    }
  }

  void _resumeCamera() {
    setState(() {
      _isFrameFrozen = false;
      _frozenFrameBytes = null;
      _currentMode = 0;
    });
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _galleryImageBytes = bytes;
        _currentMode = 2;
      });
    }
  }

  Future<void> _readPixelAt(Offset position) async {
    final renderObject = _viewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    final boundary = renderObject;

    try {
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      final Uint8List pixels = byteData.buffer.asUint8List();
      final RenderBox renderBox = boundary;
      final Size boxSize = renderBox.size;

      final int x = (position.dx / boxSize.width * image.width).clamp(0, image.width - 1).toInt();
      final int y = (position.dy / boxSize.height * image.height).clamp(0, image.height - 1).toInt();

      final int pixelIndex = (y * image.width + x) * 4;
      final int r = pixels[pixelIndex];
      final int g = pixels[pixelIndex + 1];
      final int b = pixels[pixelIndex + 2];

      final Color newColor = Color.fromRGBO(r, g, b, 1);
      final String hex = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      final String newName = _findClosestAsianPaintsName(r, g, b);
      
      if (newName != _lastHapticColorName) {
        _lastHapticColorName = newName;

        if (_isDraggingCursor) {
          _hapticTimer?.cancel();
          _hapticTimer = Timer(
            const Duration(milliseconds: 150),
            () {
              HapticFeedback.selectionClick();
            },
          );
        }
      }
      
      if (mounted) {
        setState(() {
          _pickedColor = newColor;
          _hexCode = hex;
          _rgbCode = 'RGB($r, $g, $b)';
          _colorName = newName;
        });
      }
    } catch (e) {
      return;
    }
  }

  String _findClosestAsianPaintsName(int r, int g, int b) {
    double minDistance = double.infinity;
    String closestName = 'Unknown';

    for (var paint in asianPaintsDatabase) {
      int pR = paint['r'];
      int pG = paint['g'];
      int pB = paint['b'];
      double distance = sqrt(pow(r - pR, 2) + pow(g - pG, 2) + pow(b - pB, 2));

      if (distance < minDistance) {
        minDistance = distance;
        closestName = paint['name'];
      }
    }
    return closestName;
  }

  void _saveToHistory() {
    HapticFeedback.mediumImpact();
    setState(() {
      _colorHistory.insert(0, ColorRecord(
        color: _pickedColor,
        hex: _hexCode,
        rgba: _rgbCode,
        name: _colorName,
        timestamp: DateTime.now(),
      ));
    });
    _saveHistoryToStorage();
  }

  Future<void> _getAiSuggestion() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAiLoading = true;
      _aiSuggestion = 'Consulting design oracle...';
    });

    final suggestion = await _aiService.getDesignSuggestions(_colorName, _hexCode);
    
    setState(() {
      _isAiLoading = false;
      _aiSuggestion = suggestion;
    });
  }

  Widget _buildControlButton({
    required String text,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // --- UNIFIED DARK GLASSMORPHISM ---
                color: isActive
                    ? Colors.black.withOpacity(0.6)
                    : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.white54),
              const SizedBox(height: 20),
              const Text('Permission Denied', style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 10),
              const Text('Please grant camera permission in settings', 
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (!_isCameraPermissionGranted || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text('Loading camera...', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_cursorPosition == Offset.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _cursorPosition = Offset(size.width / 2, size.height / 2 - 100); 
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Full Screen Camera/Viewport
          Positioned.fill(
            child: RepaintBoundary(
              key: _viewportKey,
              child: _buildViewport(),
            ),
          ),
         
          // 2. Top Control Buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildControlButton(
                        text: 'Live',
                        isActive: _currentMode == 0,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _currentMode = 0);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildControlButton(
                        text: 'Gallery',
                        isActive: _currentMode == 2,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _pickFromGallery();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: _isFrameFrozen
                            ? _buildControlButton(
                                text: 'Resume',
                                isActive: true,
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  _resumeCamera();
                                },
                              )
                            : _buildControlButton(
                                text: 'Pause',
                                isActive: false,
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  _freezeFrame();
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Glass Color Info Overlay
          Positioned(
            top: 110, 
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // --- UNIFIED DARK GLASSMORPHISM ---
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _pickedColor, 
                          borderRadius: BorderRadius.circular(12), 
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _colorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _hexCode,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _rgbCode,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.save, color: Colors.white, size: 18),
                          onPressed: _saveToHistory,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: IconButton(
                          icon: _isAiLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                          onPressed: _isAiLoading ? null : _getAiSuggestion,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. AI Suggestion Panel
          if (_aiSuggestion.isNotEmpty && _aiSuggestion != 'Consulting design oracle...')
            Positioned(
              top: 210,
              right: 16,
              left: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _aiSuggestion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _aiSuggestion = '');
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Draggable Crosshair
          Positioned(
            left: _cursorPosition.dx - 20, 
            top: _cursorPosition.dy - 20,
            child: GestureDetector(
              onPanStart: (_) {
                _isDraggingCursor = true;
              },
              onPanUpdate: (details) {
                // FIX: Removed _readPixelAt from here to eliminate lag. 
                // setState is lightweight and keeps the drag buttery smooth.
                setState(() {
                  _cursorPosition += details.delta;
                });
              },
              onPanEnd: (_) {
                _isDraggingCursor = false;
                HapticFeedback.mediumImpact();
                // Read the final position immediately after dragging stops
                _readPixelAt(_cursorPosition);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  // --- UNIFIED DARK GLASSMORPHISM ---
                  color: Colors.black.withOpacity(0.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ),

          // 6. Bottom History Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.12,
            minChildSize: 0.12,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      // --- UNIFIED DARK GLASSMORPHISM ---
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            controller: scrollController,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _colorHistory.length,
                            itemBuilder: (context, index) {
                              final record = _colorHistory[index];
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _pickedColor = record.color;
                                    _hexCode = record.hex;
                                    _rgbCode = record.rgba;
                                    _colorName = record.name;
                                  });
                                },
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    _colorHistory.removeAt(index);
                                  });
                                  _saveHistoryToStorage();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    // --- UNIFIED DARK GLASSMORPHISM ---
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: record.color,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        record.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        record.hex,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(record.timestamp),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewport() {
    if (_currentMode == 1 && _frozenFrameBytes != null) {
      return Image.memory(_frozenFrameBytes!, fit: BoxFit.cover);
    } else if (_currentMode == 2 && _galleryImageBytes != null) {
      return Image.memory(_galleryImageBytes!, fit: BoxFit.cover);
    } else if (_cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    } else {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Text('Camera not ready', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }
}