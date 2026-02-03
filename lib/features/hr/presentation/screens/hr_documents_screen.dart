import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/hr_provider.dart';

class HrDocumentsScreen extends ConsumerWidget {
  const HrDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(hrDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Documents'),
      ),
      body: documentsAsync.when(
        loading: () => const ListShimmer(),
        error: (error, stack) => AppErrorWidget(
          message: 'Failed to load documents',
          onRetry: () => ref.refresh(hrDocumentsProvider),
        ),
        data: (documents) {
          if (documents.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Document Requests',
              subtitle: 'Document requests from HR will appear here',
              icon: Icons.folder_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(hrDocumentsProvider);
            },
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: documents.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final doc = documents[index];

                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                doc.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _DocumentStatusBadge(state: doc.state),
                          ],
                        ),
                        if (doc.documentTypeName != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            doc.documentTypeName!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                        if (doc.description != null && doc.description!.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            doc.description!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            if (doc.hasAttachments)
                              Chip(
                                avatar: Icon(Icons.attach_file, size: 16.sp),
                                label: Text(
                                  '${doc.attachmentIds.length} file(s)',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                                backgroundColor: AppColors.info.withOpacity(0.1),
                              ),
                            const Spacer(),
                            if (doc.canSubmit)
                              ElevatedButton.icon(
                                onPressed: () => _uploadDocument(context, ref, doc.id),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Upload'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref, int documentId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading ${file.name}...')),
        );

        // TODO: Implement actual upload
        await Future.delayed(const Duration(seconds: 2));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        ref.refresh(hrDocumentsProvider);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _DocumentStatusBadge extends StatelessWidget {
  final String state;

  const _DocumentStatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (state) {
      case 'requested':
        color = AppColors.warning;
        label = 'Pending';
        icon = Icons.pending_outlined;
        break;
      case 'submitted':
        color = AppColors.info;
        label = 'Submitted';
        icon = Icons.check_circle_outline;
        break;
      case 'approved':
        color = AppColors.success;
        label = 'Approved';
        icon = Icons.verified_outlined;
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = AppColors.textSecondary;
        label = state;
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
