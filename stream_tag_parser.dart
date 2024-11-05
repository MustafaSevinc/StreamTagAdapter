import 'dart:async';

class StreamTagParser {
  final String startTag;
  final String stopTag;
  final int maxBufferSize;
  final Duration timeoutDuration;
  final StringBuffer _buffer = StringBuffer();
  bool _isBuffering = false;
  Timer? _timeoutTimer;

  String _startTagWindow = '';
  String _stopTagWindow = '';

  StreamTagParser(this.startTag, this.stopTag,
      {this.maxBufferSize = 1024,
      this.timeoutDuration = const Duration(seconds: 30)});

  StreamSubscription<void>? attachToStream(
      Stream<List<int>> stream, void Function(String) onPatternMatched) {
    final streamSubscription = stream.listen((data) {
      for (var char in data.map((e) => String.fromCharCode(e))) {
        _processChar(char, onPatternMatched);
      }
    });
    return streamSubscription;
  }

  void _processChar(String char, void Function(String) onPatternMatched) {
    _updateSlidingWindow(char);

    //if (!_isBuffering && _startTagWindow == startTag)  //To disable checking startTag after seeing first time
    if (_startTagWindow == startTag) {
      _startBuffering();
    } else if (_isBuffering) {
      _buffer.write(char);
      if (_stopTagWindow == stopTag) {
        _finishBuffering(onPatternMatched);
      } else if (_buffer.length > maxBufferSize) {
        _resetBuffer();
      }
    }
  }

  void _updateSlidingWindow(String char) {
    _startTagWindow = (_startTagWindow + char)
        .substring((_startTagWindow.length + 1) > startTag.length ? 1 : 0);
    _stopTagWindow = (_stopTagWindow + char)
        .substring((_stopTagWindow.length + 1) > stopTag.length ? 1 : 0);
  }

  void _startBuffering() {
    _isBuffering = true;
    _buffer.clear();
    _startTimeout();
  }

  void _finishBuffering(void Function(String) onPatternMatched) {
    final result = _buffer.toString();
    final cleanedResult = result.substring(0, result.length - stopTag.length);
    onPatternMatched(cleanedResult);
    _isBuffering = false;
    _cancelTimeout();
  }

  void _resetBuffer() {
    //TODO: can give/ throw timeout error or buffer size limit exceed error
    _buffer.clear();
    _isBuffering = false;
    _cancelTimeout();
  }

  void _startTimeout() {
    _cancelTimeout();
    _timeoutTimer = Timer(timeoutDuration, _resetBuffer);
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }
}
