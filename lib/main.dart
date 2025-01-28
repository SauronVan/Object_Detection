import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Speech App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home Page',
          style: TextStyle(color: Colors.white, fontSize: 25.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0.0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            _buildNavigationButton(
              context,
              title: 'Find Object',
              destination: SpeechToTextPage(
                title: 'Find Object',
                cameras: cameras,
              ),
            ),
            SizedBox(height: 50),
            _buildNavigationButton(
              context,
              title: 'Go Shopping',
              destination: SpeechToTextPage(
                title: 'Go Shopping',
                cameras: cameras,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context,
      {required String title, required Widget destination}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        height: 100,
        width: 350,
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
class SpeechToTextWidget extends StatefulWidget {
  @override
  _SpeechToTextWidgetState createState() => _SpeechToTextWidgetState();
}

class _SpeechToTextWidgetState extends State<SpeechToTextWidget> {
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  String _text = "Press the button to start speaking";

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
  }

  void _toggleListening() async {
    if (_isListening) {
      // Stop listening when the button is pressed again
      _speechToText.stop();
      setState(() {
        _isListening = false;
        _text = "Press the button to start speaking";
      });
    } else {
      // Start or restart listening
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _text = "Listening...";
        });
        _startListening();
      } else {
        setState(() {
          _text = "Unable to connect to the microphone.";
        });
      }
    }
  }

  void _startListening() {
    _speechToText.listen(
      onResult: (result) {
        // Print recognized words to the console
        print("Recognized words: ${result.recognizedWords}");
      },
      listenMode: stt.ListenMode.dictation, // Continuous listening
      onSoundLevelChange: (level) {}, // Optional: handle sound level changes
      cancelOnError: false,
      onDevice: true, // Ensure on-device processing
      partialResults: true, // Allows partial results to keep listening
    );

    // Automatically restart listening if it stops due to silence
    _speechToText.statusListener = (status) {
      if (status == "notListening" && _isListening) {
        _startListening(); // Restart listening if user hasn't pressed stop
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            _text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 20),
          FloatingActionButton(
            onPressed: _toggleListening,
            child: Icon(
              _isListening ? Icons.stop : Icons.mic,
            ),
          ),
        ],
      ),
    );
  }
}

class SpeechToTextPage extends StatelessWidget {
  final String title;
  final List<CameraDescription> cameras;

  const SpeechToTextPage({Key? key, required this.title, required this.cameras})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: CameraSpeechWidget(cameras: cameras),
    );
  }
}

class CameraSpeechWidget extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraSpeechWidget({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraSpeechWidgetState createState() => _CameraSpeechWidgetState();
}

class _CameraSpeechWidgetState extends State<CameraSpeechWidget> {
  late CameraController _cameraController;
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _isRecording = false;
  String _selectedLanguage = 'en_US';
  String _recognizedText = "Press the button to start speaking";
  List<stt.LocaleName> _availableLanguages = [];

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _loadAvailableLanguages();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      // Lock orientation to portrait
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }


  Future<void> _loadAvailableLanguages() async {
    List<stt.LocaleName> locales = await _speechToText.locales();
    setState(() {
      _availableLanguages = locales;
      if (_availableLanguages.isNotEmpty) {
        _selectedLanguage = _availableLanguages[0].localeId;
      }
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      bool available = await _speechToText.initialize(
        onStatus: (status) => print("Status: $status"),
        onError: (error) => print("Error: ${error.errorMsg}"),
      );
      print("Speech recognition available: $available");
      if (available) {
        setState(() => _isListening = true);
        print("Listening...");
        _speechToText.listen(
          localeId: _selectedLanguage,
          onResult: (result) {
            setState(() => _recognizedText = result.recognizedWords);
            print("Recognized Text: ${result.recognizedWords}");
          },
        );
      } else {
        print("Speech recognition not available");
      }
    }
  }


  void _stopListening() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
      _recognizedText = "Press the button to start speaking";
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        await _cameraController.stopVideoRecording();
      } catch (e) {
        print("Error stopping video: $e");
      }
      setState(() {
        _isRecording = false;
      });
    } else {
      try {
        await _cameraController.startVideoRecording();
      } catch (e) {
        print("Error starting video: $e");
      }
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
    if (_cameraController.value.isRecordingVideo) {
      _cameraController.stopVideoRecording();
    }
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeCamera(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error initializing camera"));
        } else {
          return Column(
            children: [
              Expanded(
                child: _isRecording
                    ? Stack(
                  children: [
                    Transform.scale(
                      scaleX: -1, // Mirror horizontally
                      child: Transform.rotate(
                        angle: 90 * 3.1416 / 180,  // Rotate the camera preview by 90 degrees (clockwise)
                        child: Container(
                          width: 800, // Set your desired width
                          height: 500, // Set your desired height
                          child: CameraPreview(_cameraController),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ],
                )
                    : Center(child: Text("")),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedLanguage = newValue!;
                        });
                      },
                      items: _availableLanguages
                          .map((locale) => DropdownMenuItem(
                        value: locale.localeId,
                        child: Text(locale.name),
                      ))
                          .toList(),
                    ),
                    Text(_recognizedText),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(height: 100),
                  ElevatedButton.icon(
                    onPressed: _toggleListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(
                        _isListening ? "Stop Listening" : "Start Listening"),
                  ),
                  SizedBox(height: 100),
                  ElevatedButton.icon(
                    onPressed: _toggleRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
                    label: Text(
                        _isRecording ? "Stop Recording" : "Start Recording"),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }
}



