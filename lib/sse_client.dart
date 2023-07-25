import 'dart:async';
import 'dart:convert';
import 'package:customize_tools/constant.dart';
import 'package:http/http.dart' as http;

class SSEClient {
  static http.Client _client = http.Client();

  static bool forceClosed = false;

  static Stream<String> subscribeToSSE(
      {Map<String, dynamic>? body,
      String host = "",
      String path = "",
      int port = 8080,
      String scheme = "https",
      Function()? onDone}) {
    var lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');
    // ignore: close_sinks
    StreamController<String> streamController = StreamController();
    printDebug("--SUBSCRIBING TO SSE---");
    forceClosed = false;
    while (true) {
      try {
        _client = http.Client();
        Uri uri = Uri(
            host: host,
            port: port,
            path: path,
            scheme: scheme);
        var request = http.Request("POST", uri);
        printDebug("--SUBSCRIBING TO Post---");

        request.headers.addAll({"Content-Type": "application/json"});
        request.body = jsonEncode(body);

        Future<http.StreamedResponse> response = _client.send(request);

        // String all_content = "";
        ///Listening to the response as a stream

        response.asStream().listen((data) {
          ///Applying transforms and listening to it
          data.stream
              .transform(const Utf8Decoder())
              .transform(const LineSplitter())
              .listen(
            (dataLine) {
              printDebug(dataLine);
              if (dataLine.isEmpty) {
                ///This means that the complete event set has been read.
                ///We then add the event to the stream
                // currentSSEModel = SSEModel();
                return;
              }
              streamController.add(dataLine);
            },
            onError: (e, s) {
              printDebug('---ERROR---: data_stream_err_${e is TimeoutException}');
              printDebug(e);
              streamController.addError(e, s);
            },
          ).onDone(() {
            printDebug("data stream is done!");
            if (onDone != null) onDone();
          });
        }, onError: (e, s) {
          printDebug('---ERROR---: response_stream_err');
          printDebug(e);
          streamController.addError(e, s);
        });
      } catch (e, s) {
        printDebug('in catch ---ERROR---');
        printDebug(e);
        streamController.addError(e, s);
      }

      Future.delayed(const Duration(seconds: 1), () {});
      return streamController.stream;
    }
  }

  static void unsubscribeFromSSE() {
    print("_client.close");
    forceClosed = true;
    _client.close();
  }
}
