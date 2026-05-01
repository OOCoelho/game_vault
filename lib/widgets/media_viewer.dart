import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';

class MediaViewer extends StatefulWidget {
  final List<String> screenshots;
  final List<GameVideo> videos;
  final int initialIndex; // índice global (vídeos vêm primeiro)

  const MediaViewer({
    required this.screenshots,
    required this.videos,
    this.initialIndex = 0,
    Key? key,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required List<String> screenshots,
    required List<GameVideo> videos,
    int initialIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      useSafeArea: false,
      builder: (_) => MediaViewer(
        screenshots: screenshots,
        videos: videos,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late int _current;
  late PageController _pageCtrl;
  final ScrollController _thumbScroll = ScrollController();

  // Vídeos no início, screenshots depois
  late final List<_MediaItem> _items;

  VideoPlayerController? _videoCtrl;
  bool _videoLoading = false;
  bool _videoPaused = false;
  Duration _videoPos = Duration.zero;
  Duration _videoDur = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _items = [
      ...widget.videos.map((v) => _MediaItem.video(v)),
      ...widget.screenshots.map((s) => _MediaItem.image(s)),
    ];

    _current = widget.initialIndex.clamp(0, _items.length - 1);
    _pageCtrl = PageController(initialPage: _current);

    if (_items[_current].isVideo) _initVideo(_items[_current].video!);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _videoCtrl?.dispose();
    _pageCtrl.dispose();
    _thumbScroll.dispose();
    super.dispose();
  }

  Future<void> _initVideo(GameVideo v) async {
    await _videoCtrl?.dispose();
    _videoCtrl = null;
    setState(() => _videoLoading = true);

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(v.videoUrl));
    await ctrl.initialize();
    ctrl.addListener(() {
      if (!mounted) return;
      setState(() {
        _videoPos = ctrl.value.position;
        _videoDur = ctrl.value.duration;
      });
    });
    ctrl.play();
    setState(() {
      _videoCtrl = ctrl;
      _videoLoading = false;
      _videoPaused = false;
    });
  }

  void _goTo(int index) {
    if (index == _current) return;

    // Pausa vídeo anterior
    _videoCtrl?.pause();

    setState(() => _current = index);
    _pageCtrl.jumpToPage(index);

    // Centraliza thumbnail
    _thumbScroll.animateTo(
      index * 98.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    if (_items[index].isVideo) {
      _initVideo(_items[index].video!);
    } else {
      _videoCtrl?.dispose();
      _videoCtrl = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SizedBox();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // ── Área principal ──
          Column(
            children: [
              // Barra superior
              Container(
                color: const Color(0xFF171a21),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _items[_current].isVideo
                            ? _items[_current].video!.name
                            : 'Screenshot ${_current - widget.videos.length + 1}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${_current + 1} / ${_items.length}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Conteúdo principal
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _items.length,
                      onPageChanged: _goTo,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        if (item.isVideo) {
                          return _buildVideoPlayer(item.video!);
                        }
                        return InteractiveViewer(
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image,
                                    color: Colors.grey),
                          ),
                        );
                      },
                    ),

                    // Seta esquerda
                    if (_current > 0)
                      Positioned(
                        left: 8,
                        child: _navButton(
                            Icons.chevron_left, () => _goTo(_current - 1)),
                      ),

                    // Seta direita
                    if (_current < _items.length - 1)
                      Positioned(
                        right: 8,
                        child: _navButton(
                            Icons.chevron_right, () => _goTo(_current + 1)),
                      ),
                  ],
                ),
              ),

              // Barra de controle do vídeo (só aparece em vídeos)
              if (_items[_current].isVideo && _videoCtrl != null)
                _buildVideoControls(),

              // Thumbnails
              Container(
                color: const Color(0xFF171a21),
                height: 80,
                child: ListView.builder(
                  controller: _thumbScroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final active = i == _current;
                    final item = _items[i];
                    return GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 6),
                        width: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: active
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item.isVideo
                                    ? item.video!.preview
                                    : item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1b2838)),
                              ),
                              if (item.isVideo)
                                const Center(
                                  child: Icon(Icons.play_circle_outline,
                                      color: Colors.white70, size: 22),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white70),
        ),
      );

  Widget _buildVideoPlayer(GameVideo video) {
    if (_videoLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent));
    }
    if (_videoCtrl == null || !_videoCtrl!.value.isInitialized) {
      return Center(
        child: Text(video.name,
            style: const TextStyle(color: Colors.grey)),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoCtrl!.value.isPlaying) {
            _videoCtrl!.pause();
            _videoPaused = true;
          } else {
            _videoCtrl!.play();
            _videoPaused = false;
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoCtrl!.value.aspectRatio,
            child: VideoPlayer(_videoCtrl!),
          ),
          if (_videoPaused)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54),
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 34),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    final pos = _videoPos.inSeconds.toDouble();
    final dur = _videoDur.inSeconds.toDouble();

    String _fmt(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Container(
      color: const Color(0xFF1b2838),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: pos.clamp(0, dur > 0 ? dur : 1),
              min: 0,
              max: dur > 0 ? dur : 1,
              onChanged: (v) => _videoCtrl
                  ?.seekTo(Duration(seconds: v.toInt())),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _videoPaused || !(_videoCtrl?.value.isPlaying ?? false)
                      ? Icons.play_arrow
                      : Icons.pause,
                  color: Colors.white70,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    if (_videoCtrl!.value.isPlaying) {
                      _videoCtrl!.pause();
                      _videoPaused = true;
                    } else {
                      _videoCtrl!.play();
                      _videoPaused = false;
                    }
                  });
                },
              ),
              Text(
                '${_fmt(_videoPos)} / ${_fmt(_videoDur)}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 11),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.replay_10,
                    color: Colors.white70, size: 20),
                onPressed: () => _videoCtrl?.seekTo(
                    _videoPos - const Duration(seconds: 10)),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10,
                    color: Colors.white70, size: 20),
                onPressed: () => _videoCtrl?.seekTo(
                    _videoPos + const Duration(seconds: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaItem {
  final bool isVideo;
  final GameVideo? video;
  final String? imageUrl;

  _MediaItem.video(this.video)
      : isVideo = true,
        imageUrl = null;

  _MediaItem.image(this.imageUrl)
      : isVideo = false,
        video = null;
}