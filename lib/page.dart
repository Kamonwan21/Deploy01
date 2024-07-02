import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'login.dart';

class PatientDetailsPage extends StatefulWidget {
  final String visitId;

  const PatientDetailsPage({required this.visitId, Key? key}) : super(key: key);

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  Map<String, dynamic>? patientDetails;
  List<dynamic>? medications;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _fetchPatientDetails();
    _configureTts();
  }

  void _configureTts() async {
    await flutterTts.setLanguage("th-TH");
    await flutterTts.setPitch(0.5);
    await flutterTts.setVolume(0.5);
    await flutterTts.setSpeechRate(0.8);
  }

  Future<void> _fetchPatientDetails() async {
    final url = Uri.parse(
        'https://bpk-webapp-prd1.bdms.co.th/ApiPhamacySmartLabel/PatientDetailsTest');
    final headers = {
      'Content-Type': 'application/json',
      // Remove the following line because it's not needed for requests made from Flutter
      // 'Access-Control-Allow-Origin': '*',
    };
    final body = jsonEncode({'emplid': widget.visitId, 'pass': ""});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == '200') {
          setState(() {
            patientDetails =
                (jsonResponse['detailsH'] as List<dynamic>?)?.first;
            medications = jsonResponse['detailsB'] as List<dynamic>?;
          });
        } else {
          _showSnackBar(
              'Failed to load patient details: ${jsonResponse['message']}');
        }
      } else {
        _showSnackBar('Failed to load patient details');
      }
    } catch (e) {
      _showSnackBar('An error occurred while fetching patient details.');
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _speakText(String text) async {
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home Medication Sheet',
          style: TextStyle(
              fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            const Color(0xFF03A9F4), // Set background color to transparent
        elevation: 0, // Remove elevation to blend with the gradient
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout),
            color: Colors.white,
          )
        ],
      ),
      body: patientDetails != null && medications != null
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile / ข้อมูลผู้ป่วย',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Card(
                    child: ListTile(
                      title: Text('${patientDetails!['patient_name'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 18)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HN : ${patientDetails!['hn'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16)),
                          Text(
                              'Gender : ${patientDetails!['fix_gender_id'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16)),
                          Text('DOB : ${patientDetails!['birthdate'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16)),
                          Text('Age : ${patientDetails!['age'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16)),
                          Text(
                              'Episode Date / Number : ${patientDetails!['visit_date'] ?? 'N/A'},${patientDetails!['visit_time'] ?? 'N/A'}[${patientDetails!['en'] ?? 'N/A'}]',
                              style: const TextStyle(fontSize: 16)),
                          Text(
                              'Diagnosis : ${patientDetails!['diagnosis'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16)),
                          Text(
                              'Allergy : ${patientDetails!['drugaallergy'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16)),
                          Text(
                              'Ward : ${patientDetails!['roombed'] ?? 'N/A'},${patientDetails!['opddoctorname'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16)),
                          Center(
                            child: IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () {
                                final String ageValue =
                                    (patientDetails!['age'] ?? 'N/A')
                                        .toString()
                                        .replaceAll(RegExp(r'\D'), '');
                                final detailsText = """
                            ${patientDetails!['patient_name'] ?? 'N/A'}
                            HN: ${patientDetails!['hn'] ?? 'N/A'}
                            Gender/เพศ: ${patientDetails!['fix_gender_id'] ?? 'N/A'}
                            D.O.B/วันเกิด: ${patientDetails!['birthdate'] ?? 'N/A'}
                            Age/อายุ: $ageValue
                            Episode Date / Number/วันที่เข้าพบแพทย์: ${patientDetails!['visit_date'] ?? 'N/A'},${patientDetails!['visit_time'] ?? 'N/A'},${patientDetails!['en'] ?? 'N/A'}
                            Diagnosis/วินิจฉัย: ${patientDetails!['diagnosis'] ?? 'N/A'}
                            Allergy/การแพ้: ${patientDetails!['drugaallergy'] ?? 'N/A'}
                            Ward/ห้อง: ${patientDetails!['roombed'] ?? 'N/A'}${patientDetails!['opddoctorname'] ?? 'N/A'}
                          """;
                                _speakText(detailsText);
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Medications / ยา',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: medications!.length,
                    itemBuilder: (context, index) {
                      final medication = medications![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5.0),
                                  child: Image.network(
                                    medication['imagename'] ?? '',
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text('${medication['item_name'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('${medication['th_name'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text(
                                  'Instructions : ${medication['instruction_text_line1'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text(
                                  '${medication['instruction_text_line2'] ?? ''}',
                                  style: const TextStyle(fontSize: 16)),
                              Text(
                                  '${medication['instruction_text_line3'] ?? ''}',
                                  style: const TextStyle(fontSize: 16)),
                              Text(
                                  'Description : ${medication['item_deacription'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text(
                                  'Caution : ${medication['item_caution'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Center(
                                child: IconButton(
                                  icon: const Icon(Icons.volume_up),
                                  onPressed: () {
                                    final medicationText = """
                                    ${medication['item_name'] ?? 'N/A'}
                                    ${medication['th_name'] ?? 'N/A'}
                                      Instructions/คำแนะนำ: ${medication['instruction_text_line1'] ?? 'N/A'}
                                      ${medication['instruction_text_line2'] ?? ''}
                                      ${medication['instruction_text_line3'] ?? ''}
                                      Description/คำอธิบาย: ${medication['item_deacription'] ?? 'N/A'}
                                      Caution/คำเตือน: ${medication['item_caution'] ?? 'N/A'}
                                    """;
                                    _speakText(medicationText);
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
