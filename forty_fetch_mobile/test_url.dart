import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  String url = 'https://youtu.be/dQw4w9WgXcQ';
  try {
    print('Testing yt.videos.get...');
    final yt = YoutubeExplode();
    
    print('Getting videoId...');
    final videoId = VideoId(url).value;
    
    print('Fetching video details...');
    var video = await yt.videos.get(videoId);
    print('Title: ${video.title}');
    
    print('Fetching manifest...');
    var manifest = await yt.videos.streamsClient.getManifest(url);
    print('Manifest video streams: ${manifest.videoOnly.length}');
    
    yt.close();
  } catch (e) {
    print('Error: $e');
  }
}
