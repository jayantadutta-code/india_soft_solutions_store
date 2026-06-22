import 'dart:convert';
import 'package:http/http.dart' as http;

//Auth token we will use to generate a meeting and connect to it
String token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIyMDE0ZDg1ZC04ODQ5LTQ1N2EtOTljNy04Njc2Zjk3OGQ3NzciLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIl0sImlhdCI6MTc4MjEwOTY4NCwiZXhwIjoxNzgyNzE0NDg0fQ.1UntJWb3-eV9Wtsi31oaseWlaiIJMTLXrQAK0NtkJ2A";

// API call to create meeting
Future<String> createMeeting() async {
  final http.Response httpResponse = await http.post(
    Uri.parse("https://api.videosdk.live/v2/rooms"),
    headers: {'Authorization': token},
  );

//Destructuring the roomId from the response
  return json.decode(httpResponse.body)['roomId'];
}