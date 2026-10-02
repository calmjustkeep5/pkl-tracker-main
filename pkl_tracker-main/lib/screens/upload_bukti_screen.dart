import 'package:flutter/material.dart';

class UploadBuktiScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Bukti Kegiatan")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: Icon(Icons.camera_alt, size: 50, color: Colors.grey),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Keterangan Foto",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color(0xFF2E3192),
              ),
              onPressed: () {}, 
              child: Text("Kirim Bukti", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}