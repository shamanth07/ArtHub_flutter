import 'package:flutter/material.dart';

class CreateEventPage extends StatelessWidget {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController maxVisitorsController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  CreateEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Event"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 0.5),
                image: DecorationImage(
                  image: AssetImage('assets/images/art_placeholder.jpg'), // Replace with your asset
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Event title
            Text(
              "Modern Art Expo",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Description field
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Date and Time fields side by side
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                      hintText: "Date",
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2025, 9, 4),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        dateController.text =
                        "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                      }
                    },
                    readOnly: true,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: timeController,
                    decoration: InputDecoration(
                      hintText: "Time",
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: 18, minute: 0),
                      );
                      if (pickedTime != null) {
                        timeController.text =
                            pickedTime.format(context);
                      }
                    },
                    readOnly: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Map image (placeholder)
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(

                color: Colors.grey[200],
                image: DecorationImage(
                  image: AssetImage('assets/images/map_placeholder.jpg'), // Replace with actual map
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(child: Icon(Icons.location_pin, size: 40, color: Colors.blue)),
            ),
            SizedBox(height: 16),

            // Maximum visitors field
            TextField(
              controller: maxVisitorsController,
              decoration: InputDecoration(
                hintText: "Maximum Visitors Allowed",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),

            // Create button
            Center(
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle create logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 👈 Rectangular shape
                    ),
                  ),

                  child: Text("Create"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
