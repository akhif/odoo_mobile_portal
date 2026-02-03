import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';

class JobOrderDetailScreen extends StatefulWidget {
  final int jobOrderId;

  const JobOrderDetailScreen({super.key, required this.jobOrderId});

  @override
  State<JobOrderDetailScreen> createState() => _JobOrderDetailScreenState();
}

class _JobOrderDetailScreenState extends State<JobOrderDetailScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isUpdating = false;
  Map<String, dynamic>? _jobOrder;
  String _selectedStage = 'In Progress';
  int _progress = 60;

  final List<String> _stages = ['To Do', 'In Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    _loadJobOrder();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadJobOrder() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _jobOrder = {
        'id': widget.jobOrderId,
        'name': 'JOB-2024-00${widget.jobOrderId}',
        'project': 'Website Redesign',
        'description': 'Update homepage layout and navigation structure. Ensure mobile responsiveness and accessibility compliance.',
        'date_deadline': DateTime.now().add(const Duration(days: 5)),
        'stage': 'In Progress',
        'priority': 'high',
        'progress': 60,
        'assigned_to': 'John Doe',
        'create_date': DateTime.now().subtract(const Duration(days: 10)),
      };
      _selectedStage = _jobOrder!['stage'];
      _progress = _jobOrder!['progress'];
    });
  }

  Future<void> _updateProgress() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Update Progress',
      message: 'Save current progress and status?',
      confirmText: 'Save',
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isUpdating = false;
      _jobOrder!['stage'] = _selectedStage;
      _jobOrder!['progress'] = _progress;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _attachFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attaching ${result.files.single.name}...')),
        );
        // TODO: Implement actual upload
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_jobOrder!['name']),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _jobOrder!['project'],
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _jobOrder!['description'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.calendar_today,
                          label: 'Due: ${dateFormat.format(_jobOrder!['date_deadline'])}',
                        ),
                        SizedBox(width: 8.w),
                        _InfoChip(
                          icon: Icons.person_outline,
                          label: _jobOrder!['assigned_to'],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Progress Update Section
            Text(
              'Update Progress',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stage Selection
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      value: _selectedStage,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: _stages.map((stage) {
                        return DropdownMenuItem(
                          value: stage,
                          child: Text(stage),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStage = value!;
                          if (value == 'Done') {
                            _progress = 100;
                          }
                        });
                      },
                    ),

                    SizedBox(height: 20.h),

                    // Progress Slider
                    Text(
                      'Progress: $_progress%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Slider(
                      value: _progress.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$_progress%',
                      onChanged: (value) {
                        setState(() {
                          _progress = value.toInt();
                        });
                      },
                    ),

                    SizedBox(height: 20.h),

                    // Notes
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add progress notes...',
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Attachments
                    OutlinedButton.icon(
                      onPressed: _attachFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Attach File'),
                    ),

                    SizedBox(height: 20.h),

                    // Update Button
                    AppButton(
                      text: 'Save Progress',
                      isLoading: _isUpdating,
                      isFullWidth: true,
                      onPressed: _updateProgress,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
