import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class MusicPlayerController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Global state for the current song.
  Rx<Map<String, dynamic>> currentSong = Rx<Map<String, dynamic>>({});
  RxBool isPlaying = false.obs;
  Rx<Duration> duration = Duration.zero.obs;
  Rx<Duration> position = Duration.zero.obs;
  RxString lyrics = "Loading lyrics...".obs;
  // Flag to indicate audio is loading.
  RxBool isAudioLoading = true.obs;

  // NEW: Upcoming songs queue (only future tracks).
  RxList<Map<String, dynamic>> upcomingSongs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _setupAudioListeners();
  }

  /// Loads a new song (single track) and resets playback.
  Future<void> loadSong(Map<String, dynamic> song) async {
    // Stop current playback completely.
    await _audioPlayer.stop();
    // Reset state.
    currentSong.value = song;
    duration.value = Duration.zero;
    position.value = Duration.zero;
    lyrics.value = "Loading lyrics...";
    isAudioLoading.value = true;
    // Clear any existing queue (since this is a single track).
    upcomingSongs.clear();
    // Fetch lyrics and prepare song.
    await _fetchLyrics(song);
    await _prepareSong(song);
  }

  /// Loads a full queue from a list of songs, starting at the tapped index.
  Future<void> loadQueueAndPlay({
    required List<Map<String, dynamic>> fullSongList,
    required int startIndex,
  }) async {
    if (fullSongList.isEmpty || startIndex < 0 || startIndex >= fullSongList.length) return;

    // Stop any current playback.
    await _audioPlayer.stop();
    // Set the current song as the tapped song.
    currentSong.value = fullSongList[startIndex];
    duration.value = Duration.zero;
    position.value = Duration.zero;
    lyrics.value = "Loading lyrics...";
    isAudioLoading.value = true;

    // Set upcoming songs: all songs after the tapped index.
    if (startIndex < fullSongList.length - 1) {
      upcomingSongs.assignAll(fullSongList.sublist(startIndex + 1));
    } else {
      upcomingSongs.clear();
    }

    // Fetch lyrics and prepare the current song.
    await _fetchLyrics(currentSong.value);
    await _prepareSong(currentSong.value);
  }

  /// Optional: Plays a specific song from the upcoming queue when tapped.
  Future<void> playSongFromQueue(int queueIndex) async {
    if (queueIndex < 0 || queueIndex >= upcomingSongs.length) return;

    // Stop current playback.
    await _audioPlayer.stop();
    // Set the selected song as current.
    currentSong.value = upcomingSongs[queueIndex];

    // Remove the songs up to and including the selected song from the queue.
    upcomingSongs.removeRange(0, queueIndex + 1);

    duration.value = Duration.zero;
    position.value = Duration.zero;
    lyrics.value = "Loading lyrics...";
    isAudioLoading.value = true;

    await _fetchLyrics(currentSong.value);
    await _prepareSong(currentSong.value);
  }

  /// Fetches lyrics from Firestore or uses the provided string.
  Future<void> _fetchLyrics(Map<String, dynamic> song) async {
    try {
      String lyricsUrl = song['lyrics_url'] ?? '';
      if (lyricsUrl.isEmpty) {
        lyrics.value = "Lyrics not available.";
      } else {
        // For simplicity, we assume lyricsUrl contains the actual lyrics.
        lyrics.value = lyricsUrl;
      }
    } catch (e) {
      lyrics.value = "Failed to load lyrics.";
    }
  }

  /// Converts a Google Drive URL to a direct download link.
  String _convertGoogleDriveUrl(String url) {
    if (url.contains("drive.google.com")) {
      final regex = RegExp(r"/d/([a-zA-Z0-9_-]+)");
      final match = regex.firstMatch(url);
      if (match != null) {
        return "https://drive.google.com/uc?export=download&id=${match.group(1)}";
      }
    }
    return url;
  }

  /// Prepares and plays the song.
  Future<void> _prepareSong(Map<String, dynamic> song) async {
    String url = _convertGoogleDriveUrl(song['song_url'] ?? '');
    try {
      // Set source and play the song.
      await _audioPlayer.setSourceUrl(url);
      await _audioPlayer.play(UrlSource(url));
      isPlaying.value = true;
      isAudioLoading.value = false;
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to play song: $e");
      isAudioLoading.value = false;
    }
  }

  /// Sets up audio player listeners.
  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((d) => duration.value = d);
    _audioPlayer.onPositionChanged.listen((p) => position.value = p);

    // Listen for track completion and automatically play next song in queue.
    _audioPlayer.onPlayerComplete.listen((_) async {
      if (upcomingSongs.isNotEmpty) {
        // Automatically load the next song.
        currentSong.value = upcomingSongs.first;
        upcomingSongs.removeAt(0);
        duration.value = Duration.zero;
        position.value = Duration.zero;
        lyrics.value = "Loading lyrics...";
        isAudioLoading.value = true;

        await _fetchLyrics(currentSong.value);
        await _prepareSong(currentSong.value);
      } else {
        // No upcoming songs; stop playback.
        isPlaying.value = false;
        position.value = Duration.zero;
      }
    });
  }

  /// Toggles play/pause.
  void togglePlayPause() {
    if (isAudioLoading.value) return;
    if (isPlaying.value) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
    isPlaying.value = !isPlaying.value;
  }

  /// Seeks to a specified position.
  void seekTo(Duration newPosition) {
    _audioPlayer.seek(newPosition);
    position.value = newPosition;
  }

  /// Rewinds 10 seconds.
  void rewind() {
    final newPos = position.value - const Duration(seconds: 10);
    seekTo(newPos < Duration.zero ? Duration.zero : newPos);
  }

  /// Forwards 10 seconds.
  void forward() {
    final newPos = position.value + const Duration(seconds: 10);
    seekTo(newPos > duration.value ? duration.value : newPos);
  }

  /// Formats a Duration as mm:ss.
  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
