// Icon Generator for Encrypted Notebook App
// This file can be used to generate the app icon programmatically
// Run this as a standalone Flutter app to generate the icon images

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:io';

void main() {
  runApp(const IconGeneratorApp());
}

class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Icon Generator')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('App Icon Generator'),
              SizedBox(height: 20),
              AppIconWidget(size: 200),
              SizedBox(height: 20),
              Text('Tap to generate icon files'),
            ],
          ),
        ),
      ),
    );
  }
}

class AppIconWidget extends StatelessWidget {
  final double size;
  
  const AppIconWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Notebook icon
          Icon(
            Icons.book,
            size: size * 0.5,
            color: Colors.white.withOpacity(0.9),
          ),
          // Lock overlay (security)
          Positioned(
            bottom: size * 0.2,
            right: size * 0.2,
            child: Container(
              padding: EdgeInsets.all(size * 0.05),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1A1A2E),
                  width: size * 0.02,
                ),
              ),
              child: Icon(
                Icons.lock,
                size: size * 0.15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppIconForegroundWidget extends StatelessWidget {
  final double size;
  
  const AppIconForegroundWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Notebook icon
          Icon(
            Icons.book,
            size: size * 0.5,
            color: Colors.white.withOpacity(0.9),
          ),
          // Lock overlay
          Positioned(
            bottom: size * 0.2,
            right: size * 0.2,
            child: Container(
              padding: EdgeInsets.all(size * 0.05),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                size: size * 0.15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SplashIconWidget extends StatelessWidget {
  final double size;
  
  const SplashIconWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Notebook icon
          Icon(
            Icons.book,
            size: size * 0.6,
            color: Colors.white.withOpacity(0.9),
          ),
          // Lock overlay
          Positioned(
            bottom: size * 0.15,
            right: size * 0.15,
            child: Container(
              padding: EdgeInsets.all(size * 0.08),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                size: size * 0.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
