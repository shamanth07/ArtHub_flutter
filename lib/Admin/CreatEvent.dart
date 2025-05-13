import 'package:flutter/material.dart';

class CreateEventPage extends StatelessWidget {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController maxVisitorsController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
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
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 0.5),
                image: DecorationImage(
                  image: AssetImage('assets/images/art_placeholder.jpg'), // Replace with your asset
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 15),

            // Event title
            TextField(
              controller: TextEditingController(),
              style: TextStyle(
                fontSize: 24, // Makes it look like a title
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Enter Title",
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            SizedBox(height: 10),


            // Description field
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: "Description",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            SizedBox(height: 10),

            // Date and Time fields side by side
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                      hintText: "Date",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
            SizedBox(height: 10),

            // Map image (placeholder)
            // Map image (placeholder)
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: AssetImage('assets/images/map_placeholder.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(child: Icon(Icons.location_pin, size: 40, color: Colors.blue)),
            ),
            SizedBox(height: 10),

// Location input with search button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      hintText: "Enter Event Location",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Implement search location logic
                    print("Searching location: ${locationController.text}");
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Search"),
                ),
              ],
            ),
            SizedBox(height: 10),


            // Maximum visitors field
            TextField(
              controller: maxVisitorsController,
              decoration: InputDecoration(
                hintText: "Maximum Artists Allowed",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),

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
