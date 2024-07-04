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
    await flutterTts.setLanguage('th-TH');
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.8);
  }

  Future<void> _fetchPatientDetails() async {
    final url = Uri.parse(
        'https://bpk-webapp-prd1.bdms.co.th/ApiPhamacySmartLabel/PatientDetails');
    final headers = {'Content-Type': 'application/json'};
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

  String getText(String thaiText, String englishText) {
    if (patientDetails == null ||
        !patientDetails!.containsKey('base_communication_language_id')) {
      return englishText; // Default to English if data is incomplete
    }

    final languageId = patientDetails!['base_communication_language_id'];
    if (languageId == 'TH') {
      return thaiText;
    } else {
      return englishText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getText('ใบสั่งยากลับบ้าน', 'Home Medication Sheet'),
          style: const TextStyle(
              fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF03A9F4),
        elevation: 0,
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
                  _buildPatientProfileSection(),
                  const SizedBox(height: 20),
                  _buildMedicationSection(),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildPatientProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(getText('ข้อมูลผู้ป่วย', 'Profile'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Card(
          child: ListTile(
            title: Text(
                '${patientDetails!['patient_name'] ?? getText('ไม่มีข้อมูล', 'N/A')}',
                style: const TextStyle(fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${getText('รหัสโรงพยาบาล', 'HN')} : ${patientDetails!['hn'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    '${getText('เพศ', 'Gender')} : ${patientDetails!['fix_gender_id'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    '${getText('วันเกิด', 'Date of birth')} : ${patientDetails!['birthdate'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    '${getText('อายุ', 'Age')} : ${patientDetails!['age'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    '${getText('วันที่เข้าพบแพทย์ / เลขที่', 'Episode Date / Number')} : ${patientDetails!['visit_date'] ?? 'N/A'} ${patientDetails!['visit_time'] ?? 'N/A'} ${patientDetails!['en'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    '${getText('การแพ้', 'Allergy')} : ${patientDetails!['drugaallergy'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    '${getText('ประเภทผู้ป่วย', 'Patient Type')} : ${patientDetails!['fix_visit_type_id'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                if (patientDetails!['fix_visit_type_id'] == 'IPD')
                  Text(
                    '${getText('ห้อง', 'Ward')} : ${patientDetails!['roombed'] ?? 'N/A'}\n${getText('ชื่อแพทย์', 'Doctor Name')} : ${patientDetails!['opddoctorname'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                if (patientDetails!['fix_visit_type_id'] == 'OPD')
                  Text(
                      '${getText('ชื่อแพทย์', 'Doctor Name')} : ${patientDetails!['opddoctorname'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16)),
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () {
                      _speakPatientDetails();
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatVisitDateTime() {
    String visitDate = patientDetails!['visit_date'] ?? 'N/A';
    String visitTime = patientDetails!['visit_time'] ?? 'N/A';
    String en = patientDetails!['en'] ?? 'N/A';

    return '$visitDate, $visitTime [$en]';
  }

  void _speakPatientDetails() {
    final detailsText = """
        ${patientDetails!['patient_name'] ?? getText('ไม่มีข้อมูล', 'N/A')}
        ${getText('รหัสโรงพยาบาล', 'HN')}: ${patientDetails!['hn'] ?? 'N/A'}
        ${getText('เพศ', 'Gender')}: ${patientDetails!['fix_gender_id'] ?? 'N/A'}
        ${getText('วันเกิด', 'Date of birth')}: ${patientDetails!['birthdate'] ?? 'N/A'}
        ${getText('อายุ', 'Age')}: ${patientDetails!['age'] ?? 'N/A'}
        ${getText('วันที่เข้าพบแพทย์ / เลขที่', 'Episode Date / Number')}: ${_formatVisitDateTime()}
        ${getText('การแพ้', 'Allergy')}: ${patientDetails!['drugaallergy'] ?? 'N/A'}
        ${getText('ประเภทผู้ป่วย', 'Patient Type')}${patientDetails!['fix_visit_type_id'] ?? 'N/A'} 
        ${getText('ห้อง', 'Ward')}${patientDetails!['roombed'] ?? 'N/A'} 
        ${getText('ชื่อแพทย์', 'Doctor Name')}${patientDetails!['opddoctorname'] ?? 'N/A'}
      """;
    _speakText(detailsText);
  }

  Widget _buildMedicationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(getText('ยา', 'Medications'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                    _buildMedicationImage(medication['profileimage']),
                    const SizedBox(height: 10),
                    _buildMedicationDetails(medication),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          final medicationText = """
                          ${medication['item_name'] ?? getText('ไม่มีข้อมูล', 'N/A')}
                          ${medication['th_name'] ?? getText('ไม่มีข้อมูล', 'N/A')}
                            ${getText('คำแนะนำ', 'Instructions')}: ${medication['instruction_text_line1'] ?? 'N/A'}
                            ${medication['instruction_text_line2'] ?? ''}
                            ${medication['instruction_text_line3'] ?? ''}
                            ${getText('คำอธิบาย', 'Description')}: ${medication['item_deacription'] ?? 'N/A'}
                            ${getText('คำเตือน', 'Caution')}: ${medication['item_caution'] ?? 'N/A'}
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
    );
  }

  Widget _buildMedicationImage(String? base64Image) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: base64Image != null && base64Image.isNotEmpty
            ? Image.memory(
                base64Decode(base64Image),
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    size: 150,
                  );
                },
              )
            : const Icon(
                Icons.image,
                size: 150,
              ),
      ),
    );
  }

  Widget _buildMedicationDetails(Map<String, dynamic> medication) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${medication['item_name'] ?? getText('ไม่มีข้อมูล', 'N/A')}',
            style: const TextStyle(fontSize: 16)),
        Text('${medication['th_name'] ?? getText('ไม่มีข้อมูล', 'N/A')}',
            style: const TextStyle(fontSize: 16)),
        Text(
            '${getText('คำแนะนำ', 'Instructions')} : ${medication['instruction_text_line1'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16)),
        Text('${medication['instruction_text_line2'] ?? ''}',
            style: const TextStyle(fontSize: 16)),
        Text('${medication['instruction_text_line3'] ?? ''}',
            style: const TextStyle(fontSize: 16)),
        Text(
            '${getText('คำอธิบาย', 'Description')} : ${medication['item_deacription'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16)),
        Text(
            '${getText('คำเตือน', 'Caution')} : ${medication['item_caution'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
