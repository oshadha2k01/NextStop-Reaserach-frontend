import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ComplaintModal extends StatefulWidget {
  final String busId;

  const ComplaintModal({super.key, required this.busId});

  @override
  State<ComplaintModal> createState() => _ComplaintModalState();
}

class _ComplaintModalState extends State<ComplaintModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  // Demo bus details (can be enhanced with real data)
  final String _busName = "Route Express Bus";
  final String _busRoute = "Main Route";

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (_subjectController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Backend endpoint: complaintRoutes.js → complaintController.js
      final complaintData = {
        'busId': widget.busId,
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'submittedAt': DateTime.now().toIso8601String(),
      };

      final resp = await ApiService().post('/api/complaints', body: complaintData);

      if (mounted) {
        if (resp.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Complaint submitted successfully!\nOur Super Admin team will review and respond soon.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting complaint: ${resp.errorMessage ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting complaint: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title, {required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Submit a Complaint",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Help us improve by reporting issues",
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Auto-fetched Bus Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _busName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bus ID: ${widget.busId}',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _busRoute,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable complaint form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject Section
                  _buildSectionTitle('Issue Subject', icon: Icons.warning_outlined),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What is the issue about?',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _subjectController,
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: 'E.g., Driver behavior, Vehicle condition, Safety issue...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  _buildSectionTitle('Description', icon: Icons.description_outlined),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Describe the issue in detail',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Please provide specific details about what happened, when, and any other relevant information...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Complaint',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
