import 'dart:io';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ofertix_ad_model.dart';
import '../../../services/admin_ads_service.dart';
import '../../../services/reels_upload_service.dart';
import '../../../widgets/ofertix_ad_slot.dart';
import '../../../widgets/ofertix_reels_video_ad.dart';

class AdminAdFormScreen extends StatefulWidget {
  AdminAdFormScreen({super.key, required this.initialAd});

  final OfertixAdModel initialAd;

  @override
  State<AdminAdFormScreen> createState() => _AdminAdFormScreenState();
}

class _AdminAdFormScreenState extends State<AdminAdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AdminAdsService.instance;

  late OfertixAdModel _ad;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _trackingUrl;
  late final TextEditingController _mediaUrl;
  late final TextEditingController _thumbnailUrl;
  late final TextEditingController _impressionUrl;
  late final TextEditingController _countryCode;
  late final TextEditingController _priority;
  late final TextEditingController _html;

  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _ad = widget.initialAd;
    _title = TextEditingController(text: _ad.title);
    _description = TextEditingController(text: _ad.description);
    _trackingUrl = TextEditingController(text: _ad.trackingUrl);
    _mediaUrl = TextEditingController(text: _ad.mediaUrl);
    _thumbnailUrl = TextEditingController(text: _ad.thumbnailUrl);
    _impressionUrl = TextEditingController(text: _ad.impressionUrl);
    _countryCode = TextEditingController(text: _ad.countryCode);
    _priority = TextEditingController(text: _ad.priority.toString());
    _html = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _trackingUrl.dispose();
    _mediaUrl.dispose();
    _thumbnailUrl.dispose();
    _impressionUrl.dispose();
    _countryCode.dispose();
    _priority.dispose();
    _html.dispose();
    super.dispose();
  }

  OfertixAdModel _currentAd() {
    return _ad.copyWith(
      title: _title.text.trim(),
      description: _description.text.trim(),
      trackingUrl: _trackingUrl.text.trim(),
      mediaUrl: _mediaUrl.text.trim(),
      thumbnailUrl: _thumbnailUrl.text.trim(),
      impressionUrl: _impressionUrl.text.trim(),
      countryCode: _countryCode.text.trim().isEmpty
          ? 'global'
          : _countryCode.text.trim().toLowerCase(),
      priority: int.tryParse(_priority.text.trim()) ?? 10,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _uploadMedia({required bool video}) async {
    // Ofertix uses Cloudinary through the existing Render backend for videos.
    // We do NOT use Firebase Storage here.
    setState(() => _uploading = true);

    try {
      final picker = ImagePicker();

      if (!video) {
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auto.admin_ads_admin_ad_form_screen.for_image_ads_paste_the_image_url_or_a'.tr()
                  .tr(),
            ),
          ),
        );
        return;
      }

      final file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;

      final result = await ReelsUploadService().uploadVideo(File(file.path));

      if (!mounted) return;

      setState(() {
        _mediaUrl.text = result.videoUrlOptimized.isNotEmpty
            ? result.videoUrlOptimized
            : result.videoUrlOriginal;
        _thumbnailUrl.text = result.thumbnailUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auto.admin_ads_admin_ad_form_screen.video_uploaded_to_cloudinary_review_pr'.tr()
                .tr(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloudinary upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _extractFromHtml() {
    final raw = _html.text.trim();
    if (raw.isEmpty) return;

    final hrefMatch = RegExp(
      r'''href=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(raw);

    final srcMatches = RegExp(r'''src=["']([^"']+)["']''', caseSensitive: false)
        .allMatches(raw)
        .map((match) => match.group(1) ?? '')
        .where((value) => value.trim().isNotEmpty)
        .toList();

    String normalizeUrl(String value) {
      final trimmed = value.trim();
      if (trimmed.startsWith('//')) return 'https:$trimmed';
      return trimmed;
    }

    setState(() {
      final href = hrefMatch?.group(1);
      if (href != null && href.trim().isNotEmpty) {
        _trackingUrl.text = normalizeUrl(href);
      }

      if (srcMatches.isNotEmpty) {
        _mediaUrl.text = normalizeUrl(srcMatches.first);
      }

      if (srcMatches.length > 1) {
        _impressionUrl.text = normalizeUrl(srcMatches[1]);
      }

      if (_title.text.trim().isEmpty) {
        _title.text = 'Oferta patrocinada';
      }

      if (_description.text.trim().isEmpty) {
        _description.text = 'Anuncio patrocinado';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('auto.admin_ads_admin_ad_form_screen.affiliate_html_extracted_review_and_sa'.tr()
              .tr(),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _ad.startAt : _ad.endAt;
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365 * 3)),
    );

    if (date == null || !mounted) return;

    setState(() {
      _ad = start ? _ad.copyWith(startAt: date) : _ad.copyWith(endAt: date);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updated = _currentAd();

      if (updated.id.isEmpty) {
        await _service.createAd(updated);
      } else {
        await _service.updateAd(updated);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showPreview() {
    final ad = _currentAd();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('auto.admin_ads_admin_ad_form_screen.preview'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 16),
              if (ad.placement == OfertixAdPlacement.reelsVideo)
                SizedBox(
                  height: 520,
                  child: OfertixReelsVideoAd(ad: ad, isActive: true),
                )
              else
                OfertixAdSlot.preview(ad: ad),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = _ad.type == OfertixAdType.video;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_ad.id.isEmpty ? 'Create anuncio' : 'Edit anuncio'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _showPreview,
            child: Text('auto.admin_ads_admin_ad_form_screen.preview'.tr()),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('auto.admin_ads_admin_ad_form_screen.save'.tr()),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 30),
            children: [
              _PickerCard(
                title: 'Placement',
                child: DropdownButtonFormField<OfertixAdPlacement>(
                  initialValue: _ad.placement,
                  dropdownColor: AppColors.card,
                  decoration: _inputDecoration('Where will it appear?'),
                  items: OfertixAdPlacement.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(OfertixAdModel.placementLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _ad = _ad.copyWith(
                        placement: value,
                        type: value == OfertixAdPlacement.reelsVideo
                            ? OfertixAdType.video
                            : _ad.type,
                      );
                    });
                  },
                ),
              ),
              SizedBox(height: 14),
              _PickerCard(
                title: 'Type',
                child: DropdownButtonFormField<OfertixAdType>(
                  initialValue: _ad.type,
                  dropdownColor: AppColors.card,
                  decoration: _inputDecoration('Banner, product or video'),
                  items: OfertixAdType.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(OfertixAdModel.typeKey(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _ad = _ad.copyWith(type: value));
                  },
                ),
              ),
              SizedBox(height: 14),
              _SwitchCard(
                title: 'Active',
                text: _ad.isActive ? 'Visible in app' : 'Paused',
                value: _ad.isActive,
                onChanged: (value) {
                  setState(() => _ad = _ad.copyWith(isActive: value));
                },
              ),
              SizedBox(height: 14),
              _Field(controller: _title, label: 'Title', required: true),
              _Field(
                controller: _description,
                label: 'product.description'.tr(),
                maxLines: 2,
              ),
              _Field(
                controller: _trackingUrl,
                label: 'Tracking URL / Affiliate link',
                required: true,
                keyboardType: TextInputType.url,
              ),
              _Field(
                controller: _mediaUrl,
                label: isVideo ? 'Video URL' : 'Image URL',
                keyboardType: TextInputType.url,
              ),
              _Field(
                controller: _thumbnailUrl,
                label: 'Thumbnail URL',
                keyboardType: TextInputType.url,
              ),
              _Field(
                controller: _impressionUrl,
                label: 'Impression Pixel URL optional',
                keyboardType: TextInputType.url,
              ),
              _UploadActions(
                uploading: _uploading,
                isVideo: isVideo,
                onUploadImage: () => _uploadMedia(video: false),
                onUploadVideo: () => _uploadMedia(video: true),
              ),
              SizedBox(height: 14),
              _PickerCard(
                title: 'Paste affiliate HTML optional',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _html,
                      maxLines: 4,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _inputDecoration(
                        'Paste <a><img> banner code here',
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _extractFromHtml,
                        icon: Icon(Icons.auto_fix_high_rounded),
                        label: Text('auto.admin_ads_admin_ad_form_screen.extract_links'.tr()
                              .tr(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _countryCode,
                      label: 'Country',
                      hint: 'es or global',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _priority,
                      label: 'Priority',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _ScheduleCard(
                startAt: _ad.startAt,
                endAt: _ad.endAt,
                onPickStart: () => _pickDate(start: true),
                onPickEnd: () => _pickDate(start: false),
                onClearStart: () {
                  setState(() => _ad = _ad.copyWith(clearStartAt: true));
                },
                onClearEnd: () {
                  setState(() => _ad = _ad.copyWith(clearEndAt: true));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadActions extends StatelessWidget {
  _UploadActions({
    required this.uploading,
    required this.isVideo,
    required this.onUploadImage,
    required this.onUploadVideo,
  });

  final bool uploading;
  final bool isVideo;
  final VoidCallback onUploadImage;
  final VoidCallback onUploadVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('auto.admin_ads_admin_ad_form_screen.media_upload'.tr(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 10),
          if (uploading)
            LinearProgressIndicator(color: AppColors.orange)
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUploadImage,
                    icon: Icon(Icons.image_rounded),
                    label: Text('auto.admin_ads_admin_ad_form_screen.upload_image'.tr(),
                    ),
                  ),
                ),
                if (isVideo) ...[
                  SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onUploadVideo,
                      icon: Icon(Icons.video_library_rounded),
                      label: Text('auto.admin_ads_admin_ad_form_screen.upload_video'.tr(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  _ScheduleCard({
    required this.startAt,
    required this.endAt,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearStart,
    required this.onClearEnd,
  });

  final DateTime? startAt;
  final DateTime? endAt;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearStart;
  final VoidCallback onClearEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('auto.admin_ads_admin_ad_form_screen.schedule'.tr(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Start',
                  value: startAt,
                  onPick: onPickStart,
                  onClear: onClearStart,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _DateButton(
                  label: 'End',
                  value: endAt,
                  onPick: onPickEnd,
                  onClear: onClearEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  _DateButton({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selected = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: onPick,
          child: Text(
            selected == null
                ? label
                : '${selected.day}/${selected.month}/${selected.year}',
          ),
        ),
        if (selected != null)
          TextButton(
            onPressed: onClear,
            child: Text('auto.admin_ads_admin_ad_form_screen.clear'.tr()),
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        decoration: _inputDecoration(label).copyWith(hintText: hint),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  _PickerCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  _SwitchCard({
    required this.title,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(text, style: TextStyle(color: AppColors.gray)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
  );
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w800),
    hintStyle: TextStyle(color: AppColors.gray.withValues(alpha: 0.65)),
    filled: true,
    fillColor: AppColors.card,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.orange, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.red),
    ),
  );
}
