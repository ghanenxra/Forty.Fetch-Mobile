import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import '../providers/download_provider.dart';
import 'app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _selectedQuality = '1080p 60fps';
  String? _savePath;
  final List<String> _qualityOptions = [
    '360p 60fps',
    '480p 60fps',
    '720p 60fps',
    '1080p 60fps',
    '1440p 60fps',
    '2160p 60fps (4K)',
    '4320p 60fps (8K)',
    'MP3 (Audio)'
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _startDownload() {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid YouTube URL')),
      );
      return;
    }
    
    // Use user picked path, or default fallback
    String dirPath = _savePath ?? (Platform.isWindows ? 'C:\\Users\\Public\\Downloads' : '/storage/emulated/0/Download/FortyFetch');
    
    // Ensure directory exists
    Directory(dirPath).createSync(recursive: true);
    
    final outputPath = '$dirPath/%(title).180s [%(id)s].%(ext)s';
    
    context.read<DownloadProvider>().startDownload(
      _urlController.text.trim(),
      _selectedQuality,
      outputPath,
    );
  }

  void _showCoffeeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Support the Project',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
            ),
            const SizedBox(height: 16),
            const Text('UPI ID: 9024810096@fam', style: TextStyle(color: AppTheme.accent, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://paypal.me/placeholder')),
              icon: const Icon(Icons.payment),
              label: const Text('PayPal'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0079C1)),
            ),
            const SizedBox(height: 16),
            // Placeholder for QR Image
            Container(
              height: 150,
              width: 150,
              color: Colors.white24,
              child: Image.asset('assets/qr_code.png', fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = context.watch<DownloadProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FORTY.FETCH',
                        style: GoogleFonts.rubikMonoOne(
                          fontSize: 32,
                          color: AppTheme.accent,
                        ),
                      ),
                      Text(
                        'POWERED BY FORTY QUINN',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF666B76),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.system_update_alt, color: Color(0xFF1E7F5D)),
                        onPressed: () {},
                        tooltip: 'Check for Engine Updates',
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Color(0xFF2A2F39)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main Download Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASTE YOUTUBE LINK',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'https://youtube.com/...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste, color: AppTheme.accent),
                          onPressed: () async {
                            // Implement clipboard paste
                          },
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedQuality,
                            dropdownColor: AppTheme.cardSurface,
                            items: _qualityOptions.map((q) {
                              return DropdownMenuItem(value: q, child: Text(q));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedQuality = val);
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            String? selectedDirectory = await getDirectoryPath();
                            if (selectedDirectory != null) {
                              setState(() {
                                _savePath = selectedDirectory;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Save location set to: $_savePath')),
                              );
                            }
                          },
                          icon: const Icon(Icons.folder, size: 20),
                          label: Text(_savePath == null ? 'Save To' : 'Saved!'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.inputBoxSurface,
                            foregroundColor: AppTheme.textMain,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Live Progress
              if (downloadState.isDownloading || downloadState.statusMessage == 'Completed!' || downloadState.statusMessage == 'Download failed')
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        downloadState.statusMessage,
                        style: GoogleFonts.inter(
                          color: downloadState.statusMessage.contains('fail') ? AppTheme.errorRed : AppTheme.textMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (downloadState.errorMessage.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(downloadState.errorMessage, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                         ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: downloadState.percentage / 100,
                          minHeight: 12,
                          backgroundColor: const Color(0xFF070A0F),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${downloadState.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${downloadState.speed} | ETA ${downloadState.eta}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Action & Support Footer
              ElevatedButton(
                onPressed: downloadState.isDownloading ? null : _startDownload,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  downloadState.isDownloading ? 'FETCHING...' : 'START FETCH',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _showCoffeeModal,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF813F)),
                    child: const Text('Buy Me a Coffee'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse('https://discord.com/users/1323161662739714120')),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF5865F2)),
                    child: const Text('Discord'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse('https://github.com/ghanenxra')),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D313A)),
                    child: const Text('GitHub'),
                  ),
                ],
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'CREATED BY GC',
                    style: TextStyle(color: Color(0xFFFF4FA3), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
