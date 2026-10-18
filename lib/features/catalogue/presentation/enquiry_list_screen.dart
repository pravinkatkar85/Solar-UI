import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_colors.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/features/catalogue/catalogue_api.dart';

/// The signed-in user's own product enquiries.
class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({
    required this.catalogueApi,
    required this.accessToken,
    super.key,
  });

  final CatalogueApi catalogueApi;
  final String accessToken;

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  late Future<CatalogueResult> _load;
  String? _busyEnquiryId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _load = widget.catalogueApi.listEnquiries(accessToken: widget.accessToken);
  }

  void _retry() {
    setState(_reload);
  }

  Future<void> _contact(CatalogueEnquiry enquiry) async {
    final name = enquiry.agentName.trim();
    final mobile = enquiry.agentMobile.trim();
    final assigned = name.isNotEmpty || mobile.isNotEmpty;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Assigned engineer'),
          content: Text(
            assigned
                ? [
                    if (name.isNotEmpty) name,
                    if (mobile.isNotEmpty) mobile,
                  ].join('\n')
                : 'No engineer is assigned to this enquiry yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _followUp(CatalogueEnquiry enquiry) async {
    final note = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Request a follow-up'),
          content: TextField(
            controller: note,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Optional message for the engineer',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    final text = note.text;
    note.dispose();
    if (send != true || !mounted) return;
    await _update(enquiry, 'followup', text);
  }

  Future<void> _cancel(CatalogueEnquiry enquiry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel enquiry'),
          content: Text('Cancel ${enquiry.enquiryNo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel enquiry'),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;
    await _update(enquiry, 'cancel', '');
  }

  Future<void> _update(
    CatalogueEnquiry enquiry,
    String action,
    String note,
  ) async {
    setState(() => _busyEnquiryId = enquiry.productEnquiryId);
    final result = await widget.catalogueApi.updateEnquiry(
      accessToken: widget.accessToken,
      productEnquiryId: enquiry.productEnquiryId,
      action: action,
      note: note,
    );
    if (!mounted) return;
    setState(() {
      _busyEnquiryId = null;
      if (result.isSuccess) _reload();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your enquiries')),
      body: SafeArea(
        child: FutureBuilder<CatalogueResult>(
          future: _load,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(key: Key('enquiry-loading')),
              );
            }
            final result = snapshot.data;
            if (result == null || !result.isSuccess) {
              return _EnquiryMessage(
                message: result?.message ?? 'Enquiries could not be loaded.',
                onRetry: _retry,
              );
            }
            final enquiries = result.enquiries ?? const <CatalogueEnquiry>[];
            if (enquiries.isEmpty) {
              return const _EnquiryMessage(
                message: 'You have not sent an enquiry yet.',
              );
            }
            return ListView.separated(
              key: const Key('enquiry-list'),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: enquiries.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final enquiry = enquiries[index];
                return _EnquiryCard(
                  enquiry: enquiry,
                  busy: _busyEnquiryId == enquiry.productEnquiryId,
                  onContact: () => _contact(enquiry),
                  onFollowUp: () => _followUp(enquiry),
                  onCancel: () => _cancel(enquiry),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EnquiryMessage extends StatelessWidget {
  const _EnquiryMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                key: const Key('enquiry-retry'),
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard({
    required this.enquiry,
    required this.busy,
    required this.onContact,
    required this.onFollowUp,
    required this.onCancel,
  });

  final CatalogueEnquiry enquiry;
  final bool busy;
  final VoidCallback onContact;
  final VoidCallback onFollowUp;
  final VoidCallback onCancel;

  bool get _open {
    return enquiry.statusCode != 'ENQ_CLOSED' &&
        enquiry.statusCode != 'ENQ_CONVERTED';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = enquiry.createdOn.length >= 10
        ? enquiry.createdOn.substring(0, 10)
        : enquiry.createdOn;
    final engineer = enquiry.agentName.trim().isEmpty
        ? 'Not assigned yet'
        : enquiry.agentName.trim();
    final scheme = theme.colorScheme;
    return Material(
      key: Key('enquiry-${enquiry.enquiryNo}'),
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    enquiry.enquiryNo,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.solarOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (enquiry.statusName.isNotEmpty)
                  Text(enquiry.statusName, style: theme.textTheme.labelMedium),
                PopupMenuButton<String>(
                  key: Key('enquiry-menu-${enquiry.enquiryNo}'),
                  tooltip: 'Enquiry actions',
                  enabled: !busy,
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (value) {
                    switch (value) {
                      case 'contact':
                        onContact();
                        break;
                      case 'followup':
                        onFollowUp();
                        break;
                      case 'cancel':
                        onCancel();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      key: Key('enquiry-contact-${enquiry.enquiryNo}'),
                      value: 'contact',
                      child: const Text('Contact engineer'),
                    ),
                    if (_open)
                      PopupMenuItem(
                        key: Key('enquiry-followup-${enquiry.enquiryNo}'),
                        value: 'followup',
                        child: const Text('Send follow-up'),
                      ),
                    if (_open)
                      PopupMenuItem(
                        key: Key('enquiry-cancel-${enquiry.enquiryNo}'),
                        value: 'cancel',
                        child: const Text('Cancel enquiry'),
                      ),
                  ],
                ),
              ],
            ),
            Text(
              enquiry.productName.isEmpty ? 'Product' : enquiry.productName,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              date.isEmpty
                  ? 'Engineer: $engineer'
                  : 'Engineer: $engineer · $date',
              style: theme.textTheme.bodySmall,
            ),
            if (enquiry.messageText.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                enquiry.messageText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (enquiry.preferredContactWindow.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Preferred contact: ${enquiry.preferredContactWindow}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
